ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

THEOS_DEVICE_IP = 127.0.0.1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = W2Like

W2Like_FILES = Tweak.xm W2AssetReader.m W2PrefsManager.m
W2Like_FRAMEWORKS = UIKit AVFoundation CoreMedia CoreVideo
W2Like_PRIVATE_FRAMEWORKS = 
W2Like_CFLAGS = -fobjc-arc

# IMPORTANT: process names, not bundle IDs. Adjust to match your device if needed:
# Common names: Instagram, TikTok (or Musically), Facebook, Camera
INSTALL_TARGET_PROCESSES = Instagram TikTok Facebook Camera

include $(THEOS_MAKE_PATH)/tweak.mk

# Preferences bundle
SUBPROJECTS += W2LikePrefs
include $(THEOS_MAKE_PATH)/aggregate.mk
