// Sources/SwiftProtobuf/NameMap.swift - Bidirectional number/name mapping
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------

/// TODO: Right now, only the NameMap and the NameDescription enum
/// (which are directly used by the generated code) are public.
/// This means that code outside the library has no way to actually
/// use this data.  We should develop and publicize a suitable API
/// for that purpose.  (Which might be the same as the internal API.)

/// This must be exactly the same as the corresponding code in the
/// protoc-gen-swift code generator.  Changing it will break
/// compatibility of the library with older generated code.
///
/// It does not necessarily need to match protoc's JSON field naming
/// logic, however.
private func toJsonFieldName(_ s: String) -> String {
    var result = String()
    var capitalizeNext = false
    for c in s {
        if c == "_" {
            capitalizeNext = true
        } else if capitalizeNext {
            result.append(String(c).uppercased())
            capitalizeNext = false
        } else {
            result.append(String(c))
        }
    }
    return result
}

/// Allocate static memory buffers to intern UTF-8
/// string data.  Track the buffers and release all of those buffers
/// in case we ever get deallocated.
fileprivate class InternPool {
  private var interned = [UnsafeRawBufferPointer]()

  func intern(utf8: String.UTF8View) -> UnsafeRawBufferPointer {
    #if swift(>=4.1)
    let mutable = UnsafeMutableRawBufferPointer.allocate(byteCount: utf8.count,
                                                         alignment: MemoryLayout<UInt8>.alignment)
    #else
    let mutable = UnsafeMutableRawBufferPointer.allocate(count: utf8.count)
    #endif
    mutable.copyBytes(from: utf8)
    let immutable = UnsafeRawBufferPointer(mutable)
    interned.append(immutable)
    return immutable
  }

  deinit {
    for buff in interned {
        #if swift(>=4.1)
          buff.deallocate()
        #else
          let p = UnsafeMutableRawPointer(mutating: buff.baseAddress)!
          p.deallocate(bytes: buff.count, alignedTo: 1)
        #endif
    }
  }
}

#if !swift(>=4.2)
// Constants for FNV hash http://tools.ietf.org/html/draft-eastlake-fnv-03
private let i_2166136261 = Int(bitPattern: 2166136261)
private let i_16777619 = Int(16777619)
#endif

/// An immutable bidirectional mapping between field/enum-case names
/// and numbers, used to record field names for text-based
/// serialization (JSON and text).  These maps are lazily instantiated
/// for each message as needed, so there is no run-time overhead for
/// users who do not use text-based serialization formats.
public struct _NameMap: ExpressibleByDictionaryLiteral {

  /// An immutable interned string container.  The `utf8Start` pointer
  /// is guaranteed valid for the lifetime of the `NameMap` that you
  /// fetched it from.  Since `NameMap`s are only instantiated as
  /// immutable static values, that should be the lifetime of the
  /// program.
  ///
  /// Internally, this uses `StaticString` (which refers to a fixed
  /// block of UTF-8 data) where possible.  In cases where the string
  /// has to be computed, it caches the UTF-8 bytes in an
  /// unmovable and immutable heap area.
  internal struct Name: Hashable, CustomStringConvertible {
    // This is safe to use elsewhere in this library
    internal init(staticString: StaticString) {
        self.nameString = .staticString(staticString)
        self.utf8Buffer = UnsafeRawBufferPointer(start: staticString.utf8Start, count: staticString.utf8CodeUnitCount)
    }

    // This should not be used outside of this file, as it requires
    // coordinating the lifecycle with the lifecycle of the pool
    // where the raw UTF8 gets interned.
    fileprivate init(string: String, pool: InternPool) {
      let utf8 = string.utf8
      self.utf8Buffer = pool.intern(utf8: utf8)
      self.nameString = .string(string)
    }

    // This is for building a transient `Name` object sufficient for lookup purposes.
    // It MUST NOT be exposed outside of this file.
    fileprivate init(transientUtf8Buffer: UnsafeRawBufferPointer) {
        self.nameString = .staticString("")
        self.utf8Buffer = transientUtf8Buffer
    }

    private(set) var utf8Buffer: UnsafeRawBufferPointer

    private enum NameString {
      case string(String)
      case staticString(StaticString)
    }
    private var nameString: NameString

    public var description: String {
      switch nameString {
      case .string(let s): return s
      case .staticString(let s): return s.description
      }
    }

  #if swift(>=4.2)
    public func hash(into hasher: inout Hasher) {
      for byte in utf8Buffer {
        hasher.combine(byte)
      }
    }
  #else  // swift(>=4.2)
    public var hashValue: Int {
      var h = i_2166136261
      for byte in utf8Buffer {
        h = (h ^ Int(byte)) &* i_16777619
      }
      return h
    }
  #endif  // swift(>=4.2)

    public static func ==(lhs: Name, rhs: Name) -> Bool {
      if lhs.utf8Buffer.count != rhs.utf8Buffer.count {
        return false
      }
      return lhs.utf8Buffer.elementsEqual(rhs.utf8Buffer)
    }
  }

