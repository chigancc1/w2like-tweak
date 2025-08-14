# ---- Theos build config (Linux/GitHub Actions) ------------------------------
ARCHS := arm64 arm64e
# Broad min version; the workflow pins the SDK (14.x / 12.5.7) at build time.
TARGET := iphone:clang:latest:12.0
THEOS_PACKAGE_SCHEME ?= rootless

# Make sure nothing upstream slipped in extra libs (e.g. -lnotify)
LIBRARIES :=

include $(THEOS)/makefiles/common.mk

# Optional: auto version from git (falls back to 0.1 if no tags)
PACKAGE_VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo 0.1)

# ---- Tweak ------------------------------------------------------------------
TWEAK_NAME := W2Like

# Main Logos file + any .m/.mm helpers next to it
W2Like_FILES := tweak.xm $(wildcard *.m) $(wildcard *.mm)

# Frameworks you actually use in the tweak
W2Like_FRAMEWORKS := UIKit AVFoundation CoreFoundation
# (Do NOT add -lnotify; notify_post resolves from libSystem on device)

# ARC for Obj-C
W2Like_CFLAGS += -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

# ---- Preferences bundle (optional) ------------------------------------------
BUNDLE_NAME := W2LikePrefs
W2LikePrefs_FILES := W2LRootListController.m
W2LikePrefs_INSTALL_PATH := /Library/PreferenceBundles
W2LikePrefs_FRAMEWORKS := UIKit
W2LikePrefs_PRIVATE_FRAMEWORKS := Preferences
# (No -lnotify here either)
W2LikePrefs_CFLAGS += -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

# ---- PreferenceLoader entry plist (if you keep Entry.plist in repo root) ----
# Copies Entry.plist -> /Library/PreferenceLoader/Preferences/W2LikePrefs.plist
after-stage::
	@set -e; \
	if [ -f Entry.plist ]; then \
	  mkdir -p "$(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences"; \
	  cp -a Entry.plist "$(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/W2LikePrefs.plist"; \
	fi

# ---- Pick the right control file automatically ------------------------------
# Keep two files at repo root:
#   control.rootless (iOS 14+)
#   control.rootful  (iOS 12.5.7)
# This copies the chosen one to "control" before packaging, then cleans up.

before-package::
	@set -e; \
	rm -f control; \
	SCHEME="$(THEOS_PACKAGE_SCHEME)"; \
	if [ -z "$$SCHEME" ]; then SCHEME=rootless; fi; \
	if [ -f "control.$$SCHEME" ]; then \
	  cp "control.$$SCHEME" control; \
	  echo "Using control.$$SCHEME"; \
	else \
	  echo "ERROR: control.$$SCHEME not found. Add control.rootless and control.rootful to repo root."; \
	  exit 1; \
	fi

after-package::
	@rm -f control || true
