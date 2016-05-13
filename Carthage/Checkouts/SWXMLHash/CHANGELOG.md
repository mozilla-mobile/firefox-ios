## v2.0.4 (November 13, 2015)

* Add explicit `watchOS` and `tvOS` targets to the project for better Carthage support

## v2.0.3 (October 25, 2015)

* Added support for Carthage builds with bitcode
* Bumped to `xcode7.1` usage of Quick and Nimble

## v2.0.2 (October 21, 2015)

* Added `tvOS` deployment target for CocoaPods and tvOS support

## v2.0.1 (September 22, 2015)

* Added `watchos` deployment target for CocoaPods and watchOS support

## v2.0.0 (September 16, 2015)

* Added Swift 2.0 / Xcode 7.0 support
    * While API parity should exist between v1 and v2, the library attempts to support the new error handling support in Swift 2.0 when you call the `byIndex`/`byKey` methods respectively (the subscript methods don't currently support throwing exceptions).
    * Note that the existing subscript methods can still be used, though.
* Changed `.Error` to `.XMLError` - this is part of handling Swift 2.0's new error handling support.
    * The prior `.Error` case received an `NSError` type whereas the new `.XMLError` case receives an `Error` which is an `ErrorType` with various cases to show which part of the parsing threw an error (i.e. `Attribute`, `AttributeValue`, `Key`, `Index`, or `Init`).

## v1.1.1 (August 3, 2015)

* Changed code signing options on the project to not code sign for OSX and to target iOS Developer.

## v1.1.0 (June 20, 2015)

* Add `configure` method off of `SWXMLHash` to allow for setting variable number of options.
    * At this time, the only options are `shouldProcessLazily` and `shouldProcessNamespaces`.
    * `shouldProcessLazily` provides the same parsing as directly calling `lazy`. I'm considering deprecating the top-level `lazy` method in favor of having it be set in `configure`, but I'm open to suggestions here (as well as to suggestions regarding the `configure` method in general).
    * `shouldProcessNamespaces` provides the functionality requested in [issue #30](https://github.com/drmohundro/SWXMLHash/issues/30).

## v1.0.1 (May 18, 2015)

* Quick/Nimble are no longer used via git submodules, but are instead being pulled in via Carthage.

## v1.0.0 (April 10, 2015)

* Lazy loading support is available ([issue #11](https://github.com/drmohundro/SWXMLHash/issues/11))
  * Call `.lazy` instead of `.parse`
  * Performance can be drastically improved when doing lazy parsing.
* See [PR #26](https://github.com/drmohundro/SWXMLHash/pull/26) for details on these:
  * Remove automatic whitespace trimming - that will be a responsibility of the caller.
  * Make umbrella header public.
  * Introduce shared schemes.
* Xcode 6.3 and Swift 1.2 support.
* Published version 1.0.0 CocoaPod.

## v0.6.4 (February 26, 2015)

* Fixed bug with interleaved XML (issue #19)
* Published version 0.6.4 CocoaPod.

## v0.6.3 (February 23, 2015)

* Fixed bug where mixed content wasn't supported (i.e. elements with both text and child elements).
* Published version 0.6.3 CocoaPod.

## v0.6.2 (February 9, 2015)

* Published version 0.6.2 CocoaPod. (yes, it should have gone with 0.6.1 but I tagged it too early)

## v0.6.1 (February 9, 2015)

* Fixed bug with `children` so that XML element order is preserved when enumerating XML child elements.
* Only require Foundation.h instead of UIKit.h.

## v0.6.0 (January 30, 2015)

* Added `children` property to allow for enumerating all child elements.
* CocoaPods support is live (see current [docset on CocoaPods](http://cocoadocs.org/docsets/SWXMLHash/0.6.0/))

## v0.5.5 (January 25, 2015)

* Added OSX target, should allow SWXMLHash to work in OSX as well as iOS.

## v0.5.4 (November 2, 2014)

* Added the `withAttr` method to allow for lookup by an attribute and its value. See README or specs for details.

## v0.5.3 (October 21, 2014)

* XCode 6.1 is out on the app store now and I had to make a minor tweak to get the code to compile.

## v0.5.2 (October 6, 2014)

* Fix handling of whitespace in XML which resolves issue #6.
  * Apparently the `foundCharacters` method of `NSXMLParser` also gets called for whitespace between elements.
  * There are now specs to account for this issue as well as a spec to document CDATA usage, too.

## v0.5.1 (October 5, 2014)

* XCode 6.1 compatibility - added explicit unwrapping of `NSXMLParser`.
* Updated to latest Quick, Nimble for 6.1 compilation.
* Added specs to try to help with issue #6.

## v0.5.0 (September 30, 2014)

* Made `XMLIndexer` implement the `SequenceType` protocol to allow for for-in usage over it. The `all` method still exists as an option, but isn't necessary for simply iterating over sequences.
* Formally introduced the change log!

## v0.4.2 (August 19, 2014)

* XCode 6 beta 6 compatibility.

## v0.4.1 (August 11, 2014)

* Fixed bugs related to the `all` method when only one element existed.

## v0.4.0 (August 8, 2014)

* Refactored to make the `parse` method class-level instead of instance-level.

## v0.3.1 (August 7, 2014)

* Moved all types into one file for ease of distribution for now.

## v0.3.0 (July 28, 2014)

* XCode 6 beta 4 compatibility.

## v0.2.0 (July 14, 2014)

* Heavy refactoring to introduce enum-based code (based on [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)).
* The public `parse` method now takes a string in addition to `NSData`.
* Initial attribute support added.

## v0.1.0 (July 8, 2014)

* Initial release.
* This version is an early iteration to get the general idea down, but isn't really ready to be used.
