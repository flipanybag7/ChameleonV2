ARCHS = arm64
TARGET = iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = Chameleon
Chameleon_FILES = app/main.m app/CHAppDelegate.m app/CHRootViewController.m app/CHProfileStore.m app/CHInstalledAppCatalog.m app/CHAppLibraryController.m app/CHMapController.m
Chameleon_CFLAGS = -fobjc-arc
Chameleon_FRAMEWORKS = UIKit Foundation UniformTypeIdentifiers MapKit CoreLocation WebKit
Chameleon_CODESIGN_FLAGS = -Sapp/Chameleon.entitlements
Chameleon_INSTALL_PATH = /Applications
Chameleon_RESOURCE_DIRS = app/Resources

include $(THEOS_MAKE_PATH)/application.mk

TWEAK_NAME = ProfileRuntime
ProfileRuntime_FILES = Tweak.xm Container.xm DeviceIdentity.xm
ProfileRuntime_CFLAGS = -fobjc-arc
ProfileRuntime_FRAMEWORKS = Foundation UIKit CoreTelephony

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard || true"
