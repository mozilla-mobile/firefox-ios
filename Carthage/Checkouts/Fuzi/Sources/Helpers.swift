// Helpers.swift
// Copyright (c) 2015 Ce Zheng
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import libxml2

// Public Helpers

/// For printing an `XMLNode`
extension XMLNode: CustomStringConvertible, CustomDebugStringConvertible {
  /// String printed by `print` function
  public var description: String {
    return self.rawXML
  }
  
  /// String printed by `debugPrint` function
  public var debugDescription: String {
    return self.rawXML
  }
}

/// For printing an `XMLDocument`
extension XMLDocument: CustomStringConvertible, CustomDebugStringConvertible {
  /// String printed by `print` function
  public var description: String {
    return self.root?.rawXML ?? ""
  }
  
  /// String printed by `debugPrint` function
  public var debugDescription: String {
    return self.root?.rawXML ?? ""
  }
}

/// Abstract key type for finding tags or other xml names, as used like element.children(tag: TagNameComparable, ...)
public protocol XMLCharsComparable {
  func caseInsensitivelyEqual(to other: UnsafePointer<xmlChar>) -> Bool
}

/// For finding tags by normal string
extension String: XMLCharsComparable {
  public func caseInsensitivelyEqual(to other: UnsafePointer<xmlChar>) -> Bool {
    return withCString { (cString: UnsafePointer<CChar>) in
        let xmlChars = UnsafeRawPointer(cString).assumingMemoryBound(to: xmlChar.self)
        return xmlStrcasecmp(xmlChars, other) == 0
    }
  }
}

/// For finding tags by string literals
extension StaticString: XMLCharsComparable {
  // compare without copying to Swift.String memory
  public func caseInsensitivelyEqual(to other: UnsafePointer<xmlChar>) -> Bool {
    return withUTF8Buffer { (utf8Buffer: UnsafeBufferPointer<UInt8>) in
      guard let baseAddress = utf8Buffer.baseAddress else {
        return false
      }

      let xmlChars = UnsafeRawPointer(baseAddress).assumingMemoryBound(to: xmlChar.self)
      return xmlStrcasecmp(xmlChars, other) == 0
    }
  }
}

// Internal Helpers

internal extension String {
  subscript (nsrange: NSRange) -> String {
    let start = utf16.index(utf16.startIndex, offsetBy: nsrange.location)
    let end = utf16.index(start, offsetBy: nsrange.length)
    return String(utf16[start..<end])!
  }
}

// Just a smiling helper operator making frequent UnsafePointer -> String cast

prefix operator ^-^
internal prefix func ^-^ <T> (ptr: UnsafePointer<T>?) -> String? {
  if let ptr = ptr {
    return String(validatingUTF8: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
  }
  return nil
}

internal prefix func ^-^ <T> (ptr: UnsafeMutablePointer<T>?) -> String? {
  if let ptr = ptr {
    return String(validatingUTF8: UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: CChar.self))
  }
  return nil
}

internal struct LinkedCNodes: Sequence, IteratorProtocol {
  internal let head: xmlNodePtr?
  internal let types: [xmlElementType]
  
  fileprivate var cursor: xmlNodePtr?
  mutating func next() -> xmlNodePtr? {
    defer {
      if let ptr = cursor {
        cursor = ptr.pointee.next
      }
    }
    while let ptr = cursor, !types.contains(where: { $0 == ptr.pointee.type }) {
      cursor = ptr.pointee.next
    }
    return cursor
  }
  
  init(head: xmlNodePtr?, types: [xmlElementType] = [XML_ELEMENT_NODE]) {
    self.head = head
    self.cursor = head
    self.types = types
  }
}

internal func cXMLNode(_ node: xmlNodePtr?, matchesTag tag: XMLCharsComparable, inNamespace ns: XMLCharsComparable?) -> Bool {
  guard let name = node?.pointee.name else {
    return false
  }

  var matches = tag.caseInsensitivelyEqual(to: name)

  if let ns = ns {
    guard let prefix = node?.pointee.ns?.pointee.prefix else {
      return false
    }
    matches = matches && ns.caseInsensitivelyEqual(to: prefix)
  }
  return matches
}
