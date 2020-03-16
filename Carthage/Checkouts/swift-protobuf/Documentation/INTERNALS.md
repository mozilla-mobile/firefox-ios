# Swift Protobuf Internals

---

This explanation of the generated code is intended to help people understand
the internal design of SwiftProtobuf.
In particular, people interested in helping with the development of
SwiftProtobuf itself should probably read this carefully.

Note, however, that this is not a contract:
The details of the generated code are expected to change
over time as we discover better ways to implement the expected
behaviors.
As a result, this document is probably already out of date;
pull requests that correct this document to better match the actual
behavior are always appreciated.

## Swift Language Support

The goal is to always support "one full major version”, which basically
means if the current official release of Swift is `X.Y`, the library will
support back to `X-1.Y`.  That is, when Swift 4.2 was released, the minimum
for support got moved up to 3.2.

NOTE: While things like Swift 4.1 existed from a packaging/install pov,
`swiftc` does not support `4.1` as a value for `-swift-version`, so the minimum
can't be made to something like _4.1_ because that can't be targeted. So when
the minimum would move to a version like that, it instead says on the previous
minimum that was targetable (4.0 in the 4.1 case).

When the minimum Swift version gets updated, update:
- The `README.md` in the root of the project
- Audit all the `#if` directives in the code and tests that use at
  `swift(...)` to check the version being compiled against, and
  remove the ones that are no longer needed.
- Update `Package.swift` and `SwiftProtobuf.podspec` files to list the
  versions supported. Eventually the version specific `Package@*.swift`
  files will go away.

## Field Storage

The generated message structs follow one of several different patterns
regarding how they store their fields.

### Basic Templates

**Simple proto3 fields:**
The simplest pattern is for small proto3 messages that have only basic
field types.
For example, consider the following:

```protobuf
syntax = "proto3";
message Foo {
   int32 field1 = 1;
   string field2 = 2;
}
```

For these, we can generate a simple struct with the expected public properties
and simple initializers:

```swift
struct Foo {
   public var field1: Int32 = 0
   public var field2: String = ""
   // Other stuff...
}
```

**Simple proto2 optionals:**
We need a more complex template for proto2 optional fields with basic
field types.
Consider the proto2 analog of the previous example:

```protobuf
syntax = "proto2";
message Foo {
   optional int32 field1 = 1;
   optional string field2 = 2;
}
```

In this case, we generate fields that use Swift optionals internally (to track
whether the field was set on the message) but expose a non-optional
value for the field and a separate `hasXyz` property that can be used to
test whether the field was set:

```swift
struct Foo {
   private var _field1: Int32? = nil
   var field1: Int32 {
     get {return _field1 ?? 0}
     set {_field1 = newValue}
   }
   var hasField1: Bool {return _field1 != nil}
   mutating func clearField1() {_field1 = nil}

   private var _field2: String? = nil
   var field2: String {
     get {return _field1 ?? ""}
     set {_field1 = newValue}
   }
   var hasField2: Bool {return _field2 != nil}
   mutating func clearField2() {_field2 = nil}
}
```

If explicit defaults were set on the fields in the proto, the generated code
is essentially the same; it just uses different default values in
the generated getters.
The `clearXyz` methods above ensure that users can always reset a field
to the default value without needing to know what the default value is.

**Proto2 optional vs. Swift Optional**

The original implementation of Swift Protobuf handled proto2 optional
fields by generating properties with Swift `Optional<>` type.
Although the common name makes this approach obvious (which is no doubt
why it keeps getting suggested), experience with that first
implementation prompted us to change it to have separate
explicit `has` properties and `clear` methods for each field instead.

To understand why, it might help to first think about why proto2 and
proto3 each sometimes omit fields from the encoded data.
Proto3 has the simplest model; it omits fields as a form of compression.
In particular, proto3 fields always have a value (they are never "not set"),
we just sometimes save a few bytes by not transferring that value.

Proto2 is only slightly different.
Like proto3, proto2 fields also always have a value.
Unlike proto3, however, proto2 keeps track of whether the current
value was explicitly set or not.
If it was not explicitly given a value, then proto2 doesn't transfer it.
Note that the presence or absence of a field in the encoded data
only indicates whether the field value was explicitly set;
the field itself still always has a value.

This is fundamentally different than Swift Optionals.
A Swift Optional is "nullable"; it can explicitly represent
the absence of a value.
Proto2 optional fields are not nullable; they always have a value.
This is a subtle but important difference between the two.

