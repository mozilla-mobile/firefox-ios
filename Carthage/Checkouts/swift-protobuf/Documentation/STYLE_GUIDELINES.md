# Style Guidelines

If you're interested in contributing to the Swift Protobuf project, welcome!
Please make sure that your APIs are named and code is formatted according to
these guidelines so that we can ensure a consistent look-and-feel across the
entire codebase.

The following guidelines are non-exhaustive.

## Formatting

* Indentation: 2 spaces (do not use tabs)
* Line length: 80 characters

When in doubt about how to format a particularly tricky construct (such as
a method with a large number of generic types and/or arguments), we suggest
two pieces of advice:

1. Look to the
   [Swift standard library](https://github.com/apple/swift/tree/master/stdlib/public/core)
   for guidance.
1. Don't fight Xcode's auto-indenting unless doing so would make the
   formatting look horrible. Xcode has some baked-in assumptions about how
   Swift code should be formatted and fighting it will make your life harder
   and the lives of anyone who has to update that code in the future.

## File organization

* For the most part, each Swift source file should contain only one type, and
  the name of the file should match that of the type (for example, `Foo.swift`
  would contain a type named `Foo`).
  * In some cases, however, many small related types may be combined into a
    single .swift file for convenience. In that case, name the file based on a
    plural noun that describes the grouping. For example, the
    `ProtobufBinaryTypes.swift` file contains multiple small related types.
* Source files that primarily contain an extension that adds protocol
  conformance to a type should be named `Type+Protocol.swift` so the content
  and purpose of the file is easily glanceable based on the name and so that it
  is easy to find the source file where a particular concept is implemented.
  * Mirroring the multiple-types-in-one-file discussed above, a file that adds
    protocol conformance to several related types could be named based on the
    plural name of that file, plus the protocol name: `Types+Protocol.swift`.

## Documentation

* All public APIs should have documentation comments. Use `- Parameter foo:`
  and `- Returns:` tags when the meanings of parameters and return values are
  not obvious from the other documentation. Use `- Throws:` tags to describe
  which errors are thrown and under which circumstances.
* Internal/private APIs should also be documented unless it is unambiguously
  clear from its name and signature what it does.

## API naming conventions

The official
[Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
are a good source of wisdom when designing a new API.

Some points of emphasis:

* Method and property names should make use sites form grammatical English
  sentences. For example,
  * Methods without side-effects (i.e., which return something) should be named
    with a noun or noun phrase; for example, `serializedSize()`.
  * Methods with side-effects that return `Void` should be named with
    imperative verbs or verb phrases; for example, `encode(value:)`.
  * Non-Boolean properties should be named with nouns or noun phrases: `color`,
    `encodedSize`, etc.
  * Boolean properties should be named as assertions; adjectival phrases
    preceded by the word `is`, such as `isEmpty`, or indicative verb phrases
    such as `intersects`.
* Protocols that describe what something *is* should be named as nouns, like
  `Collection`.
* Protocols that describe what something is *capable of* should be named with
  gerunds (`Encoding`) or -able/-ible adjectives (`Encodable`).

## Future directions

At the time of this writing, some of the code in this project does not conform
to these guidelines (as it was written before the guidelines were adopted). As
changes are made, old code will be opportunistically brought in line with these
guidelines.

Eventually, it is our hope that the `swift-format` tool that is in Swift's
master branch will be made generally available with a future release of Xcode
or in some other form that is easy for end-users to adopt.
