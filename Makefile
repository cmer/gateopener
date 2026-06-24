APP_NAME := GateOpener
BUNDLE_ID := local.gateopener.app
BUILD_DIR := build
APP_BUNDLE := $(BUILD_DIR)/$(APP_NAME).app
EXECUTABLE := $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
SDK := $(shell xcrun --sdk macosx --show-sdk-path)
DEPLOYMENT_TARGET := 13.0
CONFIG ?= Debug
SWIFT_OPTIMIZATION_FLAGS_Debug := -Onone -g
SWIFT_OPTIMIZATION_FLAGS_Release := -O
SWIFT_OPTIMIZATION_FLAGS := $(SWIFT_OPTIMIZATION_FLAGS_$(CONFIG))

.PHONY: all app clean run

all: app

app: $(EXECUTABLE) $(APP_BUNDLE)/Contents/Info.plist

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

run: app
	open "$(APP_BUNDLE)"

clean:
	rm -rf "$(BUILD_DIR)"
