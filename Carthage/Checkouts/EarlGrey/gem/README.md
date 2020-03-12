# EarlGrey

[![Gem Version](https://badge.fury.io/rb/earlgrey.svg)](https://rubygems.org/gems/earlgrey)

Automatically installs EarlGrey. Supports carthage, cocoapods, and Swift.

```
$ earlgrey help install
Usage:
  earlgrey install -t, --target=TARGET

Options:
  -p, [--project=PROJECT]            # Project
  -t, --target=TARGET                # EarlGrey
  -s, [--scheme=SCHEME]              # EarlGrey.xcscheme
      [--carthage], [--no-carthage]
                                     # Default: true
      [--swift], [--no-swift]
                                     # Default: true
      [--swift-version]
                                     # Default: 4.0
                                     # Supported Values: 3.0, 4.0.

Installs EarlGrey into an Xcode unit test target
```

## Usage

Create new Target `iOS Unit Testing Bundle` then add a new scheme
`Product → Scheme → Manage Schemes` and mark it as shared.
See [EarlGrey docs for screenshots](https://github.com/google/EarlGrey/blob/master/docs/install-and-run.md#step-1-set-up-a-test-target)

Now run the install command with the test target name:

- `earlgrey install -t AutoEarlGrey`

See [the example project](https://github.com/bootstraponline/swift_xcuitest_example/tree/earlgrey/Example)
which defines `AutoEarlGrey`.

## Rake

The gem uses Rake to define common tasks. The tests are run with `rake spec`.
By default `rake` will run `spec`, `rubocop`, and `warn`.

```
$ rake -T
rake build                 # Build the earlgrey gem into the pkg directory
rake clean                 # Remove any temporary products
rake clobber               # Remove any generated files
rake install               # Build and install earlgrey gem into system gems
rake install:local         # Build and install earlgrey gem into system gems without network access
rake release[remote]       # Create a version tag and build and push earlgrey gem to Rubygems
rake rubocop               # Run RuboCop
rake rubocop:auto_correct  # Auto-correct RuboCop offenses
rake spec                  # Run RSpec code examples
rake warn                  # Check for warnings
```

## Notes

The install command does the following by default:

-- Adds EarlGrey.swift to test target
- FRAMEWORK_SEARCH_PATHS = "$(SRCROOT)/Carthage/Build/iOS";
- HEADER_SEARCH_PATHS = "$(SRCROOT)/Carthage/Build/iOS/**";
- Add EarlGrey.swift to compile sources (PBXSourcesBuildPhase)
- Link binary with libraries. EarlGrey.framework
- Use carthage copy-files to ensure frameworks are signed, dSYMs/BCSymbolMaps copied.
  Carthage doesn't sign when building.
- Updates scheme DYLD_INSERT_LIBRARIES so it can find EarlGrey.framework
