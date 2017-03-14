BUILD_TOOL = xcodebuild
BUILD_SCHEME = SQLite Mac
IOS_SIMULATOR = iPhone 6s
IOS_VERSION = 9.3
ifeq ($(BUILD_SCHEME),SQLite iOS)
	BUILD_ARGUMENTS = -scheme "$(BUILD_SCHEME)" -destination "platform=iOS Simulator,name=$(IOS_SIMULATOR),OS=$(IOS_VERSION)"
else
	BUILD_ARGUMENTS = -scheme "$(BUILD_SCHEME)"
endif

XCPRETTY := $(shell command -v xcpretty)
SWIFTCOV := $(shell command -v swiftcov)
GCOVR := $(shell command -v gcovr)
TEST_ACTIONS := clean build build-for-testing test-without-building

default: test

build:
	$(BUILD_TOOL) $(BUILD_ARGUMENTS)

test:
ifdef XCPRETTY
	@set -o pipefail && $(BUILD_TOOL) $(BUILD_ARGUMENTS) $(TEST_ACTIONS) | $(XCPRETTY) -c
else
	$(BUILD_TOOL) $(BUILD_ARGUMENTS) $(TEST_ACTIONS)
endif

coverage:
ifdef SWIFTCOV
	$(SWIFTCOV) generate --output coverage \
		$(BUILD_TOOL) $(BUILD_ARGUMENTS) -configuration Release test \
		-- ./SQLite/*.swift
ifdef GCOVR
	$(GCOVR) \
		--root . \
		--use-gcov-files \
		--html \
		--html-details \
		--output coverage/index.html \
		--keep
else
	@echo gcovr must be installed for HTML output: https://github.com/gcovr/gcovr
endif
else
	@echo swiftcov must be installed for coverage: https://github.com/realm/SwiftCov
	@exit 1
endif

clean:
	$(BUILD_TOOL) $(BUILD_ARGUMENTS) clean
	rm -r coverage

repl:
	@$(BUILD_TOOL) $(BUILD_ARGUMENTS) -derivedDataPath $(TMPDIR)/SQLite.swift > /dev/null && \
		swift -F '$(TMPDIR)/SQLite.swift/Build/Products/Debug'

sloc:
	@zsh -c "grep -vE '^ *//|^$$' SQLite/*/*.{swift,h,m} | wc -l"

.PHONY: test coverage clean repl sloc
