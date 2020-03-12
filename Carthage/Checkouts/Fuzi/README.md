# Fuzi (斧子)

[![Build Status](https://api.travis-ci.org/cezheng/Fuzi.svg)](https://travis-ci.org/cezheng/Fuzi)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Fuzi.svg)](https://cocoapods.org/pods/Fuzi)
[![License](https://img.shields.io/cocoapods/l/Fuzi.svg?style=flat&color=gray)](http://opensource.org/licenses/MIT)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/cocoapods/p/Fuzi.svg?style=flat)](http://cezheng.github.io/Fuzi/)
[![Twitter](https://img.shields.io/badge/twitter-@AdamoCheng-blue.svg?style=flat)](http://twitter.com/AdamoCheng)

**A fast & lightweight XML/HTML parser in Swift that makes your life easier.** [[Documentation]](http://cezheng.github.io/Fuzi/)

Fuzi is based on a Swift port of Mattt Thompson's [Ono](https://github.com/mattt/Ono)(斧), using most of its low level implementaions with moderate class & interface redesign following standard Swift conventions, along with several bug fixes.

> Fuzi(斧子) means "axe", in homage to [Ono](https://github.com/mattt/Ono)(斧), which in turn is inspired by [Nokogiri](http://nokogiri.org) (鋸), which means "saw".

[简体中文](README-zh.md)
[日本語](README-ja.md)
## A Quick Look
```swift
let xml = "..."
// or
// let xmlData = <some NSData or Data>
do {
  let document = try XMLDocument(string: xml)
  // or
  // let document = try XMLDocument(data: xmlData)
  
  if let root = document.root {
    // Accessing all child nodes of root element
    for element in root.children {
      print("\(element.tag): \(element.attributes)")
    }
    
    // Getting child element by tag & accessing attributes
    if let length = root.firstChild(tag:"Length", inNamespace: "dc") {
      print(length["unit"])     // `unit` attribute
      print(length.attributes)  // all attributes
    }
  }
  
  // XPath & CSS queries
  for element in document.xpath("//element") {
    print("\(element.tag): \(element.attributes)")
  }
  
  if let firstLink = document.firstChild(css: "a, link") {
    print(firstLink["href"])
  }
} catch let error {
  print(error)
}
```

## Features
### Inherited from Ono
- Extremely performant document parsing and traversal, powered by `libxml2`
- Support for both [XPath](http://en.wikipedia.org/wiki/XPath) and [CSS](http://en.wikipedia.org/wiki/Cascading_Style_Sheets) queries
- Automatic conversion of date and number values
- Correct, common-sense handling of XML namespaces for elements and attributes
- Ability to load HTML and XML documents from either `String` or `NSData` or `[CChar]`
- Comprehensive test suite
- Full documentation

### Improved in Fuzi
- Simple, modern API following standard Swift conventions, no more return types like `AnyObject!` that cause unnecessary type casts
- Customizable date and number formatters
- Some bugs fixes
- More convenience methods for HTML Documents
- Access XML nodes of all types (Including text, comment, etc.)
- Support for more CSS selectors (yet to come)


## Requirements

- iOS 8.0+ / Mac OS X 10.9+
- Xcode 8.0+

> Use version [0.4.0](../../releases/tag/0.4.0) for Swift 2.3.


## Installation

There are 4 ways you can install Fuzi to your project.

### Using [CocoaPods](http://cocoapods.org/)
You can use [CocoaPods](http://cocoapods.org/) to install `Fuzi` by adding it to your to your `Podfile`:

```ruby
platform :ios, '8.0'
use_frameworks!

target 'MyApp' do
	pod 'Fuzi', '~> 1.0.0'
end
```

Then, run the following command:

```bash
$ pod install
```

### Using Swift Package Manager
The Swift Package Manager is now built-in with Xcode 11 (currently in beta). You can easily add Fuzi as a dependency by choosing `File > Swift Packages > Add Package Dependency...` or in the Swift Packages tab of your project file and clicking on `+`.
Simply use `https://github.com/cezheng/Fuzi` as repository and Xcode should automatically resolve the current version.

### Manually
1. Add all `*.swift` files in `Fuzi` directory into your project.
2. In your Xcode project `Build Settings`:
   1. Find `Search Paths`, add `$(SDKROOT)/usr/include/libxml2` to `Header Search Paths`.
   2. Find `Linking`, add `-lxml2` to `Other Linker Flags`.

### Using [Carthage](https://github.com/Carthage/Carthage)
Create a `Cartfile` or `Cartfile.private` in the root directory of your project, and add the following line:

```
github "cezheng/Fuzi" ~> 1.0.0
```
Run the following command:

```
$ carthage update
```
Then do the followings in Xcode:

1. Drag the `Fuzi.framework` built by Carthage into your target's `General` -> `Embedded Binaries`.
2. In `Build Settings`, find `Search Paths`, add `$(SDKROOT)/usr/include/libxml2` to `Header Search Paths`.


## Usage
### XML
```swift
import Fuzi

let xml = "..."
do {
  // if encoding is omitted, it defaults to NSUTF8StringEncoding
  let document = try XMLDocument(string: html, encoding: String.Encoding.utf8)
  if let root = document.root {
    print(root.tag)
    
    // define a prefix for a namespace
    document.definePrefix("atom", defaultNamespace: "http://www.w3.org/2005/Atom")
    
    // get first child element with given tag in namespace(optional)
    print(root.firstChild(tag: "title", inNamespace: "atom"))

    // iterate through all children
    for element in root.children {
      print("\(index) \(element.tag): \(element.attributes)")
    }
  }
  // you can also use CSS selector against XMLDocument when you feels it makes sense
} catch let error as XMLError {
  switch error {
  case .noError: print("wth this should not appear")
  case .parserFailure, .invalidData: print(error)
  case .libXMLError(let code, let message):
    print("libxml error code: \(code), message: \(message)")
  }
}
```
### HTML
`HTMLDocument` is a subclass of `XMLDocument`.

```swift
import Fuzi

let html = "<html>...</html>"
do {
  // if encoding is omitted, it defaults to NSUTF8StringEncoding
  let doc = try HTMLDocument(string: html, encoding: String.Encoding.utf8)
  
  // CSS queries
  if let elementById = doc.firstChild(css: "#id") {
    print(elementById.stringValue)
  }
  for link in doc.css("a, link") {
      print(link.rawXML)
      print(link["href"])
  }
  
  // XPath queries
  if let firstAnchor = doc.firstChild(xpath: "//body/a") {
    print(firstAnchor["href"])
  }
  for script in doc.xpath("//head/script") {
    print(script["src"])
  }
  
  // Evaluate XPath functions
  if let result = doc.eval(xpath: "count(/*/a)") {
    print("anchor count : \(result.doubleValue)")
  }
  
  // Convenient HTML methods
  print(doc.title) // gets <title>'s innerHTML in <head>
  print(doc.head)  // gets <head> element
  print(doc.body)  // gets <body> element
  
} catch let error {
  print(error)
}
```

### I don't care about error handling

```swift
import Fuzi

let xml = "..."

// Don't show me the errors, just don't crash
if let doc1 = try? XMLDocument(string: xml) {
  //...
}

let html = "<html>...</html>"

// I'm sure this won't crash
let doc2 = try! HTMLDocument(string: html)
//...
```

### I want to access Text Nodes
Not only text nodes, you can specify what types of nodes you would like to access.

```swift
let document = ...
// Get all child nodes that are Element nodes, Text nodes, or Comment nodes
document.root?.childNodes(ofTypes: [.Element, .Text, .Comment])
```

## Migrating From Ono?
Looking at example programs is the swiftest way to know the difference. The following 2 examples do exactly the same thing.

[Ono Example](https://github.com/mattt/Ono/blob/master/Example/main.m)

[Fuzi Example](FuziDemo/FuziDemo/main.swift)

### Accessing children
**Ono**

```objc
[doc firstChildWithTag:tag inNamespace:namespace];
[doc firstChildWithXPath:xpath];
[doc firstChildWithXPath:css];
for (ONOXMLElement *element in parent.children) {
  //...
}
[doc childrenWithTag:tag inNamespace:namespace];
```
**Fuzi**

```swift
doc.firstChild(tag: tag, inNamespace: namespace)
doc.firstChild(xpath: xpath)
doc.firstChild(css: css)
for element in parent.children {
  //...
}
doc.children(tag: tag, inNamespace:namespace)
```
### Iterate through query results
**Ono**

Conforms to `NSFastEnumeration`.

```objc
// simply iterating through the results
// mark `__unused` to unused params `idx` and `stop`
[doc enumerateElementsWithXPath:xpath usingBlock:^(ONOXMLElement *element, __unused NSUInteger idx, __unused BOOL *stop) {
  NSLog(@"%@", element);
}];

// stop the iteration at second element
[doc enumerateElementsWithXPath:XPath usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
  *stop = (idx == 1);
}];

// getting element by index 
ONOXMLDocument *nthElement = [(NSEnumerator*)[doc CSS:css] allObjects][n];

// total element count
NSUInteger count = [(NSEnumerator*)[document XPath:xpath] allObjects].count;
```

**Fuzi**

Conforms to Swift's `SequenceType` and `Indexable`.

```swift
// simply iterating through the results
// no need to write the unused `idx` or `stop` params
for element in doc.xpath(xpath) {
  print(element)
}

// stop the iteration at second element
for (index, element) in doc.xpath(xpath).enumerate() {
  if idx == 1 {
    break
  }
}

// getting element by index 
if let nthElement = doc.css(css)[n] {
  //...
}

// total element count
let count = doc.xpath(xpath).count
```

### Evaluating XPath Functions
**Ono**

```objc
ONOXPathFunctionResult *result = [doc functionResultByEvaluatingXPath:xpath];
result.boolValue;    //BOOL
result.numericValue; //double
result.stringValue;  //NSString
```

**Fuzi**

```swift
if let result = doc.eval(xpath: xpath) {
  result.boolValue   //Bool
  result.doubleValue //Double
  result.stringValue //String
}
```

## License

`Fuzi` is released under the MIT license. See [LICENSE](LICENSE) for details.