Usually, the current form seems to noticeably simplify the usage:
Most of the time, you just want to use whatever value is there,
relying on the default when no value was set explicitly.
Sometimes, you may need to verify that the other side
explicitly provided the values you expect.
In these cases, it is generally easier to assert
that the received object `has` the expected fields
in just one place, then use the current values throughout,
than to test and unwrap Swift Optionals at every access.

**Proto2 required fields:**

Required fields generate the same storage and field management
as for optional fields.

But the code generator augments this with a generated `isInitialized`
method that simply tests each required field to ensure it has
a suitable value.
Note that this is done for proto3 messages as well if there are
fields that store proto2 messages.

Since the code generator has the entire schema available at once it
can generally inspect the entire schema and short-circuit the
`isInitialized` check entirely in cases where no sub-object has any
required fields.
This means that required field support does not incur any cost unless
there actually are some required fields.

(Extensions complicate this picture:
Since extensions may be compiled separately, the `isInitialized`
check must always visit any extensible messages in case one of
their extensions has required fields.)

The generated `isInitialized` property is used in the following cases:

* When initializing an `Any` field
* Just before serializing to binary format
* Just after decoding from binary format

Each of these APIs supports a `partial` parameter; setting this
parameter to `true` will suppress the check, allowing you to encode or
decode a partial object that may be lacking required fields.

**Proto2 and proto3 repeated and map fields:**

Repeated and map fields work the same way in proto2 and proto3.
The following proto definition:

```protobuf
message Foo {
   map<string, int32> fieldMap = 1;
   repeated int32 fieldRepeated = 2;
}
```

results in the obvious properties on the generated struct:

```swift
struct Foo {
  var fieldMap: Dictionary<String,Int32> = [:]
  var fieldRepeated: [Int32] = []
}
```

### Message-valued Fields

Protobuf allows recursive structures such as the following:

```protobuf
syntax = "proto3";
message Foo {
   Foo foo_field = 1;
}
```

The simple patterns above cannot correctly handle this because Swift does not
permit recursive structs. To correctly model this, we need to store `fooField`
in a separate storage class that will be allocated on the heap:

```swift
struct Foo {
  private class _StorageClass {
    var _fooField: Foo? = nil
  }
  private var _storage = _StorageClass()

  public var fooField: Foo {
    get {return _storage?._fooField ?? Foo()}
    set {_uniqueStorage()._fooField = newValue}
  }

  private mutating func _uniqueStorage() -> _StorageClass { ... }
}
```

With this structure, the value for `fooField` actually resides in a
`_StorageClass` object allocated on the heap.
The `_uniqueStorage()` method is a simple template that provides standard
Swift copy-on-write behaviors:

```swift
  private mutating func _uniqueStorage() -> _StorageClass {
    if !isKnownUniquelyReferenced(&_storage) {
      _storage = _storage.copy()
    }
    return _storage
  }
```

Note that the `_uniqueStorage()` method depends on a `copy()`
method on the storage class which is not shown here.

In the current implementation, a storage class is generated in the following
cases:

 * If there are any fields containing a message or group type
 * If there are more than 16 total fields

This logic will doubtless change in the future.
In particular, there are likely cases where it makes more sense
to put some fields directly
into the struct and others into the storage class, but the current
implementation will put all fields into the storage class if it decides
to use a storage class.

Whether a particular field is generated directly on the struct or on
an internal storage class should be entirely opaque to the user.

## General Message Information

Each generated struct has a collection of computed variables that return basic
information about the struct.

Here is the actual first part of the generated code for `message Foo` above:

```swift
public struct Foo: ProtobufGeneratedMessage {
  static let protoMessageName: String = "Foo"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "field1"),
    2: .same(proto: "field2"),
  ]
```

The `protoMessageName` provides the fully-qualified
message name (including leading package, if any) from the `.proto` file
for use by various serialization mechanisms.
The `_protobuf_nameMap` provides fast translation between
field numbers, JSON field names, and proto field names,
as needed by the serialization engines in the runtime library.

## Serialization support

The serialization support is based on a traversal mechanism (also known as
"The Visitor Pattern").
The various serialization systems in the runtime library construct objects
that conform to the `SwiftProtobuf.Visitor` protocol and then invoke
the `traverse()` method which will provide the visitor with a look at every
non-empty field.

As above, this varies slightly depending on the proto language dialect,
so let's start with a proto3 example:

```protobuf
syntax= "proto3";
message Foo {
  int32 field1 = 1;
  sfixed32 field2 = 2;
  repeated string field3 = 3;
  Foo fooField = 4;
  map<int32,bool> mapField = 5;
}
```

