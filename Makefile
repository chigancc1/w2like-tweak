# ---- Theos build config (Linux/GitHub Actions) ------------------------------
# Rootful / classic layout (no THEOS_PACKAGE_SCHEME set)
ARCHS := arm64
# Broad min version; the workflow will pin the SDK (prefers 12.5.7)
TARGET := iphone:clang:latest:12.0

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

# ---- Preferences bundle -----------------------------------------------------
BUNDLE_NAME := W2LikePrefs
W2LikePrefs_FILES := W2LRootListController.m
# Rootful path (classic)
W2LikePrefs_INSTALL_PATH := /Library/PreferenceBundles
W2LikePrefs_FRAMEWORKS := UIKit
W2LikePrefs_PRIVATE_FRAMEWORKS := Preferences
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
