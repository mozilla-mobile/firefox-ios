# Change Log

* **Version 7.0.0**: *(2019/03/26)* - Updated for Xcode 10.2/Swift 5.0, adds additional log levels: notice, alert, and emergency
* **Version 6.1.0**: *(2018/09/16)* - Fix for Xcode 10.0 warnings/Swift 4.2, other minor tweaks
* **Version 6.0.4**: *(2018/06/11)* - Fix for Xcode 9.3 warnings/Swift 4.1 (thanks @ijaureguialzo), and other fixes
* **Version 6.0.2**: *(2017/11/30)* - Fix for Xcode warning about deprecated .characters (thanks @WeidongGu)
* **Version 6.0.1**: *(2017/09/30)* - Set the SWIFT_VERSION value in the Podspec (via `pod_target_xcconfig`)
* **Version 6.0.0**: *(2017/09/28)* - Updated for Xcode 9 and Swift 4.0
* **Version 5.0.5**: *(2017/09/28)* - Fixed a warning in Xcode 9 when still using Swift 3
* **Version 5.0.4**: *(2017/09/27)* - Fixed some issues in the AutoRotatingFileDestination class, added fileAttribute options, other fixes
* **Version 5.0.1**: *(2017/04/06)* - Updated for Xcode 8.3/Swift 3.1. Added a new fancy AutoRotatingFileDestination, that will automatically archive your log files based on size, and/or time interval. Check out the macOS demo app for a usage example. All new tags on the branches for versioning to be compatible with the Swift Package Manager. If you're referencing tags such as `Version_4.0.0`, please convert to the new equivalent tag `4.0.0`.
* **Version 5.0.0**: *(2017/04/01)* - Invalid version, due to a merged PR that included stray tags. 
* **Version 4.1.0**: *(2017/04/01)* - Invalid version, due to a merged PR that included stray tags.
* **Version 4.0.0**: *(2016/09/20)* - First full release for Swift 3.0. Squeezed in a couple of feature requests: ability to change log level labels, and a formatter to add a prefix and/or postfix to messages.
* **Version 4.0.0-beta.5**: *(2016/09/19)* - Tweaked userInfo handling for Tags/Devs, introduced subspecs for CocoaPods, made the userInfo helpers optional (consider them experimental and subject to change even after 4.0.0 is actually moved out of beta status).
* **Version 4.0.0-beta.4**: *(2016/09/14)* - Removed escaping from closures, fixed issue using String/StaticString for function/file names.
* **Version 3.6.0**: *(2016/09/14)* - Updated for Swift 2.3.
* **Version 3.5.3**: *(2016/09/14)* - Fixed podspec.
* **Version 3.5.2**: *(2016/09/13)* - Backported Objective-C exception handling, removed escaping from closures, fixed issue using String/StaticString for function/file names.
* **Version 4.0.0-beta.3**: *(2016/09/11)* - Fixed issue with CocoaPods using multiple `XCGLogger.h` files, added Objective-C exception handling to fix #123
* **Version 4.0.0-beta.2**: *(2016/09/04)* - Updated docs, added filtering by tag and developer, added demo for filters
* **Version 4.0.0-beta.1**: *(2016/09/01)* - First beta for Swift 3 compatibility, including a lot of architecture changes
* **Version 3.5.1**: *(2016/08/28)* - Added documentation, improved tests.
* **Version 3.5**: *(2016/08/23)* - Added the ability to log anything, no longer limited to strings, or required to use string interpolation. Thanks to @Zyphrax #130 and @mishimay #140. Can also now call a logging method with no parameters, such as `log.debug()`. This will log the result of customizable `testNoMessageClosure` property. By default that's just an empty string, but should allow for some interesting features, (like an automatic counter). 
* **Version 3.4**: *(2016/08/21)* - Finally added an option to append to an existing log file, and added a basic log rotation method. Other bug fixes.
* **Version 3.3**: *(2016/03/27)* - Updated for Xcode 7.3 (Swift 2.2). If you're still using 7.2 (Swift 2.1), you must use XCGLogger 3.2.
* **Version 3.2**: *(2016/01/04)* - Added option to omit the default destination (for advanced usage), added background logging option
* **Version 3.1.1**: *(2015/11/18)* - Minor clean up, fixes an app submission issue for tvOS
* **Version 3.1**: *(2015/10/23)* - Initial support for tvOS
* **Version 3.1b1**: *(2015/09/09)* - Initial support for tvOS
* **Version 3.0**: *(2015/09/09)* - Bug fix, and WatchOS 2 support (thanks @ymyzk)
* **Version 2.4**: *(2015/09/09)* - Minor bug fix, likely the last release for Swift 1.x
* **Version 3.0b3**: *(2015/08/24)* - Added option to include the log identifier in log messages #79
* **Version 2.3**: *(2015/08/24)* - Added option to include the log identifier in log messages #79
* **Version 3.0b2**: *(2015/08/11)* - Updated for Swift 2.0 (Xcode 7 Beta 5)
* **Version 2.2**: *(2015/08/11)* - Internal restructuring, easier to create new log destination subclasses. Can disable function names, and/or dates. Added optional new log destination that uses NSLog instead of println().
* **Version 3.0b1**: *(2015/06/18)* - Swift 2.0 support/required. Consider this unstable for now, as Swift 2.0 will likely see changes before final release, and this library may undergo some architecture changes (time permitting).
* **Version 2.1.1**: *(2015/06/18)* - Fixed two minor bugs wrt XcodeColors.
* **Version 2.1**: *(2015/06/17)* - Added support for XcodeColors (https://github.com/robbiehanson/XcodeColors). Undeprecated the \*Exec() methods.
* **Version 2.0**: *(2015/04/14)* - Requires Swift 1.2. Removed some workarounds/hacks for older versions of Xcode. Removed thread based caching of NSDateFormatter objects since they're now thread safe. You can now use the default date formatter, or create and assign your own and it'll be used. Added Thread name option (Thanks to Nick Strecker https://github.com/tekknick ). Add experimental support for CocoaPods. 
* **Version 1.9**: *(2015/04/14)* - Deprecated the \*Exec() methods in favour of just using a trailing closure on the logging methods (Thanks to Nick Strecker https://github.com/tekknick ). This will be the last version for Swift 1.1.
* **Version 1.8.1**: *(2014/12/31)* - Added a workaround to the Swift compiler's optimization bug, restored optimization level back to Fastest
* **Version 1.8**: *(2014/11/16)* - Added warning log level (Issue #16)
* **Version 1.7**: *(2014/09/27)* - Reorganized to be used as a subproject instead of a framework, fixed threading
* **Version 1.6**: *(2014/09/09)* - Updated for Xcode 6.1 Beta 1
* **Version 1.5**: *(2014/08/23)* - Updated for Xcode 6 Beta 6
* **Version 1.4**: *(2014/08/04)* - Updated for Xcode 6 Beta 5, removed `__FUNCTION__` workaround
* **Version 1.3**: *(2014/07/27)* - Updated to use public/internal/private access modifiers
* **Version 1.2**: *(2014/07/01)* - Added exec methods to selectively execute code
* **Version 1.1**: *(2014/06/22)* - Changed the internal architecture to allow for more flexibility
* **Version 1.0**: *(2014/06/09)* - Initial Release

