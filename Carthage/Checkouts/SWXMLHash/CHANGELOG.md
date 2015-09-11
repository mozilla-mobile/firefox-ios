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
