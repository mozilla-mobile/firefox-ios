// Sources/SwiftProtobuf/ExtensionFieldValueSet.swift - Extension support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A collection of extension field values on a particular object.
/// This is only used within messages to manage the values of extension fields;
/// it does not need to be very sophisticated.
///
// -----------------------------------------------------------------------------

public struct ExtensionFieldValueSet: Hashable {
  fileprivate var values = [Int : AnyExtensionField]()

  public static func ==(lhs: ExtensionFieldValueSet,
                        rhs: ExtensionFieldValueSet) -> Bool {
    guard lhs.values.count == rhs.values.count else {
      return false
    }
    for (index, l) in lhs.values {
      if let r = rhs.values[index] {
        if type(of: l) != type(of: r) {
          return false
        }
        if !l.isEqual(other: r) {
          return false
        }
      } else {
        return false
      }
    }
    return true
  }

  public init() {}

#if swift(>=4.2)
  public func hash(into hasher: inout Hasher) {
    // AnyExtensionField is not Hashable, and the Self constraint that would
    // add breaks some of the uses of it; so the only choice is to manually
    // mix things in. However, one must remember to do things in an order
    // independent manner.
    var hash = 16777619
    for (fieldNumber, v) in values {
      var localHasher = hasher
      localHasher.combine(fieldNumber)
      v.hash(into: &localHasher)
      hash = hash &+ localHasher.finalize()
    }
    hasher.combine(hash)
  }
#else  // swift(>=4.2)
  public var hashValue: Int {
    var hash = 16777619
    for (fieldNumber, v) in values {
      // Note: This calculation cannot depend on the order of the items.
      hash = hash &+ fieldNumber &+ v.hashValue
    }
    return hash
  }
#endif  // swift(>=4.2)

  public func traverse<V: Visitor>(visitor: inout V, start: Int, end: Int) throws {
    let validIndexes = values.keys.filter {$0 >= start && $0 < end}
    for i in validIndexes.sorted() {
      let value = values[i]!
      try value.traverse(visitor: &visitor)
    }
  }

  public subscript(index: Int) -> AnyExtensionField? {
    get { return values[index] }
    set { values[index] = newValue }
  }

  public var isInitialized: Bool {
    for (_, v) in values {
      if !v.isInitialized {
        return false
      }
    }
    return true
  }
}
