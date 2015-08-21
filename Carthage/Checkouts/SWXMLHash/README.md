# SWXMLHash

SWXMLHash is a relatively simple way to parse XML in Swift. If you're familiar with `NSXMLParser`, this library is a simple wrapper around it. Conceptually, it provides a translation from XML to a dictionary of arrays (aka hash).

The API takes a lot of inspiration from [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON).

## Installation

The recommended means of installing SWXMLHash is using [CocoaPods](http://cocoapods.org/). As of CocoaPods 0.36 beta, Swift projects are supported.

To install the beta of CocoaPods, run:

```bash
$ gem install cocoapods --pre
```

Then create a `Podfile` with the following contents:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'

pod 'SWXMLHash', '~> 0.6.0'
```

Finally, run the following command to install it:

```bash
$ pod install
```

## Getting Started

If you're just getting started with SWXMLHash, I'd recommend cloning the repository down and opening the workspace. I've included a Swift playground in the workspace which makes it *very* easy to experiment with the API and the calls.

<img src="https://raw.githubusercontent.com/drmohundro/SWXMLHash/assets/swift-playground@2x.png" width="600" alt="Swift Playground" />

## Examples

All examples below can be found in the included specs.

### Initialization

```swift
let xml = SWXMLHash.parse(xmlToParse)
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

```swift
switch xml["root"]["what"]["header"]["foo"] {
case .Element(let elem):
  // everything is good, code away!
case .Error(let error):
  // error is an NSError instance that you can deal with
}
```

## TODO

* [x] finish implementing error handling for group indexing
* [x] add attribute support
* [x] maybe add attribute look-up for elements as opposed to solely array indexing
* [x] add CocoaPods support once it supports Swift projects
* [ ] more???

## License

SWXMLHash is released under the MIT license. See [LICENSE](LICENSE) for details.
