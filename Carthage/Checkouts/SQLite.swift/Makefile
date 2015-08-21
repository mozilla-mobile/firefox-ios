BUILD_TOOL = xcodebuild
BUILD_SDK = macosx
BUILD_ARGUMENTS = -scheme SQLite -sdk $(BUILD_SDK)

default: test

build:
	$(BUILD_TOOL) $(BUILD_ARGUMENTS)

test:
	$(BUILD_TOOL) $(BUILD_ARGUMENTS) test

clean:
	$(BUILD_TOOL) $(BUILD_ARGUMENTS) clean

repl:
	@$(BUILD_TOOL) $(BUILD_ARGUMENTS) -derivedDataPath $(TMPDIR)/SQLite.swift > /dev/null && \
		swift -F '$(TMPDIR)/SQLite.swift/Build/Products/Debug'

sloc:
	@zsh -c "grep -vE '^ *//|^$$' SQLite/*.{swift,h,c} | wc -l"