This generates a storage class, of course.
The storage class and the generated `traverse()` look like this:

```swift
  private class _StorageClass {
    var _field1: Int32 = 0
    var _field2: Int32 = 0
    var _field3: [String] = []
    var _fooField: Foo? = nil
    var _mapField: Dictionary<Int32,Bool> = [:]
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    try withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      if _storage._field1 != 0 {
        try visitor.visitSingularInt32Field(
                value: _storage._field1,
                fieldNumber: 1)
      }
      if _storage._field2 != 0 {
        try visitor.visitSingularSFixed32Field(
                value: _storage._field2,
                fieldNumber: 2)
      }
      if !_storage._field3.isEmpty {
        try visitor.visitRepeatedStringField(
                value: _storage._field3,
                fieldNumber: 3)
      }
      if let v = _storage._fooField {
        try visitor.visitSingularMessageField(
                value: v,
                fieldNumber: 4)
      }
      if !_storage._mapField.isEmpty {
        try visitor.visitMapField(
                fieldType: _ProtobufMap<ProtobufInt32,ProtobufBool>.self,
                value: _storage._mapField,
                fieldNumber: 5)
      }
    }
    try unknownFields.traverse(visitor: &visitor)
  }
```

Note that the visitors are generally structs (not classes) that
are passed as `inout` parameters.
Also note that the fields are traversed in order of field number;
this causes some complexity when dealing with extension ranges
or `oneof` groups.

Since this example is proto3, we only need to visit fields whose value is not the
default.
The `ProtobufVisitor` protocol specifies a number of `visitXyzField`
methods that accept different types of fields.
Each of these methods is given the value and the proto field number.
The field number is used as-is by the binary serializer; the JSON and
text serializers use the `_protobuf_nameMap` described above to convert
the field numbers into field names.

Most of the `visit` methods accept a very specific type of data.
The visitor methods for messages, groups, and enums use generic
arguments to identify the exact type of object.
This is insufficient for map fields, however, so the map visitors
use an additional type object at this point.

Many other facilities - not just serialization - can be built on
top of this same machinery.
For example, the `hashValue` implementation uses the same traversal
machinery to iterate over all of the set fields and values in order
to compute the hash.

You can look at the runtime library to see more details about the
`Visitor` protocol and the various implementations in each encoder.

## Deserialization support

Deserialization is a more complex overall process than serialization,
although the generated code is still quite simple.

The deserialization machinery rests on the generated `decodeMessage`
method. Here is the `decodeMessage` method for the example just above:

```swift
  mutating func decodeMessage<D: Decoder>(decoder: inout D) throws {
    _ = _uniqueStorage()
    try withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      while let fieldNumber = try decoder.nextFieldNumber() {
        switch fieldNumber {
        case 1: try decoder.decodeSingularInt32Field(
                     value: &_storage._field1)
        case 2: try decoder.decodeSingularSFixed32Field(
                     value: &_storage._field2)
        case 3: try decoder.decodeRepeatedStringField(
                     value: &_storage._field3)
        case 4: try decoder.decodeSingularMessageField(
                     value: &_storage._fooField)
        case 5: try decoder.decodeMapField(
                     fieldType: _ProtobufMap<ProtobufInt32,ProtobufBool>.self,
                     value: &_storage._mapField)
        default: break
        }
      }
    }
  }
```

This captures the essential structure of all of the supported decoders:
inspect the next field, determine how to decode it, and store the
result in the appropriate property.

In essence, the decoder knows how to identify the next field and
how to decode a field body once someone else has provided the schema.
This block of generated code drives the decode process by requesting
the number of the next field and using a `switch` statement to convert
that into schema information.

There are two important features of this design:

* The fields are processed in the order they are seen by the decoder.
  This allows the decoder to walk through the data serially for
  optimal performance.

* Fields are identified here by number.
  Decoders that use named fields must use the `_protobuf_nameMap`
  to translate those into field numbers.
  This allows number-keyed formats (such as protobuf's default binary
  format) to operate extremely efficiently.

Unknown fields are captured by the decoder as a by-product of this
process:
The decoder sees which fields are supported (one of its decode methods
gets called for each one), so it can identify and preserve any field
that is not known.
After processing the entire message, the decoder can push the
collected unknown field data onto the resulting message object.

## Miscellaneous support methods

TODO: initializers

TODO: _protobuf_generated methods

# Enums

TODO

# Groups

TODO

# Extensions

TODO

