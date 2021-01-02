# Do not manually invoke this script with a custom GREED_TARGET
# variable. Use simulate.sh instead.
GREED_TARGET ?= iOS

CFLAGS = 

ifeq ($(GREED_TARGET),iOS)

# iOS (native)
ARCHS = arm64e arm64 armv7
TARGET := iphone:11.2:6.0
CFLAGS += -DGREED_TARGET_IOS=1

else
ifeq ($(GREED_TARGET),tvOS)

# tvOS (native)
ARCHS = arm64 arm64e
TARGET := appletv:clang:latest:12.0
CFLAGS += -DGREED_TARGET_TVOS=1

else

# iOS (simulator)
ARCHS = x86_64
TARGET := simulator:clang:latest:7.0
CFLAGS += -DGREED_TARGET_SIMULATOR=1
APPLE_CERTIFICATE ?= -
TARGET_CODESIGN_FLAGS ?= -s '$(APPLE_CERTIFICATE)'

ifeq ($(GREED_TARGET),tvOS_Simulator)

# tvOS (simulator)
CFLAGS += -DGREED_TARGET_TVOS=1 -Wno-overriding-t-option -target x86_64-apple-tvos11.2.0 -isysroot $(shell xcode-select -p)/Platforms/AppleTVSimulator.platform/Developer/SDKs/AppleTVSimulator.sdk
LDFLAGS += -Wno-overriding-t-option -target x86_64-apple-tvos11.2.0 -isysroot $(shell xcode-select -p)/Platforms/AppleTVSimulator.platform/Developer/SDKs/AppleTVSimulator.sdk

else
ifeq ($(GREED_TARGET),iOS_Simulator)

# iOS (simulator)
CFLAGS += -DGREED_TARGET_IOS=1

else

$(error GREED_TARGET environment variable contains an invalid value. It should be tvOS, iOS, tvOS_Simulator or iOS_Simulator)

endif # iOS (simulator)
endif # tvOS (simulator)
endif # tvOS
endif # iOS

export CFLAGS TARGET ARCHS LDFLAGS

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Greed

Greed_FILES = $(wildcard *.mm) $(wildcard *.xm)
Greed_CFLAGS = -fobjc-arc -Wno-unused-function -include Tweak.h

include $(THEOS_MAKE_PATH)/tweak.mk

ifeq ($(GREED_TARGET),iOS)
SUBPROJECTS += GreedPreferences
include $(THEOS_MAKE_PATH)/aggregate.mk
endif