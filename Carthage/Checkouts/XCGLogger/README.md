![XCGLogger][xcglogger-logo]

[![badge-language]][swift.org]
[![badge-platforms]][swift.org]
[![badge-license]][license]

[![badge-travis]][travis]
[![badge-swiftpm]][swiftpm]
[![badge-cocoapods]][cocoapods-xcglogger]
[![badge-carthage]][carthage]

[![badge-mastodon]][mastodon-davewoodx]
[![badge-twitter]][twitter-davewoodx]

[![badge-sponsors]][cerebral-gardens]
[![badge-patreon]][patreon-davewoodx]

## tl;dr
XCGLogger is the original debug log module for use in Swift projects. 

Swift does not include a C preprocessor so developers are unable to use the debug log `#define` macros they would use in Objective-C. This means our traditional way of generating nice debug logs no longer works. Resorting to just plain old `print` calls means you lose a lot of helpful information, or requires you to type a lot more code.

XCGLogger allows you to log details to the console (and optionally a file, or other custom destinations), just like you would have with `NSLog()` or `print()`, but with additional information, such as the date, function name, filename and line number.

Go from this:

```Simple message```

to this:

```2014-06-09 06:44:43.600 [Debug] [AppDelegate.swift:40] application(_:didFinishLaunchingWithOptions:): Simple message```

#### Example
<img src="https://raw.githubusercontent.com/DaveWoodCom/XCGLogger/master/ReadMeImages/SampleLog.png" alt="Example" style="width: 690px;" />

### Communication _(Hat Tip AlamoFire)_

* If you need help, use [Stack Overflow][stackoverflow] (Tag '[xcglogger][stackoverflow]').
* If you'd like to ask a general question, use [Stack Overflow][stackoverflow].
* If you've found a bug, open an issue.
* If you have a feature request, open an issue.
* If you want to contribute, submit a pull request.
* If you use XCGLogger, please Star the project on [GitHub][github-xcglogger]

## Installation

### Git Submodule

Execute:

```git submodule add https://github.com/DaveWoodCom/XCGLogger.git```
	
in your repository folder.

### [Carthage][carthage]

Add the following line to your `Cartfile`.

```github "DaveWoodCom/XCGLogger" ~> 7.0.0```

Then run `carthage update --no-use-binaries` or just `carthage update`. For details of the installation and usage of Carthage, visit [its project page][carthage].

Developers running 5.0 and above in Swift will need to add `$(SRCROOT)/Carthage/Build/iOS/ObjcExceptionBridging.framework` to their Input Files in the Copy Carthage Frameworks Build Phase. 

### [CocoaPods][cocoapods]

Add something similar to the following lines to your `Podfile`. You may need to adjust based on your platform, version/branch etc.

```
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

pod 'XCGLogger', '~> 7.0.0'
```

Specifying the pod `XCGLogger` on its own will include the core framework. We're starting to add subspecs to allow you to include optional components as well:

`pod 'XCGLogger/UserInfoHelpers', '~> 7.0.0'`: Include some experimental code to help deal with using UserInfo dictionaries to tag log messages.

Then run `pod install`. For details of the installation and usage of CocoaPods, visit [its official web site][cocoapods].

Note: Before CocoaPods 1.4.0 it was not possible to use multiple pods with a mixture of Swift versions. You may need to ensure each pod is configured for the correct Swift version (check the targets in the pod project of your workspace). If you manually adjust the Swift version for a project, it'll reset the next time you run `pod install`. You can add a `post_install` hook into your podfile to automate setting the correct Swift versions. This is largely untested, and I'm not sure it's a good solution, but it seems to work:

```
post_install do |installer|
    installer.pods_project.targets.each do |target|
        if ['SomeTarget-iOS', 'SomeTarget-watchOS'].include? "#{target}"
            print "Setting #{target}'s SWIFT_VERSION to 4.2\n"
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = '4.2'
            end
        else
            print "Setting #{target}'s SWIFT_VERSION to Undefined (Xcode will automatically resolve)\n"
            target.build_configurations.each do |config|
                config.build_settings.delete('SWIFT_VERSION')
            end
        end
    end

    print "Setting the default SWIFT_VERSION to 3.2\n"
    installer.pods_project.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '3.2'
    end
end
```

