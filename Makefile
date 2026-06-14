.PHONY: check check-syntax shellcheck personal work thinkpad
.SILENT:

SHELL_SCRIPTS := \
	mac.sh \
	personal.sh \
	work.sh \
	thinkpad.sh \
	$(wildcard common/*.sh) \
	$(wildcard linux/*.sh) \
	$(wildcard linux/thinkpad/*.sh) \
	$(wildcard macos/*.sh)

check: shellcheck check-syntax

shellcheck:
	shellcheck $(SHELL_SCRIPTS)

check-syntax:
	bash -n $(SHELL_SCRIPTS)

personal:
	./personal.sh

work:
	./work.sh

thinkpad:
	./thinkpad.sh
