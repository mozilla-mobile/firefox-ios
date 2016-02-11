BUILD_TOOL = xcodebuild
BUILD_SCHEME = SQLite Mac
BUILD_ARGUMENTS = -scheme "$(BUILD_SCHEME)"

XCPRETTY := $(shell command -v xcpretty)
SWIFTCOV := $(shell command -v swiftcov)
GCOVR := $(shell command -v gcovr)

default: test

build:
	$(BUILD_TOOL) $(BUILD_ARGUMENTS)

test:
ifdef XCPRETTY
	@set -o pipefail && $(BUILD_TOOL) $(BUILD_ARGUMENTS) test | $(XCPRETTY) -c
else
	$(BUILD_TOOL) $(BUILD_ARGUMENTS) test
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
	@zsh -c "grep -vE '^ *//|^$$' SQLite/*.{swift,h,c} | wc -l"

.PHONY: test coverage clean repl sloc
