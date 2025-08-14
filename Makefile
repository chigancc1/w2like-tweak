# ---- Theos build config (Linux/GitHub Actions) ------------------------------
# Rootful iOS 12.x (A7–A11) devices → build only arm64 (no arm64e)
ARCHS := arm64

# Broad min version; your workflow will pin the SDK it finds (12.x/14.x).
TARGET := iphone:clang:latest:12.0

# Force rootful package scheme
THEOS_PACKAGE_SCHEME := rootful
# If you keep multiple control files, uncomment this to point to the rootful one:
# THEOS_CONTROL_PATH := $(PWD)/debian/control.rootful

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