You can adjust that to suit your needs of course.

### [Swift Package Manager][swiftpm]

Add the following entry to your package's dependencies:

```
.Package(url: "https://github.com/DaveWoodCom/XCGLogger.git", majorVersion: 7)
```	

### Backwards Compatibility

Use:
* XCGLogger version [7.0.0][xcglogger-7.0.0] for Swift 5.0
* XCGLogger version [6.1.0][xcglogger-6.1.0] for Swift 4.2
* XCGLogger version [6.0.4][xcglogger-6.0.4] for Swift 4.1
* XCGLogger version [6.0.2][xcglogger-6.0.2] for Swift 4.0
* XCGLogger version [5.0.5][xcglogger-5.0.5] for Swift 3.0-3.2
* XCGLogger version [3.6.0][xcglogger-3.6.0] for Swift 2.3
* XCGLogger version [3.5.3][xcglogger-3.5.3] for Swift 2.2
* XCGLogger version [3.2][xcglogger-3.2] for Swift 2.0-2.1
* XCGLogger version [2.x][xcglogger-2.x] for Swift 1.2
* XCGLogger version [1.x][xcglogger-1.x] for Swift 1.1 and below.

## Basic Usage (Quick Start)

_This quick start method is intended just to get you up and running with the logger. You should however use the [advanced usage below](#advanced-usage-recommended) to get the most out of this library._

Add the XCGLogger project as a subproject to your project, and add the appropriate library as a dependency of your target(s).
Under the `General` tab of your target, add `XCGLogger.framework` and `ObjcExceptionBridging.framework` to the `Embedded Binaries` section.

Then, in each source file:

```Swift
import XCGLogger
```

In your AppDelegate (or other global file), declare a global constant to the default XCGLogger instance.

```Swift
let log = XCGLogger.default
```

In the
```Swift
application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]? = nil) // iOS, tvOS
```

or

```Swift
applicationDidFinishLaunching(_ notification: Notification) // macOS
```

function, configure the options you need:

```Swift
log.setup(level: .debug, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: "path/to/file", fileLevel: .debug)
```

The value for `writeToFile:` can be a `String` or `URL`. If the file already exists, it will be cleared before we use it. Omit the parameter or set it to `nil` to log to the console only. You can optionally set a different log level for the file output using the `fileLevel:` parameter. Set it to `nil` or omit it to use the same log level as the console.

Then, whenever you'd like to log something, use one of the convenience methods:

```Swift
log.verbose("A verbose message, usually useful when working on a specific problem")
log.debug("A debug message")
log.info("An info message, probably useful to power users looking in console.app")
log.notice("A notice message")
log.warning("A warning message, may indicate a possible error")
log.error("An error occurred, but it's recoverable, just info about what happened")
log.severe("A severe error occurred, we are likely about to crash now")
log.alert("An alert error occurred, a log destination could be made to email someone")
log.emergency("An emergency error occurred, a log destination could be made to text someone")
```

The different methods set the log level of the message. XCGLogger will only print messages with a log level that is greater to or equal to its current log level setting. So a logger with a level of `.error` will only output log messages with a level of `.error`, `.severe`, `.alert`, or `.emergency`.

## Advanced Usage (Recommended)

XCGLogger aims to be simple to use and get you up and running quickly with as few as 2 lines of code above. But it allows for much greater control and flexibility. 

A logger can be configured to deliver log messages to a variety of destinations. Using the basic setup above, the logger will output log messages to the standard Xcode debug console, and optionally a file if a path is provided. It's quite likely you'll want to send logs to more interesting places, such as the Apple System Console, a database, third party server, or another application such as [NSLogger][NSLogger]. This is accomplished by adding the destination to the logger.

Here's an example of configuring the logger to output to the Apple System Log as well as a file.

```Swift
// Create a logger object with no destinations
let log = XCGLogger(identifier: "advancedLogger", includeDefaultDestinations: false)

// Create a destination for the system console log (via NSLog)
let systemDestination = AppleSystemLogDestination(identifier: "advancedLogger.systemDestination")

// Optionally set some configuration options
systemDestination.outputLevel = .debug
systemDestination.showLogIdentifier = false
systemDestination.showFunctionName = true
systemDestination.showThreadName = true
systemDestination.showLevel = true
systemDestination.showFileName = true
systemDestination.showLineNumber = true
systemDestination.showDate = true

// Add the destination to the logger
log.add(destination: systemDestination)

// Create a file log destination
let fileDestination = FileDestination(writeToFile: "/path/to/file", identifier: "advancedLogger.fileDestination")

// Optionally set some configuration options
fileDestination.outputLevel = .debug
fileDestination.showLogIdentifier = false
fileDestination.showFunctionName = true
fileDestination.showThreadName = true
fileDestination.showLevel = true
fileDestination.showFileName = true
fileDestination.showLineNumber = true
fileDestination.showDate = true

// Process this destination in the background
fileDestination.logQueue = XCGLogger.logQueue

// Add the destination to the logger
log.add(destination: fileDestination)

// Add basic app info, version info etc, to the start of the logs
log.logAppDetails()
```

You can configure each log destination with different options depending on your needs.

Another common usage pattern is to have multiple loggers, perhaps one for UI issues, one for networking, and another for data issues.

Each log destination can have its own log level. As a convenience, you can set the log level on the log object itself and it will pass that level to each destination. Then set the destinations that need to be different.

**Note**: A destination object can only be added to one logger object, adding it to a second will remove it from the first.

### Initialization Using A Closure

Alternatively you can use a closure to initialize your global variable, so that all initialization is done in one place
```Swift
let log: XCGLogger = {
    let log = XCGLogger(identifier: "advancedLogger", includeDefaultDestinations: false)

	// Customize as needed
    
    return log
}()
```

**Note**: This creates the log object lazily, which means it's not created until it's actually needed. This delays the initial output of the app information details. Because of this, I recommend forcing the log object to be created at app launch by adding the line `let _ = log` at the top of your `didFinishLaunching` method if you don't already log something on app launch.

### Log Anything

You can log strings:

```Swift
log.debug("Hi there!")
```

or pretty much anything you want:

```Swift
log.debug(true)
log.debug(CGPoint(x: 1.1, y: 2.2))
log.debug(MyEnum.Option)
log.debug((4, 2))
log.debug(["Device": "iPhone", "Version": 7])
```

### Filtering Log Messages

New to XCGLogger 4, you can now create filters to apply to your logger (or to specific destinations). Create and configure your filters (examples below), and then add them to the logger or destination objects by setting the optional `filters` property to an array containing the filters. Filters are applied in the order they exist in the array. During processing, each filter is asked if the log message should be excluded from the log. If any filter excludes the log message, it's excluded. Filters have no way to reverse the exclusion of another filter.

If a destination's `filters` property is `nil`, the log's `filters` property is used instead. To have one destination log everything, while having all other destinations filter something, add the filters to the log object and set the one destination's `filters` property to an empty array `[]`. 

**Note**: Unlike destinations, you can add the same filter object to multiple loggers and/or multiple destinations.

#### Filter by Filename

To exclude all log messages from a specific file, create an exclusion filter like so:

```Swift
log.filters = [FileNameFilter(excludeFrom: ["AppDelegate.swift"], excludePathWhenMatching: true)]
```

`excludeFrom:` takes an `Array<String>` or `Set<String>` so you can specify multiple files at the same time.

`excludePathWhenMatching:` defaults to `true` so you can omit it unless you want to match path's as well.

To include log messages only for a specific set to files, create the filter using the `includeFrom:` initializer. It's also possible to just toggle the `inverse` property to flip the exclusion filter to an inclusion filter.
	
#### Filter by Tag

In order to filter log messages by tag, you must of course be able to set a tag on the log messages. Each log message can now have additional, user defined data attached to them, to be used by filters (and/or formatters etc). This is handled with a `userInfo: Dictionary<String, Any>` object. The dictionary key should be a namespaced string to avoid collisions with future additions. Official keys will begin with `com.cerebralgardens.xcglogger`. The tag key can be accessed by `XCGLogger.Constants.userInfoKeyTags`. You definitely don't want to be typing that, so feel free to create a global shortcut: `let tags = XCGLogger.Constants.userInfoKeyTags`. Now you can easily tag your logs:

```Swift
let sensitiveTag = "Sensitive"
log.debug("A tagged log message", userInfo: [tags: sensitiveTag])
```

The value for tags can be an `Array<String>`, `Set<String>`, or just a `String`, depending on your needs. They'll all work the same way when filtered.

Depending on your workflow and usage, you'll probably create faster methods to set up the `userInfo` dictionary. See [below](#mixing-and-matching) for other possible shortcuts.

Now that you have your logs tagged, you can filter easily:

```Swift
log.filters = [TagFilter(excludeFrom: [sensitiveTag])]
```

Just like the `FileNameFilter`, you can use `includeFrom:` or toggle `inverse` to include only log messages that have the specified tags.

#### Filter by Developer

Filtering by developer is exactly like filtering by tag, only using the `userInfo` key of `XCGLogger.Constants.userInfoKeyDevs`. In fact, both filters are subclasses of the `UserInfoFilter` class that you can use to create additional filters. See [Extending XCGLogger](#extending-xcglogger) below.

#### Mixing and Matching

In large projects with multiple developers, you'll probably want to start tagging log messages, as well as indicate the developer that added the message.

While extremely flexible, the `userInfo` dictionary can be a little cumbersome to use. There are a few possible methods you can use to simply things. I'm still testing these out myself so they're not officially part of the library yet (I'd love feedback or other suggestions).

I have created some experimental code to help create the UserInfo dictionaries. (Include the optional `UserInfoHelpers` subspec if using CocoaPods). Check the iOS Demo app to see it in use.

There are two structs that conform to the `UserInfoTaggingProtocol` protocol. `Tag` and `Dev`.

You can create an extension on each of these that suit your project. For example:

```Swift
extension Tag {
    static let sensitive = Tag("sensitive")
    static let ui = Tag("ui")
    static let data = Tag("data")
}

extension Dev {
    static let dave = Dev("dave")
    static let sabby = Dev("sabby")
}
```

Along with these types, there's an overloaded operator `|` that can be used to merge them together into a dictionary compatible with the `UserInfo:` parameter of the logging calls.

Then you can log messages like this:

```Swift
log.debug("A tagged log message", userInfo: Dev.dave | Tag.sensitive)
```

There are some current issues I see with these `UserInfoHelpers`, which is why I've made it optional/experimental for now. I'd love to hear comments/suggestions for improvements.

1. The overloaded operator `|` merges dictionaries so long as there are no `Set`s. If one of the dictionaries contains a `Set`, it'll use one of them, without merging them. Preferring the left hand side if both sides have a set for the same key.
2. Since the `userInfo:` parameter needs a dictionary, you can't pass in a single Dev or Tag object. You need to use at least two with the `|` operator to have it automatically convert to a compatible dictionary. If you only want one Tag for example, you must access the `.dictionary` parameter manually: `userInfo: Tag("Blah").dictionary`.

### Selectively Executing Code

All log methods operate on closures. Using the same syntactic sugar as Swift's `assert()` function, this approach ensures we don't waste resources building log messages that won't be output anyway, while at the same time preserving a clean call site.

For example, the following log statement won't waste resources if the debug log level is suppressed:

```Swift
log.debug("The description of \(thisObject) is really expensive to create")
```

Similarly, let's say you have to iterate through a loop in order to do some calculation before logging the result. In Objective-C, you could put that code block between `#if` `#endif`, and prevent the code from running. But in Swift, previously you would need to still process that loop, wasting resources. With `XCGLogger` it's as simple as:

```Swift
log.debug {
    var total = 0.0
    for receipt in receipts {
        total += receipt.total
    }

    return "Total of all receipts: \(total)"
}
```

In cases where you wish to selectively execute code without generating a log line, return `nil`, or use one of the methods: `verboseExec`, `debugExec`, `infoExec`, `warningExec`, `errorExec`, and `severeExec`.

### Custom Date Formats

You can create your own `DateFormatter` object and assign it to the logger.

```Swift
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "MM/dd/yyyy hh:mma"
dateFormatter.locale = Locale.current
log.dateFormatter = dateFormatter
```

### Enhancing Log Messages With Colour

XCGLogger supports adding formatting codes to your log messages to enable colour in various places. The original option was to use the [XcodeColors plug-in][XcodeColors]. However, Xcode (as of version 8) no longer officially supports plug-ins. You can still view your logs in colour, just not in Xcode at the moment. You can use the ANSI colour support to add colour to your fileDestination objects and view your logs via a terminal window. This gives you some extra options such as adding Bold, Italics, or (please don't) Blinking!

Once enabled, each log level can have its own colour. These colours can be customized as desired. If using multiple loggers, you could alternatively set each logger to its own colour.

An example of setting up the ANSI formatter:

```Swift
if let fileDestination: FileDestination = log.destination(withIdentifier: XCGLogger.Constants.fileDestinationIdentifier) as? FileDestination {
    let ansiColorLogFormatter: ANSIColorLogFormatter = ANSIColorLogFormatter()
    ansiColorLogFormatter.colorize(level: .verbose, with: .colorIndex(number: 244), options: [.faint])
    ansiColorLogFormatter.colorize(level: .debug, with: .black)
    ansiColorLogFormatter.colorize(level: .info, with: .blue, options: [.underline])
    ansiColorLogFormatter.colorize(level: .notice, with: .green, options: [.italic])
    ansiColorLogFormatter.colorize(level: .warning, with: .red, options: [.faint])
    ansiColorLogFormatter.colorize(level: .error, with: .red, options: [.bold])
    ansiColorLogFormatter.colorize(level: .severe, with: .white, on: .red)
    ansiColorLogFormatter.colorize(level: .alert, with: .white, on: .red, options: [.bold])
    ansiColorLogFormatter.colorize(level: .emergency, with: .white, on: .red, options: [.bold, .blink])
    fileDestination.formatters = [ansiColorLogFormatter]
}
```

As with filters, you can use the same formatter objects for multiple loggers and/or multiple destinations. If a destination's `formatters` property is `nil`, the logger's `formatters` property will be used instead.

See [Extending XCGLogger](#extending-xcglogger) below for info on creating your own custom formatters.

### Alternate Configurations

By using Swift build flags, different log levels can be used in debugging versus staging/production.
Go to Build Settings -> Swift Compiler - Custom Flags -> Other Swift Flags and add `-DDEBUG` to the Debug entry.

```Swift
#if DEBUG
    log.setup(level: .debug, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true)
#else
    log.setup(level: .severe, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true)
#endif
```

You can set any number of options up in a similar fashion. See the updated iOSDemo app for an example of using different log destinations based on options, search for `USE_NSLOG`.

### Background Log Processing

By default, the supplied log destinations will process the logs on the thread they're called on. This is to ensure the log message is displayed immediately when debugging an application. You can add a breakpoint immediately after a log call and see the results when the breakpoint hits.

However, if you're not actively debugging the application, processing the logs on the current thread can introduce a performance hit. You can now specify a destination process its logs on a dispatch queue of your choice (or even use a default supplied one).

```Swift
fileDestination.logQueue = XCGLogger.logQueue
```	

or even

```Swift
fileDestination.logQueue = DispatchQueue.global(qos: .background)
```

This works extremely well when combined with the [Alternate Configurations](#alternate-configurations) method above.

```Swift
#if DEBUG
    log.setup(level: .debug, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true)
#else
    log.setup(level: .severe, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true)
    if let consoleLog = log.logDestination(XCGLogger.Constants.baseConsoleDestinationIdentifier) as? ConsoleDestination {
        consoleLog.logQueue = XCGLogger.logQueue
    }
#endif
```

### Append To Existing Log File

When using the advanced configuration of the logger (see [Advanced Usage above](#advanced-usage-recommended)), you can now specify that the logger append to an existing log file, instead of automatically overwriting it.

Add the optional `shouldAppend:` parameter when initializing the `FileDestination` object. You can also add the `appendMarker:` parameter to add a marker to the log file indicating where a new instance of your app started appending. By default we'll add `-- ** ** ** --` if the parameter is omitted. Set it to `nil` to skip appending the marker.

```let fileDestination = FileDestination(writeToFile: "/path/to/file", identifier: "advancedLogger.fileDestination", shouldAppend: true, appendMarker: "-- Relauched App --")```


### Automatic Log File Rotation

When logging to a file, you have the option to automatically rotate the log file to an archived destination, and have the logger automatically create a new log file in place of the old one.

Create a destination using the `AutoRotatingFileDestination` class and set the following properties:

`targetMaxFileSize`: Auto rotate once the file is larger than this

`targetMaxTimeInterval`: Auto rotate after this many seconds

`targetMaxLogFiles`: Number of archived log files to keep, older ones are automatically deleted

Those are all guidelines for the logger, not hard limits.

### Extending XCGLogger

You can create alternate log destinations (besides the built in ones). Your custom log destination must implement the `DestinationProtocol` protocol. Instantiate your object, configure it, and then add it to the `XCGLogger` object with `add(destination:)`. There are two base destination classes (`BaseDestination` and `BaseQueuedDestination`) you can inherit from to handle most of the process for you, requiring you to only implement one additional method in your custom class. Take a look at `ConsoleDestination` and `FileDestination` for examples.

You can also create custom filters or formatters. Take a look at the provided versions as a starting point. Note that filters and formatters have the ability to alter the log messages as they're processed. This means you can create a filter that strips passwords, highlights specific words, encrypts messages, etc.

## Contributing

XCGLogger is the best logger available for Swift because of the contributions from the community like you. There are many ways you can help continue to make it great.

1. Star the project on [GitHub][github-xcglogger].
2. Report issues/bugs you find.
3. Suggest features.
4. Submit pull requests.
5. Download and install one of my apps: [https://www.cerebralgardens.com/apps/][cerebral-gardens-apps] Try my newest app: [All the Rings][all-the-rings].
6. You can visit my [Patreon][patreon-davewoodx] and contribute financially.

**Note**: when submitting a pull request, please use lots of small commits verses one huge commit. It makes it much easier to merge in when there are several pull requests that need to be combined for a new version.

<!-- Removed these since plug-ins seem to be gone for good now
## Third Party Tools That Work With XCGLogger

**Note**: These plug-ins no longer 'officially' work in Xcode. File a [bug report](https://openradar.appspot.com/27447585) if you'd like to see plug-ins return to Xcode.

[**XcodeColors:**][XcodeColors] Enable colour in the Xcode console
<br />
[**KZLinkedConsole:**][KZLinkedConsole] Link from a log line directly to the code that produced it

**Note**: These may not yet work with the Swift 4 version of XCGLogger.

[**XCGLoggerNSLoggerConnector:**][XCGLoggerNSLoggerConnector] Send your logs to [NSLogger][NSLogger]
-->

## To Do

- Add more examples of some advanced use cases
- Add additional log destination types
- Add Objective-C support
- Add Linux support

## More

If you find this library helpful, you'll definitely find this other tool helpful:

Watchdog: https://watchdogforxcode.com/

Also, please check out some of my other projects:

- All the Rings: [App Store](https://itunes.apple.com/app/all-the-rings/id1186956966?pt=17255&ct=github&mt=8&at=11lMGu)
- Rudoku: [App Store](https://itunes.apple.com/app/rudoku/id965105321?pt=17255&ct=github&mt=8&at=11lMGu)
- TV Tune Up: https://www.cerebralgardens.com/tvtuneup

### Change Log

The change log is now in its own file: [CHANGELOG.md](CHANGELOG.md)

[xcglogger-logo]: https://github.com/DaveWoodCom/XCGLogger/raw/master/ReadMeImages/XCGLoggerLogo_326x150.png
[swift.org]: https://swift.org/
[license]: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
[travis]: https://travis-ci.org/DaveWoodCom/XCGLogger
[swiftpm]: https://swift.org/package-manager/
[cocoapods]: https://cocoapods.org/
[cocoapods-xcglogger]: https://cocoapods.org/pods/XCGLogger
[carthage]: https://github.com/Carthage/Carthage
[cerebral-gardens]: https://www.cerebralgardens.com/
[cerebral-gardens-apps]: https://www.cerebralgardens.com/apps/
[all-the-rings]: https://alltherings.fit/?s=GH3
[mastodon-davewoodx]: https://mastodon.social/@davewoodx
[twitter-davewoodx]: https://twitter.com/davewoodx
[github-xcglogger]: https://github.com/DaveWoodCom/XCGLogger
[stackoverflow]: https://stackoverflow.com/questions/tagged/xcglogger
[patreon-davewoodx]: https://www.patreon.com/DaveWoodX

[badge-language]: https://img.shields.io/badge/Swift-1.x%20%7C%202.x%20%7C%203.x%20%7C%204.x%20%7C%205.x-orange.svg?style=flat
[badge-platforms]: https://img.shields.io/badge/Platforms-macOS%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS-lightgray.svg?style=flat
[badge-license]: https://img.shields.io/badge/License-MIT-lightgrey.svg?style=flat
[badge-travis]: https://img.shields.io/travis/DaveWoodCom/XCGLogger/master.svg?style=flat
[badge-swiftpm]: https://img.shields.io/badge/Swift_Package_Manager-v7.0.0-64a6dd.svg?style=flat
[badge-cocoapods]: https://img.shields.io/cocoapods/v/XCGLogger.svg?style=flat
[badge-carthage]: https://img.shields.io/badge/Carthage-v7.0.0-64a6dd.svg?style=flat

[badge-sponsors]: https://img.shields.io/badge/Sponsors-Cerebral%20Gardens-orange.svg?style=flat
[badge-mastodon]: https://img.shields.io/badge/Mastodon-DaveWoodX-606A84.svg?style=flat
[badge-twitter]: https://img.shields.io/twitter/follow/DaveWoodX.svg?style=social
[badge-patreon]: https://img.shields.io/badge/Patreon-DaveWoodX-F96854.svg?style=flat

[XcodeColors]: https://github.com/robbiehanson/XcodeColors
[KZLinkedConsole]: https://github.com/krzysztofzablocki/KZLinkedConsole
[NSLogger]: https://github.com/fpillet/NSLogger
[XCGLoggerNSLoggerConnector]: https://github.com/markuswinkler/XCGLoggerNSLoggerConnector
[Firelog]: http://jogabo.github.io/firelog/
[Firebase]: https://www.firebase.com/

[xcglogger-7.0.0]: https://github.com/DaveWoodCom/XCGLogger/releases/tag/7.0.0
[xcglogger-6.1.0]: https://github.com/DaveWoodCom/XCGLogger/releases/tag/6.1.0
[xcglogger-6.0.4]: https://github.com/DaveWoodCom/XCGLogger/releases/tag/6.0.4
[xcglogger-6.0.2]: https://github.com/DaveWoodCom/XCGLogger/releases/tag/6.0.2
[xcglogger-5.0.5]: https://github.com/DaveWoodCom/XCGLogger/releases/tag/5.0.5
[xcglogger-3.6.0]: https://github.com/DaveWoodCom/XCGLogger/releases/tag/3.6.0
[xcglogger-3.5.3]: https://github.com/DaveWoodCom/XCGLogger/releases/tag/3.5.3
[xcglogger-3.2]: https://github.com/DaveWoodCom/XCGLogger/releases/tag/3.2.0
[xcglogger-2.x]: https://github.com/DaveWoodCom/XCGLogger/releases/tag/2.4.0
[xcglogger-1.x]: https://github.com/DaveWoodCom/XCGLogger/releases/tag/1.8.1
