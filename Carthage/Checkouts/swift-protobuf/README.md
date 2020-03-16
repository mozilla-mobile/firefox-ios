<img src="https://swift.org/assets/images/swift.svg" alt="Swift logo" height="70" >

# Swift Protobuf

**Welcome to Swift Protobuf!**

[Apple's Swift programming language](https://swift.org/) is a perfect
complement to [Google's Protocol
Buffer](https://developers.google.com/protocol-buffers/) ("protobuf") serialization
technology.
They both emphasize high performance and programmer safety.

This project provides both the command-line program that adds Swift
code generation to Google's `protoc` and the runtime library that is
necessary for using the generated code.
After using the protoc plugin to generate Swift code from your .proto
files, you will need to add this library to your project.


# Features of SwiftProtobuf

SwiftProtobuf offers many advantages over alternative serialization
systems:

* Safety: The protobuf code-generation system avoids the
  errors that are common with hand-built serialization code.
* Correctness: SwiftProtobuf passes both its own extensive
  test suite and Google's full conformance test for protobuf
  correctness.
* Schema-driven: Defining your data structures in a separate
  `.proto` schema file clearly documents your communications
  conventions.
* Idiomatic: SwiftProtobuf takes full advantage of the Swift language.
  In particular, all generated types provide full Swift copy-on-write
  value semantics.
* Efficient binary serialization: The `.serializedData()`
  method returns a `Data` with a compact binary form of your data.
  You can deserialize the data using the `init(serializedData:)`
  initializer.
* Standard JSON serialization: The `.jsonUTF8Data()` method returns a JSON
  form of your data that can be parsed with the `init(jsonUTF8Data:)`
  initializer.
* Hashable, Equatable: The generated struct can be put into a
  `Set<>` or `Dictionary<>`.
* Performant: The binary and JSON serializers have been
  extensively optimized.
* Extensible: You can add your own Swift extensions to any
  of the generated types.

Best of all, you can take the same `.proto` file and generate
Java, C++, Python, or Objective-C for use on other platforms. The
generated code for those languages will use the exact same
serialization and deserialization conventions as SwiftProtobuf, making
it easy to exchange serialized data in binary or JSON forms, with no
additional effort on your part.

# Documentation

More information is available in the associated documentation:

 * [Google's protobuf documentation](https://developers.google.com/protocol-buffers/)
   provides general information about protocol buffers, the protoc compiler,
   and how to use protocol buffers with C++, Java, and other languages.
 * [PLUGIN.md](Documentation/PLUGIN.md) documents the `protoc-gen-swift`
   plugin that adds Swift support to the `protoc` program
 * [API.md](Documentation/API.md) documents how to use the generated code.
   This is recommended reading for anyone using SwiftProtobuf in their
   project.
 * [cocoadocs.org](http://cocoadocs.org/docsets/SwiftProtobuf/) has the generated
   API documentation
 * [INTERNALS.md](Documentation/INTERNALS.md) documents the internal structure
   of the generated code and the library.  This
   should only be needed by folks interested in working on SwiftProtobuf
   itself.
 * [STYLE_GUIDELINES.md](Documentation/STYLE_GUIDELINES.md) documents the style
   guidelines we have adopted in our codebase if you are interested in
   contributing

# Getting Started

If you've worked with Protocol Buffers before, adding Swift support is very
simple: you just need to build the `protoc-gen-swift` program and copy it into
your PATH.
The `protoc` program will find and use it automatically, allowing you
to build Swift sources for your proto files.
You will also, of course, need to add the SwiftProtobuf runtime library to
your project as explained below.

## System Requirements

To use Swift with Protocol buffers, you'll need:

* A Swift 4.0 or later compiler (Xcode 9.1 or later).  Support is included
for the Swift Package Manager; or using the included Xcode project. The Swift
protobuf project is being developed and tested against the latest release
version of Swift available from [Swift.org](https://swift.org)

* Google's protoc compiler.  The Swift protoc plugin is being actively
developed and tested against the latest protobuf sources.
The SwiftProtobuf tests need a version of protoc which supports the
`swift_prefix` option (introduced in protoc 3.2.0).
It may work with earlier versions of protoc.
You can get recent versions from
[Google's github repository](https://github.com/protocolbuffers/protobuf).

## Building and Installing the Code Generator Plugin

To translate `.proto` files into Swift, you will need both Google's
protoc compiler and the SwiftProtobuf code generator plugin.

Building the plugin should be simple on any supported Swift platform:

```
$ git clone https://github.com/apple/swift-protobuf.git
$ cd swift-protobuf
```

Pick what released version of SwiftProtobuf you are going to use.  You can get
a list of tags with:

```
$ git tag -l
```

Once you pick the version you will use, set your local state to match, and
build the protoc plugin:

```
$ git checkout tags/[tag_name]
$ swift build -c release
```

This will create a binary called `protoc-gen-swift` in the `.build/release`
directory.

To install, just copy this one executable into a directory that is
part of your `PATH` environment variable.

NOTE: The Swift runtime support is now included with macOS. If you are
using old Xcode versions or are on older system versions, you might need
to use also use `--static-swift-stdlib` with `swift build`.

### Alternatively install via Homebrew

If you prefer using [Homebrew](https://brew.sh):

```
$ brew install swift-protobuf
```

This will install `protoc` compiler and Swift code generator plugin.

## Converting .proto files into Swift

To generate Swift output for your .proto files, you run the `protoc` command as
usual, using the `--swift_out=<directory>` option:

```
$ protoc --swift_out=. my.proto
```

The `protoc` program will automatically look for `protoc-gen-swift` in your
`PATH` and use it.

Each `.proto` input file will get translated to a corresponding `.pb.swift`
file in the output directory.

More information about building and using `protoc-gen-swift` can be found
in the [detailed Plugin documentation](Documentation/PLUGIN.md).

## Adding the SwiftProtobuf library to your project...

To use the generated code, you need to include the `SwiftProtobuf` library
module in your project.  How you do this will vary depending on how
you're building your project.  Note that in all cases, we strongly recommend
that you use the version of the SwiftProtobuf library that corresponds to
the version of `protoc-gen-swift` you used to generate the code.

### ...using `swift build`

After copying the `.pb.swift` files into your project, you will need to add the
[SwiftProtobuf library](https://github.com/apple/swift-protobuf) to your
project to support the generated code.
If you are using the Swift Package Manager, add a dependency to your
`Package.swift` file and import the `SwiftProtobuf` library into the desired
targets.  Adjust the `"1.6.0"` here to match the `[tag_name]` you used to build
the plugin above:

```swift
dependencies: [
    .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.6.0"),
],
targets: [
    .target(name: "MyTarget", dependencies: ["SwiftProtobuf"]),
]
```

### ...using Xcode

If you are using Xcode, then you should:

* Add the `.pb.swift` source files generated from your protos directly to your
  project
* Add the appropriate `SwiftProtobuf_<platform>` target from the Xcode project
  in this package to your project.

### ...using CocoaPods

If you're using CocoaPods, add this to your `Podfile` adjusting the `:tag` to
match the `[tag_name]` you used to build the plugin above:

```ruby
pod 'SwiftProtobuf', '~> 1.0'
```

And run `pod install`.

NOTE: CocoaPods 1.7 or newer is required.

### ...using Carthage

If you're using Carthage, add this to your `Cartfile` but adjust the tag to match the `[tag_name]` you used to build the plugin above:

```ruby
github "apple/swift-protobuf" ~> 1.0
```

Run `carthage update` and drag `SwiftProtobuf.framework` into your Xcode.project.

# Quick Start

Once you have installed the code generator, used it to
generate Swift code from your `.proto` file, and
added the SwiftProtobuf library to your project, you can
just use the generated types as you would any other Swift
struct.

For example, you might start with the following very simple
proto file:
```protobuf
syntax = "proto3";

message BookInfo {
   int64 id = 1;
   string title = 2;
   string author = 3;
}
```

Then generate Swift code using:
```
$ protoc --swift_out=. DataModel.proto
```

The generated code will expose a Swift property for
each of the proto fields as well as a selection
of serialization and deserialization capabilities:
```swift
// Create a BookInfo object and populate it:
var info = BookInfo()
info.id = 1734
info.title = "Really Interesting Book"
info.author = "Jane Smith"

// As above, but generating a read-only value:
let info2 = BookInfo.with {
    $0.id = 1735
    $0.title = "Even More Interesting"
    $0.author = "Jane Q. Smith"
  }

// Serialize to binary protobuf format:
let binaryData: Data = try info.serializedData()

// Deserialize a received Data object from `binaryData`
let decodedInfo = try BookInfo(serializedData: binaryData)

// Serialize to JSON format as a Data object
let jsonData: Data = try info.jsonUTF8Data()

// Deserialize from JSON format from `jsonData`
let receivedFromJSON = try BookInfo(jsonUTF8Data: jsonData)
```

You can find more information in the detailed
[API Documentation](Documentation/API.md).

## Report any issues

If you run into problems, please send us a detailed report.
At a minimum, please include:

* The specific operating system and version (for example, "macOS 10.12.1" or
  "Ubuntu 16.10")
* The version of Swift you have installed (from `swift --version`)
* The version of the protoc compiler you are working with from
  `protoc --version`
* The specific version of this source code (you can use `git log -1` to get the
  latest commit ID)
* Any local changes you may have
