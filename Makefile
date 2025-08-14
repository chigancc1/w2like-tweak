# ---- Universal settings (safe for Theos on Linux) --------------------------
ARCHS := arm64 arm64e
TARGET := iphone:clang:latest:14.5   # <= forces a 14.x SDK to avoid iOS 16 header issues
THEOS_PACKAGE_SCHEME = rootless

PACKAGE_VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo 0.1)

include $(THEOS)/makefiles/common.mk

# ---- Tweak -----------------------------------------------------------------
TWEAK_NAME = W2Like

# Compile the main Logos file and any .m/.mm you’ve added next to it
W2Like_FILES  = tweak.xm $(wildcard *.m) $(wildcard *.mm)
W2Like_CFLAGS += -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

# ---- Preferences bundle (optional) -----------------------------------------
# If you don't want this yet, delete this block and the bundle.mk include.
BUNDLE_NAME = W2LikePrefs

W2LikePrefs_FILES  = W2LRootListController.m
W2LikePrefs_INSTALL_PATH = /Library/PreferenceBundles
W2LikePrefs_FRAMEWORKS = UIKit
W2LikePrefs_PRIVATE_FRAMEWORKS = Preferences
W2LikePrefs_CFLAGS += -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
