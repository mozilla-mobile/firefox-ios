# SWXMLHash

[![CocoaPods](https://img.shields.io/cocoapods/p/SWXMLHash.svg)]()
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods](https://img.shields.io/cocoapods/v/SWXMLHash.svg)](https://cocoapods.org/pods/SWXMLHash)
[![Join the chat at https://gitter.im/drmohundro/SWXMLHash](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/drmohundro/SWXMLHash?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

SWXMLHash is a relatively simple way to parse XML in Swift. If you're familiar with `NSXMLParser`, this library is a simple wrapper around it. Conceptually, it provides a translation from XML to a dictionary of arrays (aka hash).

The API takes a lot of inspiration from [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON).

## Contents

* [Requirements](#requirements)
* [Installation](#installation)
* [Getting Started](#getting-started)
* [Configuration](#configuration)
* [Examples](#examples)
* [Changelog](#changelog)
* [Contributing](#contributing)
* [License](#license)

## Requirements

- iOS 8.0+ / Mac OS X 10.9+ / tvOS 9.0+ / watchOS 2.0+
- Xcode 7.1+

## Installation

SWXMLHash can be installed using [CocoaPods](http://cocoapods.org/), [Carthage](https://github.com/Carthage/Carthage), or manually.

### CocoaPods

To install CocoaPods, run:

```bash
$ gem install cocoapods
```

Then create a `Podfile` with the following contents:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'

pod 'SWXMLHash', '~> 2.0.0'
```

Finally, run the following command to install it:

```bash
$ pod install
```

### Carthage

To install Carthage, run (using Homebrew):

```bash
$ brew update
$ brew install carthage
```

Then add the following line to your `Cartfile`:

```
github "drmohundro/SWXMLHash" ~> 2.0
```

### Manual Installation

To install manually, you'll need to clone the SWXMLHash repository. You can do this in a separate directory or you can make use of git submodules - in this case, git submodules are recommended so that your repository has details about which commit of SWXMLHash you're using. Once this is done, you can just drop the `SWXMLHash.swift` file into your project.

> NOTE: if you're targeting iOS 7, you'll have to install manually because embedded frameworks require a minimum deployment target of iOS 8 or OSX Mavericks.

## Getting Started

If you're just getting started with SWXMLHash, I'd recommend cloning the repository down and opening the workspace. I've included a Swift playground in the workspace which makes it *very* easy to experiment with the API and the calls.

<img src="https://raw.githubusercontent.com/drmohundro/SWXMLHash/assets/swift-playground@2x.png" width="600" alt="Swift Playground" />

## Configuration

SWXMLHash allows for limited configuration in terms of its approach to parsing. To set any of the configuration options, you use the `configure` method, like so:

```swift
let xml = SWXMLHash.config {
              config in
              // set any config options here
          }.parse(xmlToParse)
```

The available options at this time are:

* `shouldProcessLazily`
    * This determines whether not to use lazy loading of the XML. It can significantly increase the performance of parsing if your XML is very large.
    * Defaults to `false`
* `shouldProcessNamespaces`
    * This setting is forwarded on to the internal `NSXMLParser` instance. It will return any XML elements without their namespace parts (i.e. "\<h:table\>" will be returned as "\<table\>")
    * Defaults to `false`

## Examples

All examples below can be found in the included [specs](https://github.com/drmohundro/SWXMLHash/blob/master/Tests/SWXMLHashSpecs.swift).

### Initialization

```swift
let xml = SWXMLHash.parse(xmlToParse)
```

Alternatively, if you're parsing a large XML file and need the best performance, you may wish to configure the parsing to be processed lazily. Lazy processing avoids loading the entire XML document into memory, so it could be preferable for performance reasons. See the error handling for one caveat regarding lazy loading.

```swift
let xml = SWXMLHash.config {
              config in
              config.shouldProcessLazily = true
          }.parse(xmlToParse)
```

The above approach uses the new config method, but there is also a `lazy` method directly off of `SWXMLHash`.

```swift
let xml = SWXMLHash.lazy(xmlToParse)
```

### Single Element Lookup

Given:

```xml
<root>
  <header>
    <title>Foo</title>
  </header>
  ...
</root>
```

Will return "Foo".

```swift
xml["root"]["header"]["title"].element?.text
```

### Multiple Elements Lookup

Given:

```xml
<root>
  ...
  <catalog>
    <book><author>Bob</author></book>
    <book><author>John</author></book>
    <book><author>Mark</author></book>
  </catalog>
  ...
</root>
```

The below will return "John".

```swift
xml["root"]["catalog"]["book"][1]["author"].element?.text
```

### Attributes Usage

Given:

```xml
<root>
  ...
  <catalog>
    <book id="1"><author>Bob</author></book>
    <book id="123"><author>John</author></book>
    <book id="456"><author>Mark</author></book>
  </catalog>
  ...
</root>
```

The below will return "123".

```swift
xml["root"]["catalog"]["book"][1].element?.attributes["id"]
```

Alternatively, you can look up an element with specific attributes. The below will return "John".

```swift
xml["root"]["catalog"]["book"].withAttr("id", "123")["author"].element?.text
```

### Returning All Elements At Current Level

Given:

```xml
<root>
  ...
  <catalog>
    <book><genre>Fiction</genre></book>
    <book><genre>Non-fiction</genre></book>
    <book><genre>Technical</genre></book>
  </catalog>
  ...
</root>
```

The below will return "Fiction, Non-fiction, Technical" (note the `all` method).

```swift
", ".join(xml["root"]["catalog"]["book"].all.map { elem in
  elem["genre"].element!.text!
})
```

Alternatively, you can just iterate over the elements using `for-in` directly against an element.

```swift
for elem in xml["root"]["catalog"]["book"] {
  NSLog(elem["genre"].element!.text!)
}
```

### Returning All Child Elements At Current Level

Given:

```xml
<root>
  <catalog>
    <book>
      <genre>Fiction</genre>
      <title>Book</title>
      <date>1/1/2015</date>
    </book>
  </catalog>
</root>
```

The below will `NSLog` "root", "catalog", "book", "genre", "title", and "date" (note the `children` method).

```swift
func enumerate(indexer: XMLIndexer) {
  for child in indexer.children {
    NSLog(child.element!.name)
    enumerate(child)
  }
}

enumerate(xml)
```

### Error Handling

Using Swift 2.0's new error handling feature:

```swift
do {
  try xml!.byKey("root").byKey("what").byKey("header").byKey("foo")
} catch let error as XMLIndexer.Error {
  // error is an XMLIndexer.Error instance that you can deal with
}
```

__Or__ using the existing indexing functionality (__NOTE__ that the `.Error` case has been renamed to `.XMLError` so as to not conflict with the `XMLIndexer.Error` error type):

```swift
switch xml["root"]["what"]["header"]["foo"] {
case .Element(let elem):
  // everything is good, code away!
case .XMLError(let error):
  // error is an XMLIndexer.Error instance that you can deal with
}
```

Note that error handling as shown above will not work with lazy loaded XML. The lazy parsing doesn't actually occur until the `element` or `all` method are called - as a result, there isn't any way to know prior to asking for an element if it exists or not.

## Changelog

See [CHANGELOG](CHANGELOG.md) for a list of all changes and their corresponding versions.

## Contributing

This framework uses [Quick](https://github.com/Quick/Quick) and [Nimble](https://github.com/Quick/Nimble) for its tests. To get these dependencies, you'll need to have [Carthage](https://github.com/Carthage/Carthage) installed. Once it is installed, you should be able to just run `carthage update`.

To run the tests, you can either run them from within Xcode or you can run `rake test`.

The code loosely follows GitHub's [Swift Styleguide](https://github.com/github/swift-style-guide). The line length recommendations aren't strictly followed and the codebase is currently using spaces over tabs. I'm using [SwiftLint](https://github.com/realm/SwiftLint) to catch issues with style.

## License

SWXMLHash is released under the MIT license. See [LICENSE](LICENSE) for details.
