# ---- Theos build config (Linux/GitHub Actions) ------------------------------
ARCHS := arm64 arm64e
# Broad min version; the workflow pins the SDK (14.x / 12.5.7) at build time.
TARGET := iphone:clang:latest:12.0
# Default build is rootless; override with THEOS_PACKAGE_SCHEME=rootful for iOS 12–13
THEOS_PACKAGE_SCHEME ?= rootless

# >>> IMPORTANT: Select the control file BEFORE including Theos <<<
ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
  THEOS_CONTROL_PATH := $(CURDIR)/control.rootless
else
  THEOS_CONTROL_PATH := $(CURDIR)/control.rootful
endif

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

# ---- PreferenceLoader entry plist (optional) --------------------------------
# Copies Entry.plist -> /Library/PreferenceLoader/Preferences/W2LikePrefs.plist
after-stage::
	@set -e; \
	if [ -f Entry.plist ]; then \
	  mkdir -p "$(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences"; \
	  cp -a Entry.plist "$(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/W2LikePrefs.plist"; \
	fi
