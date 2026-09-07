"""Exercise service helpers in an isolated filesystem with no real sudo/systemctl."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]
MOCK = '''#!{python}
import json, os, pathlib, shutil, subprocess, sys
name = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
with open(os.environ['COMMAND_LOG'], 'a') as log:
    log.write(json.dumps([name, *args]) + '\\n')
state = json.loads(pathlib.Path(os.environ['MOCK_STATE']).read_text())
if name == 'sudo':
    sys.exit(subprocess.call(args))
if name == 'install':
    assert args[0] == '-Dm644', args
    target = pathlib.Path(args[2])
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(args[1], target)
    target.chmod(0o644)
if name == 'pacman':
    sys.exit(state.get('pacman_status', 0))
if name == 'systemctl':
    if args[0] == '--user':
        args = args[1:]
    if args[0] == 'is-active':
        sys.exit(0 if args[-1] in state.get('active', []) else 3)
    if args[0] == 'show':
        print(state.get('swap_load', 'loaded'))
    if args[0] == 'show-environment':
        sys.exit(state.get('user_bus_status', 0))
'''


class ArchSystemTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.checkout = self.root / 'repo'
        for profile in ('arch', 'macbook'):
            source = REPO / 'linux' / profile
            target = self.checkout / 'linux' / profile
            shutil.copytree(source, target)
            for script in target.glob('*.sh'):
                contents = script.read_text()
                for prefix in ('/etc/', '/run/', '/usr/local/lib/', '/usr/lib/', '/sys/'):
                    contents = contents.replace(prefix, str(self.root) + prefix)
                script.write_text(contents)
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        for command in ('sudo', 'systemctl', 'install', 'pacman'):
            executable = self.bin / command
            executable.write_text(MOCK.format(python=sys.executable))
            executable.chmod(0o755)
        self.log = self.root / 'commands.jsonl'
        self.state = self.root / 'state.json'
        self.state.write_text('{}')
        self.env = dict(os.environ, ROOT_DIR=str(self.checkout),
                        PATH=str(self.bin) + os.pathsep + os.environ['PATH'],
                        COMMAND_LOG=str(self.log), MOCK_STATE=str(self.state))
        self.write('run/systemd/resolve/stub-resolv.conf', 'nameserver 127.0.0.53\n')
        (self.root / 'etc').mkdir(exist_ok=True)

    def write(self, path, text):
        target = self.root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text)
        return target

    def configure(self, **state):
        self.state.write_text(json.dumps(state))

    def run_helper(self, name, success=True):
        result = subprocess.run(['bash', str(self.checkout / 'linux' / name)],
                                env=self.env, text=True, capture_output=True)
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def commands(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()] if self.log.exists() else []

    def test_network_defaults_and_dns_backup_survive_rerun(self):
        self.write('etc/resolv.conf', 'nameserver 192.0.2.1\n')
        self.run_helper('arch/network.sh')
        configs = self.root / 'etc/systemd/network'
        self.assertEqual(sorted(p.name for p in configs.iterdir()),
                         ['20-ethernet.network', '20-wlan.network', '20-wwan.network'])
        wlan = configs / '20-wlan.network'
        wlan.write_text('[Match]\nName=custom-wifi\n')
        self.run_helper('arch/network.sh')
        self.assertEqual(wlan.read_text(), '[Match]\nName=custom-wifi\n')
        self.assertEqual((self.root / 'etc/resolv.conf.pre-laptop').read_text(), 'nameserver 192.0.2.1\n')
        self.assertEqual((self.root / 'etc/resolv.conf').resolve(), self.root / 'run/systemd/resolve/stub-resolv.conf')
        self.assertFalse(any('restart' in c or 'reconfigure' in c for c in self.commands()))

    def test_existing_runtime_network_config_prevents_defaults(self):
        self.write('run/systemd/network/10-custom.network', '[Match]\nName=eth0\n')
        self.run_helper('arch/network.sh')
        self.assertFalse((self.root / 'etc/systemd/network').exists())

    def test_network_mask_is_preserved(self):
        target = self.root / 'etc/systemd/network/20-wlan.network'
        target.parent.mkdir(parents=True)
        target.symlink_to('/dev/null')
        self.run_helper('arch/network.sh')
        self.assertEqual(os.readlink(target), '/dev/null')
        self.assertEqual(len(list(target.parent.iterdir())), 1)

    def test_new_zram_configuration_and_active_swap_rerun(self):
        zswap = self.write('sys/module/zswap/parameters/enabled', 'Y\n')
        self.run_helper('arch/zram.sh')
        config = self.root / 'etc/systemd/zram-generator.conf'
        self.assertIn('zram-size = min(ram / 2, 4096)', config.read_text())
        self.assertIn('compression-algorithm = zstd', config.read_text())
        config.write_text('[zram0]\nzram-size = 1024\n')
        self.configure(active=['dev-zram0.swap'])
        self.run_helper('arch/zram.sh')
        self.assertEqual(config.read_text(), '[zram0]\nzram-size = 1024\n')
        self.assertEqual(zswap.read_text(), 'N\n')
        self.assertFalse(any('stop' in c or 'restart' in c for c in self.commands()))
        self.assertIn(['systemctl', 'start', 'dev-zram0.swap'], self.commands())

    def test_zram_mask_prevents_default_configuration_and_swap_start(self):
        target = self.root / 'etc/systemd/zram-generator.conf'
        target.parent.mkdir(parents=True)
        target.symlink_to('/dev/null')
        self.configure(swap_load='not-found')
        self.run_helper('arch/zram.sh')
        self.assertEqual(os.readlink(target), '/dev/null')
        self.assertNotIn(['systemctl', 'start', 'dev-zram0.swap'], self.commands())

    def test_vendor_zram_config_and_local_dropin_are_preserved(self):
        self.write('usr/lib/systemd/zram-generator.conf.d/vendor.conf', '[zram1]\n')
        dropin = self.write('etc/systemd/system/systemd-zram-setup@zram0.service.d/disable-zswap.conf', '# local override\n')
        self.configure(swap_load='not-found')
        self.run_helper('arch/zram.sh')
        self.assertFalse((self.root / 'etc/systemd/zram-generator.conf').exists())
        self.assertEqual(dropin.read_text(), '# local override\n')
        self.assertNotIn(['systemctl', 'start', 'dev-zram0.swap'], self.commands())

    def test_services_use_system_and_current_user_scopes(self):
        self.run_helper('arch/services.sh')
        self.run_helper('macbook/services.sh')
        self.assertIn(['sudo', 'systemctl', 'enable', '--now', 'bluetooth.service', 'power-profiles-daemon.service'], self.commands())
        self.assertIn(['systemctl', '--user', 'enable', '--now', 'pipewire.socket', 'pipewire-pulse.socket', 'wireplumber.service'], self.commands())
        self.assertIn(['sudo', 'systemctl', 'enable', '--now', 't2fanrd.service'], self.commands())
        self.assertFalse(any(c[0] == 'sudo' and '--user' in c for c in self.commands()))

    @unittest.skipIf(os.geteuid() == 0, 'Wrapper deliberately rejects root sessions')
    def test_missing_packages_or_user_session_abort_before_mutation(self):
        for state in (dict(pacman_status=1), dict(user_bus_status=1)):
            with self.subTest(state=state):
                self.configure(**state)
                self.run_helper('arch/system.sh', success=False)
                self.assertFalse(any(c[0] == 'sudo' for c in self.commands()))


if __name__ == '__main__':
    unittest.main()
