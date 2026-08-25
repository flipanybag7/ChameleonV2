ARCHS = arm64
TARGET = iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ProfileRuntime
ProfileRuntime_FILES = Tweak.xm
ProfileRuntime_CFLAGS = -fobjc-arc
ProfileRuntime_FRAMEWORKS = Foundation
ProfileRuntime_PACKAGE_CONTROL_PATH = ./control

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard || true"
