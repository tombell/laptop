# Migrate literal Limine command-line assignments without evaluating shell code.
# Preserve quoting, other kernel parameters, comments, and boot menu settings.
function fail(message) {
  print "Error: " message > "/dev/stderr"
  failed = 1
  exit 1
}

/^[[:space:]]*KERNEL_CMDLINE(\[[^]]+\])?[[:space:]]*\+?=/ {
  assignment_end = index($0, "=")
  assignment = substr($0, 1, assignment_end)
  # A leading space gives unquoted values the same token boundary as quoted ones.
  line = " " substr($0, assignment_end + 1)
  if (line ~ /(^|[[:space:]"\047])cryptkey=/) {
    fail("Migrate cryptkey= to systemd keyfile configuration before running ThinkPad setup")
  }

  while (match(line, /(^|[[:space:]"\047])cryptdevice=[^[:space:]"\047]+/)) {
    start = RSTART
    length_with_prefix = RLENGTH
    parameter = substr(line, start, length_with_prefix)
    prefix = substr(parameter, 1, 1)
    sub(/^./, "", parameter)
    sub(/^cryptdevice=/, "", parameter)
    count = split(parameter, parts, ":")
    if (count < 2 || count > 3 || parts[2] != "root" ||
        (count == 3 && parts[3] != "allow-discards")) {
      fail("Unsupported cryptdevice= value; expected a root mapping with optional allow-discards")
    }
    replacement = "rd.luks.name=" luks_uuid "=root"
    if (count == 3) {
      replacement = replacement " rd.luks.options=" luks_uuid "=discard"
    }
    line = substr(line, 1, start - 1) prefix replacement substr(line, start + length_with_prefix)
    found_root = 1
  }

  if (line ~ /(^|[[:space:]"\047])rd\.luks\.name=/) {
    # Reruns must still refer to the root volume detected on this machine.
    expected = "rd.luks.name=" luks_uuid "=root"
    rest = line
    while (match(rest, /(^|[[:space:]"\047])rd\.luks\.name=[^[:space:]"\047]+/)) {
      parameter = substr(rest, RSTART + 1, RLENGTH - 1)
      if (parameter != expected) {
        fail("Unexpected rd.luks.name= value in ThinkPad Limine configuration")
      }
      found_root = 1
      rest = substr(rest, RSTART + RLENGTH)
    }
  }
  $0 = assignment substr(line, 2)
}

{ print }

END {
  if (!failed && !found_root) {
    fail("No root encryption parameter found in /etc/default/limine; migrate inherited command lines explicitly")
  }
}