  /// The JSON and proto names for a particular field, enum case, or extension.
  internal struct Names {
    private(set) var json: Name?
    private(set) var proto: Name
  }

  /// A description of the names for a particular field or enum case.
  /// The different forms here let us minimize the amount of string
  /// data that we store in the binary.
  ///
  /// These are only used in the generated code to initialize a NameMap.
  public enum NameDescription {

    /// The proto (text format) name and the JSON name are the same string.
    case same(proto: StaticString)

    /// The JSON name can be computed from the proto string
    case standard(proto: StaticString)

    /// The JSON and text format names are just different.
    case unique(proto: StaticString, json: StaticString)

    /// Used for enum cases only to represent a value's primary proto name (the
    /// first defined case) and its aliases. The JSON and text format names for
    /// enums are always the same.
    case aliased(proto: StaticString, aliases: [StaticString])
  }

  private var internPool = InternPool()

  /// The mapping from field/enum-case numbers to names.
  private var numberToNameMap: [Int: Names] = [:]

  /// The mapping from proto/text names to field/enum-case numbers.
  private var protoToNumberMap: [Name: Int] = [:]

  /// The mapping from JSON names to field/enum-case numbers.
  /// Note that this also contains all of the proto/text names,
  /// as required by Google's spec for protobuf JSON.
  private var jsonToNumberMap: [Name: Int] = [:]

  /// Creates a new empty field/enum-case name/number mapping.
  public init() {}

  /// Build the bidirectional maps between numbers and proto/JSON names.
  public init(dictionaryLiteral elements: (Int, NameDescription)...) {
    for (number, description) in elements {
      switch description {

      case .same(proto: let p):
        let protoName = Name(staticString: p)
        let names = Names(json: protoName, proto: protoName)
        numberToNameMap[number] = names
        protoToNumberMap[protoName] = number
        jsonToNumberMap[protoName] = number

      case .standard(proto: let p):
        let protoName = Name(staticString: p)
        let jsonString = toJsonFieldName(protoName.description)
        let jsonName = Name(string: jsonString, pool: internPool)
        let names = Names(json: jsonName, proto: protoName)
        numberToNameMap[number] = names
        protoToNumberMap[protoName] = number
        jsonToNumberMap[protoName] = number
        jsonToNumberMap[jsonName] = number

      case .unique(proto: let p, json: let j):
        let jsonName = Name(staticString: j)
        let protoName = Name(staticString: p)
        let names = Names(json: jsonName, proto: protoName)
        numberToNameMap[number] = names
        protoToNumberMap[protoName] = number
        jsonToNumberMap[protoName] = number
        jsonToNumberMap[jsonName] = number

      case .aliased(proto: let p, aliases: let aliases):
        let protoName = Name(staticString: p)
        let names = Names(json: protoName, proto: protoName)
        numberToNameMap[number] = names
        protoToNumberMap[protoName] = number
        jsonToNumberMap[protoName] = number
        for alias in aliases {
            let protoName = Name(staticString: alias)
            protoToNumberMap[protoName] = number
            jsonToNumberMap[protoName] = number
        }
      }
    }
  }

  /// Returns the name bundle for the field/enum-case with the given number, or
  /// `nil` if there is no match.
  internal func names(for number: Int) -> Names? {
    return numberToNameMap[number]
  }

  /// Returns the field/enum-case number that has the given JSON name,
  /// or `nil` if there is no match.
  ///
  /// This is used by the Text format parser to look up field or enum
  /// names using a direct reference to the un-decoded UTF8 bytes.
  internal func number(forProtoName raw: UnsafeRawBufferPointer) -> Int? {
    let n = Name(transientUtf8Buffer: raw)
    return protoToNumberMap[n]
  }

  /// Returns the field/enum-case number that has the given JSON name,
  /// or `nil` if there is no match.
  ///
  /// This accepts a regular `String` and is used in JSON parsing
  /// only when a field name or enum name was decoded from a string
  /// containing backslash escapes.
  ///
  /// JSON parsing must interpret *both* the JSON name of the
  /// field/enum-case provided by the descriptor *as well as* its
  /// original proto/text name.
  internal func number(forJSONName name: String) -> Int? {
    let utf8 = Array(name.utf8)
    return utf8.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
      let n = Name(transientUtf8Buffer: buffer)
      return jsonToNumberMap[n]
    }
  }

  /// Returns the field/enum-case number that has the given JSON name,
  /// or `nil` if there is no match.
  ///
  /// This is used by the JSON parser when a field name or enum name
  /// required no special processing.  As a result, we can avoid
  /// copying the name and look up the number using a direct reference
  /// to the un-decoded UTF8 bytes.
  internal func number(forJSONName raw: UnsafeRawBufferPointer) -> Int? {
    let n = Name(transientUtf8Buffer: raw)
    return jsonToNumberMap[n]
  }
}
