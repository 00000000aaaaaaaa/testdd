export TARGET = iphone:clang:latest:15.0
export ARCHS = arm64 arm64e
export THEOS_PACKAGE_SCHEME = rootless

INSTALL_TARGET_PROCESSES = MobileSafari SafariViewService Preferences

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = safarisettingsdd
safarisettingsdd_FILES = Tweak.x
safarisettingsdd_CFLAGS = -fobjc-arc -Wno-unused-variable -Wno-unused-function -Wno-deprecated-declarations -Wno-error=incompatible-pointer-types
safarisettingsdd_FRAMEWORKS = UIKit Foundation WebKit
safarisettingsdd_LDFLAGS = -rpath /var/jb/Library/Frameworks -rpath /var/jb/usr/lib

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = safarisettingsddprefs
safarisettingsddprefs_FILES = prefs/SSDRootListController.m
safarisettingsddprefs_INSTALL_PATH = /Library/PreferenceBundles
safarisettingsddprefs_FRAMEWORKS = UIKit
safarisettingsddprefs_LDFLAGS = -undefined dynamic_lookup
safarisettingsddprefs_CFLAGS = -fobjc-arc
safarisettingsddprefs_RESOURCE_DIR = prefs/Resources

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp prefs/entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/safarisettingsdd.plist$(ECHO_END)

after-install::
	install.exec "killall -9 MobileSafari SafariViewService Preferences 2>/dev/null || true"
