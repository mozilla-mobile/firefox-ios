SwiftKeychainWrapper
===============
A simple static wrapper for the iOS Keychain to allow you to use it in a similar fashion to user defaults. Written in Swift.

Supports adding and retrieving Strings, NSData and objects that implement NSCoding.

Usage
=====

Add a string value to keychain:
```Swift
let saveSuccessful: Bool = KeychainWrapper.setString("Some String", forKey: "myKey")
```

Retrieve a string value from keychain:
```Swift
let retrievedString: String? = KeychainWrapper.stringForKey("myKey")
```

Remove a string value from keychain:
```Swift
let removeSuccessful: Bool = KeychainWrapper.removeObjectForKey("myKey")
```

Notes
======
v1.0.5 has been tagged in master

This version converts the project to a proper Swift Framework and adds a podspec file to be compatible with the latest CocoaPods pre-release, which now supports Swift.

To see an example of usage with Cocoapods, I've created the repo SwiftKeychainWrapperExample:
https://github.com/jrendel/SwiftKeychainWrapperExample

In addition to adding Cocoapods support, there is a known issue with Swift keychain access causing it to fail. I don't know the full extent of the issue, but one "work around" is to turn off Swift compile optimization for release and the problem goes away:

http://stackoverflow.com/questions/26355630/swift-keychain-and-provisioning-profiles

This is not an ideal solution, so as recommended, I've added an objective c wrapper/helper for the keychain data retrieval. This allows the KeychainWrapper to work as expected with Swift compile optimizations enabled.

======

v1.0.2 has been updated for Xcode 6.1

Currently this is not a static library, as static libraries do not support swift code when I created this. I intend to update this project to a static library and make it a cocoapod once supported.

I've been using an Objective-C based wrapper in my own projects for the past couple years. The original library I wrote for myself was based on the following tutorial:

http://www.raywenderlich.com/6475/basic-security-in-ios-5-tutorial-part-1

This is a rewrite of that code in Swift.
