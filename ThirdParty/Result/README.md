# Result

`Result` is a Swift framework that includes the `Result` enum and an
`ErrorType` protocol.

Both types are extremely small. I look forward to two changes in Swift's future:

* A fix for the Swift compiler issue that requires the `Success` case of
	`Result` to box its `T` type somehow. This repo uses
	[Box](https://github.com/robrix/Box) as a workaround.
* (Hopefully) The inclusion of these types or their moral equivalents in the
  Swift standard library, at which point this repo can be removed.

## Integration

Add this repository as a submodule, or use [Carthage](https://github.com/Carthage/Carthage/).

## Author

John Gallagher, jgallagher@bignerdranch.com

## License

Deferred is available under the MIT license. See the LICENSE file for more info.
