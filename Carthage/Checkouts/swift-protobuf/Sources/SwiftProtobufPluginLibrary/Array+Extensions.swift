// Sources/SwiftProtobufPluginLibrary/Array+Extensions.swift - Additions to Arrays
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------

import Foundation

extension Array {

  /// Like map, but calls the transform with the index and value.
  ///
  /// NOTE: It would seem like doing:
  ///   return self.enumerated().map {
  ///     return try transform($0.index, $0.element)
  ///   }
  /// would seem like a simple thing to avoid extension. However as of Xcode 8.3.2
  /// (Swift 3.1), building/running 5000000 interation test (macOS) of the differences
  /// are rather large -
  ///   Release build:
  ///     Using enumerated: 3.694987967
  ///     Using enumeratedMap: 0.961241992
  ///   Debug build:
  ///     Using enumerated: 20.038512905
  ///     Using enumeratedMap: 8.521299144
  func enumeratedMap<T>(_ transform: (Int, Element) throws -> T) rethrows -> [T] {
    var i: Int = -1
    return try map {
      i += 1
      return try transform(i, $0)
    }
  }
}

#if !swift(>=4.2)
extension Array {
  func firstIndex(where predicate: (Element) throws -> Bool) rethrows -> Int? {
    var i = self.startIndex
    while i < self.endIndex {
      if try predicate(self[i]) {
        return i
      }
      self.formIndex(after: &i)
    }
    return nil
  }
}
#endif  // !swift(>=4.2)
