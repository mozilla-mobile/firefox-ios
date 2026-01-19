# CopyWithChanges

Allows copying a Swift class or struct while changing arbitrary fields.

## Overview

The `@CopyWithChanges` macro can be applied to a struct or a class to generate a function that takes facultative arguments, one for each of the target's fields, and returns a new instance that is a copy of the original, except for the provided arguments. It supports optionals.

## Rationale

Every so often, there is a need for a copy of a struct, but with differences in one or more fields. The correct way to do it is to invoke `init` with the intended values for each field, but that's unwieldy. What often happens is that the fields that have to be changed are made mutable, an assignment copy is made, and the change is made after the copy:

```swift
// original
let s1 = LargeStruct(a: 5, b: 2, c: 3, d: 7, e: 4, f: 1, g: 6)

// cumbersome copy changing b to 2
let s2 = LargeStruct(a: s1.a, b: 2, c: s1.c, d: s1.d, e: s1.e, f: s1.f, g: s1.g)

// reasonably simple copy + change, but requires that s3 AND b be mutable even if neither is changed outside this context
var s3 = s1
s3.b = 2
```

Making the instance mutable is a small trade-off, that can even be solved by using some variant of an initialisation block. However, making the **fields** mutable just for the sake of convenient initialisation can be seen as a big anti-pattern.

To avoid this need to make the fields mutable, `@CopyWithChanges` provides the boilerplate needed in the form of `func with(...)`, that handles the boilerplate of calling `init` with both the changed and the kept values:

```swift
// the solution proposed here
let s4 = s1.with(b: 2)

// the same, but changing two fields
let s5 = s1.with(c: 4, g: 7)

// will change f to nil (if field f is defined as Optional)
let s6 = s1.with(f: nil)
```

The complete behavior is:
- providing a value for any field will use that value for the field;
- providing `nil` for a field that is non-optional is the same as not including that field in the call, i.e. the value from the originalk struct will be used;
- providing `nil` for an optional field will make that field `nil`;
- providing `.some(nil)` for an optional field is the same as not including that field in the call, i.e. the value from the originalk struct will be used.

The macro can also apply to classes. In either classes or structs, there will have to be a memberwise `init`. In structs this is automatically synthesised by the compiler unless a custom init is defined in the struct declaration. It can also be generated via Xcode's autocompletion features.

## Usage

Annotate the target type with the `@CopyWithChanges` macro to generate `func with(...) -> Self`:

```swift
import CopyWithChanges

@CopyWithChanges
struct Report {
    let venue: String
    let sponsor: String?
    let drinks: [String]
    let complexStructure: [Date: [(String, Int)]]
    let characters: [String]?
    let budget: Double
}
```

The code after expansion:

```swift
struct Report {
    let venue: String
    let sponsor: String?
    let drinks: [String]
    let complexStructure: [Date: [(String, Int)]]
    let characters: [String]?
    let budget: Double

    public func with(venue: String? = nil, sponsor: String?? = .some(nil), drinks: [String]? = nil, complexStructure: [Date: [(String, Int)]]? = nil, characters: [String]?? = .some(nil), budget: Double? = nil) -> Self {
        Self (
            venue: venue ?? self.venue,
            sponsor: sponsor == .none ? nil : self.sponsor,
            drinks: drinks ?? self.drinks,
            complexStructure: complexStructure ?? self.complexStructure,
            characters: characters == .none ? nil : self.characters,
            budget: budget ?? self.budget
        )
    }
}
```

## Installation

<summary><h3>Swift Package Manager</h3></summary>

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler.

Once you have your Swift package set up, adding `CopyWithChanges` as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
.package(url: "https://github.com/entonio/CopyWithChanges/tree/main", from: "1.1.0"),
```

Then you can add the `CopyWithChanges` module product as dependency to the `target`s of your choosing, by adding it to the `dependencies` value of your `target`s.

```swift
.product(name: "CopyWithChanges", package: "CopyWithChanges"),
```

## License

All the files in this package are copyright of the package contributors mentioned in the [NOTICE](NOTICE) file and licensed under the [Apache 2.0 License](http://www.apache.org/licenses/LICENSE-2.0), which is permissive for business use.
