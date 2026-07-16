APP_NAME := GateOpener
BUNDLE_ID := local.gateopener.app
BUILD_DIR := build
APP_BUNDLE := $(BUILD_DIR)/$(APP_NAME).app
EXECUTABLE := $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
ICON_SOURCE := Resources/GateOpener.png
ICONSET := $(BUILD_DIR)/$(APP_NAME).iconset
ICON := $(APP_BUNDLE)/Contents/Resources/$(APP_NAME).icns
SDK := $(shell xcrun --sdk macosx --show-sdk-path)
DEPLOYMENT_TARGET := 13.0
CONFIG ?= Debug
SWIFT_OPTIMIZATION_FLAGS_Debug := -Onone -g
SWIFT_OPTIMIZATION_FLAGS_Release := -O
SWIFT_OPTIMIZATION_FLAGS := $(SWIFT_OPTIMIZATION_FLAGS_$(CONFIG))

.PHONY: all app clean run

all: app

app: $(EXECUTABLE) $(APP_BUNDLE)/Contents/Info.plist $(ICON)

$(EXECUTABLE): Sources/GateOpener/main.swift
	@mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	swiftc \
		-sdk "$(SDK)" \
		-target arm64-apple-macosx$(DEPLOYMENT_TARGET) \
		-parse-as-library \
		$(SWIFT_OPTIMIZATION_FLAGS) \
		-framework SwiftUI \
		-framework AppKit \
		-o "$@" \
		"$<"

$(APP_BUNDLE)/Contents/Info.plist: Info.plist
	@mkdir -p "$(APP_BUNDLE)/Contents"
	@sed \
		-e 's/$${APP_NAME}/$(APP_NAME)/g' \
		-e 's/$${BUNDLE_ID}/$(BUNDLE_ID)/g' \
		"$<" > "$@"

$(ICON): $(ICON_SOURCE)
	@rm -rf "$(ICONSET)"
	@mkdir -p "$(ICONSET)" "$(APP_BUNDLE)/Contents/Resources"
	@sips -z 16 16 "$<" --out "$(ICONSET)/icon_16x16.png" >/dev/null
	@sips -z 32 32 "$<" --out "$(ICONSET)/icon_16x16@2x.png" >/dev/null
	@sips -z 32 32 "$<" --out "$(ICONSET)/icon_32x32.png" >/dev/null
	@sips -z 64 64 "$<" --out "$(ICONSET)/icon_32x32@2x.png" >/dev/null
	@sips -z 128 128 "$<" --out "$(ICONSET)/icon_128x128.png" >/dev/null
	@sips -z 256 256 "$<" --out "$(ICONSET)/icon_128x128@2x.png" >/dev/null
	@sips -z 256 256 "$<" --out "$(ICONSET)/icon_256x256.png" >/dev/null
	@sips -z 512 512 "$<" --out "$(ICONSET)/icon_256x256@2x.png" >/dev/null
	@sips -z 512 512 "$<" --out "$(ICONSET)/icon_512x512.png" >/dev/null
	@sips -z 1024 1024 "$<" --out "$(ICONSET)/icon_512x512@2x.png" >/dev/null
	@iconutil -c icns "$(ICONSET)" -o "$@"

run: app
	open "$(APP_BUNDLE)"

clean:
	rm -rf "$(BUILD_DIR)"
