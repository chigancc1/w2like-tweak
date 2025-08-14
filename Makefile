# ---- Pick the right control file automatically ------------------------------
# Theos looks for a file literally named "control". We keep two variants:
#   - control.rootless  (iOS 14+)
#   - control.rootful   (iOS 12.5.7)
# This hook copies the correct one to "control" before packaging, and cleans it.

before-package::
	@set -e; \
	rm -f control; \
	echo "THEOS_PACKAGE_SCHEME=$(THEOS_PACKAGE_SCHEME)"; \
	if [ -f control.$(THEOS_PACKAGE_SCHEME) ]; then \
	  cp control.$(THEOS_PACKAGE_SCHEME) control; \
	  echo "Using control.$(THEOS_PACKAGE_SCHEME)"; \
	elif [ -f control.rootless ]; then \
	  cp control.rootless control; \
	  echo "Using control.rootless (fallback)"; \
	elif [ -f control.rootful ]; then \
	  cp control.rootful control; \
	  echo "Using control.rootful (fallback)"; \
	else \
	  echo "ERROR: No control file found (looked for control.$(THEOS_PACKAGE_SCHEME), control.rootless, control.rootful)"; \
	  exit 1; \
	fi

after-package::
	@rm -f control || true
