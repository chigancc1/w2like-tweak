# ---- Theos build config (Linux) --------------------------------------------
ARCHS := arm64 arm64e
# Use “latest” toolchain but a broad min version (the workflow pins the SDK itself)
TARGET := iphone:clang:latest:12.0
THEOS_PACKAGE_SCHEME ?= rootless

include $(THEOS)/makefiles/common.mk

# --- tweak ---
TWEAK_NAME := W2Like
W2Like_FILES := tweak.xm $(wildcard *.m) $(wildcard *.mm)
W2Like_CFLAGS += -fobjc-arc
include $(THEOS_MAKE_PATH)/tweak.mk

# --- prefs bundle (optional) ---
BUNDLE_NAME := W2LikePrefs
W2LikePrefs_FILES := W2LRootListController.m
W2LikePrefs_INSTALL_PATH := /Library/PreferenceBundles
W2LikePrefs_FRAMEWORKS := UIKit
W2LikePrefs_PRIVATE_FRAMEWORKS := Preferences
W2LikePrefs_CFLAGS += -fobjc-arc
include $(THEOS_MAKE_PATH)/bundle.mk

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
