[![Build Status](https://travis-ci.org/mozilla-mobile/telemetry-ios.svg?branch=master)](https://travis-ci.org/mozilla-mobile/telemetry-ios)

telemetry-ios
=============

A generic library for sending telemetry pings from iOS applications to Mozilla's telemetry service.

## Motivation

The goal of this library is to provide a generic set of components to support a variety of telemetry use cases. It tries to not be opinionated about frameworks or HTTP clients. The only dependency is [AliSoftware/OHHTTPStubs](https://github.com/AliSoftware/OHHTTPStubs) for supporting tests.

## Usage

In your application's `AppDelegate`, setup your configuration options:

```swift
let configuration = Telemetry.default.configuration
configuration.appName = "My App"
configuration.appVersion = "1.0"
configuration.updateChannel = "release"
configuration.buildId = "1"
...
```

This library can automatically measure user preferences stored with `NSUserDefaults` for certain ping types. To do this, specify the `NSUserDefaults` key and a default value in the configuration:

```swift
configuration.measureUserDefaultsSetting(forKey: "foo", withDefaultValue: true)
configuration.measureUserDefaultsSetting(forKey: "bar", withDefaultValue: false)
```

The `AppDelegate` is also a good place to add a `TelemetryPingBuilder` for each type of ping you plan on using. This library includes two by default: `CorePingBuilder` and `FocusEventPingBuilder`. Additional ping types can be added by extending the base `TelemetryPingBuilder` class. Simply add the classes for the ping builder types you intend to use:

```swift
Telemetry.default.add(pingBuilderType: CorePingBuilder.self)
Telemetry.default.add(pingBuilderType: FocusEventPingBuilder.self)
```

How you record data in your application depends largely on the ping builder types you are using. For convenience, several methods are accessible right off the root `Telemetry` class for interfacing with the built-in ping builder types.

* Ensure your ping builders are registered before the UIApplication `appDidBecomeActive`, as the library uses that event to trigger the start of recording.
* `recordEvent(_ event: TelemetryEvent)` -- Adds a UI event to be batched and sent for `FocusEventPingBuilder`. There are also several convenience methods for constructing a `TelemetryEvent` and recording it at the same time such as `recordEvent(category: String, method: String, object: String, value: String?, extras: [String : Any?]?)` where `value` and `extras` are both optional.
* `recordSearch(location: SearchesMeasurement.SearchLocation, searchEngine: String)` -- Records that a search was performed for `CorePingBuilder`.

After recording data, it is stored locally in `FileManager.SearchPathDirectory.cachesDirectory` by default. 

When the app is backgrounded, one or more backgroundTasks are started to perform uploading.

### Customizing Ping Data

To modify the final key-value data dict before it gets stored as JSON, install a handler using Telemetry.swift:
`beforeSerializePing(pingType: String, handler: @escaping BeforeSerializePingHandler)`

## Getting involved

We encourage you to participate in this open source project. We love Pull Requests, Bug Reports, ideas, (security) code reviews or any kind of positive contribution. Please read the [Community Participation Guidelines](https://www.mozilla.org/en-US/about/governance/policies/participation/).

* Issues: [https://github.com/mozilla-mobile/telemetry-ios/issues](https://github.com/mozilla-mobile/telemetry-ios/issues)

* IRC: [#mobile (irc.mozilla.org)](https://wiki.mozilla.org/IRC)

* Mailing list: [mobile-firefox-dev](https://mail.mozilla.org/listinfo/mobile-firefox-dev)

## License

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/
