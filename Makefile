include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = W2LikePrefs
W2LikePrefs_FILES = W2LRootListController.m
W2LikePrefs_INSTALL_PATH = /Library/PreferenceBundles
W2LikePrefs_FRAMEWORKS = UIKit
W2LikePrefs_PRIVATE_FRAMEWORKS = Preferences
W2LikePrefs_CFLAGS = -fobjc-arc
W2LikePrefs_RESOURCE_DIRS = Resources

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp Resources/Entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/W2LikePrefs.plist$(ECHO_END)
