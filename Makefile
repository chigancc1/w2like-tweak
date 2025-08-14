# ---- Theos build config (Linux) --------------------------------------------
ARCHS = arm64 arm64e
# Force 14.5 SDK to avoid iOS 16 header/attribute issues on Linux clang
TARGET := iphone:clang:latest:14.5
THEOS_PACKAGE_SCHEME = rootless

# Nice version string if repo is a git repo (optional)
PACKAGE_VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo 0.1)

include $(THEOS)/makefiles/common.mk

# ---- Tweak -----------------------------------------------------------------
TWEAK_NAME = W2Like
# Make it robust to file name casing:
W2Like_FILES = $(wildcard *.xm) $(wildcard *.m) $(wildcard *.mm)
W2Like_CFLAGS += -fobjc-arc
include $(THEOS_MAKE_PATH)/tweak.mk

# ---- Preferences bundle (optional) -----------------------------------------
# If you aren’t ready for prefs yet, delete this block + the bundle include.
BUNDLE_NAME = W2LikePrefs
W2LikePrefs_FILES = W2LRootListController.m
W2LikePrefs_INSTALL_PATH = /Library/PreferenceBundles
W2LikePrefs_FRAMEWORKS = UIKit
W2LikePrefs_PRIVATE_FRAMEWORKS = Preferences
W2LikePrefs_CFLAGS += -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
