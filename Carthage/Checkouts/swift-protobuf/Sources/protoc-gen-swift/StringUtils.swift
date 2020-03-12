// Sources/protoc-gen-swift/StringUtils.swift - String processing utilities
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------

import Foundation

func splitPath(pathname: String) -> (dir:String, base:String, suffix:String) {
  var dir = ""
  var base = ""
  var suffix = ""
  for c in pathname {
    if c == "/" {
      dir += base + suffix + String(c)
      base = ""
      suffix = ""
    } else if c == "." {
      base += suffix
      suffix = String(c)
    } else {
      suffix += String(c)
    }
  }
  let validSuffix = suffix.isEmpty || suffix.first == "."
  if !validSuffix {
    base += suffix
    suffix = ""
  }
  return (dir: dir, base: base, suffix: suffix)
}

func partition(string: String, atFirstOccurrenceOf substring: String) -> (String, String) {
  guard let index = string.range(of: substring)?.lowerBound else {
    return (string, "")
  }
  return (String(string[..<index]),
          String(string[string.index(after: index)...]))
}

func parseParameter(string: String?) -> [(key:String, value:String)] {
  guard let string = string, !string.isEmpty else {
    return []
  }
  let parts = string.components(separatedBy: ",")
  let asPairs = parts.map { partition(string: $0, atFirstOccurrenceOf: "=") }
  let result = asPairs.map { (key:trimWhitespace($0), value:trimWhitespace($1)) }
  return result
}

func trimWhitespace(_ s: String) -> String {
  return s.trimmingCharacters(in: .whitespacesAndNewlines)
}

/// The protoc parser emits byte literals using an escaped C convention.
/// Fortunately, it uses only a limited subset of the C escapse:
///  \n\r\t\\\'\" and three-digit octal escapes but nothing else.
func escapedToDataLiteral(_ s: String) -> String {
  if s.isEmpty {
    return "SwiftProtobuf.Internal.emptyData"
  }
  var out = "Data(["
  var separator = ""
  var escape = false
  var octal = 0
  var octalAccumulator = 0
  for c in s.utf8 {
    if octal > 0 {
      precondition(c >= 48 && c < 56)
      octalAccumulator <<= 3
      octalAccumulator |= (Int(c) - 48)
      octal -= 1
      if octal == 0 {
        out += separator
        out += "\(octalAccumulator)"
        separator = ", "
      }
    } else if escape {
      switch c {
      case 110:
        out += separator
        out += "10"
        separator = ", "
      case 114:
        out += separator
        out += "13"
        separator = ", "
      case 116:
        out += separator
        out += "9"
        separator = ", "
      case 48..<56:
        octal = 2 // 2 more digits
        octalAccumulator = Int(c) - 48
      default:
        out += separator
        out += "\(c)"
        separator = ", "
      }
      escape = false
    } else if c == 92 { // backslash
      escape = true
    } else {
      out += separator
      out += "\(c)"
      separator = ", "
    }
  }
  out += "])"
  return out
}

/// Generate a Swift string literal suitable for including in
/// source code
private let hexdigits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"]

func stringToEscapedStringLiteral(_ s: String) -> String {
  if s.isEmpty {
    return "String()"
  }
  var out = "\""
  for c in s.unicodeScalars {
    switch c.value {
    case 0:
      out += "\\0"
    case 1..<32:
      let n = Int(c.value)
      let hex1 = hexdigits[(n >> 4) & 15]
      let hex2 = hexdigits[n & 15]
      out += "\\u{" + hex1 + hex2 + "}"
    case 34:
      out += "\\\""
    case 92:
      out += "\\\\"
    default:
      out.append(String(c))
    }
  }
  return out + "\""
}
