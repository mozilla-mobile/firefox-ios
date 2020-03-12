// Sources/SwiftProtobuf/JSONEncoder.swift - JSON Encoding support
//
// Copyright (c) 2014 - 2019 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// JSON serialization engine.
///
// -----------------------------------------------------------------------------

import Foundation

private let asciiZero = UInt8(ascii: "0")
private let asciiOne = UInt8(ascii: "1")
private let asciiTwo = UInt8(ascii: "2")
private let asciiThree = UInt8(ascii: "3")
private let asciiFour = UInt8(ascii: "4")
private let asciiFive = UInt8(ascii: "5")
private let asciiSix = UInt8(ascii: "6")
private let asciiSeven = UInt8(ascii: "7")
private let asciiEight = UInt8(ascii: "8")
private let asciiNine = UInt8(ascii: "9")
private let asciiMinus = UInt8(ascii: "-")
private let asciiPlus = UInt8(ascii: "+")
private let asciiEquals = UInt8(ascii: "=")
private let asciiColon = UInt8(ascii: ":")
private let asciiComma = UInt8(ascii: ",")
private let asciiDoubleQuote = UInt8(ascii: "\"")
private let asciiBackslash = UInt8(ascii: "\\")
private let asciiForwardSlash = UInt8(ascii: "/")
private let asciiOpenSquareBracket = UInt8(ascii: "[")
private let asciiCloseSquareBracket = UInt8(ascii: "]")
private let asciiOpenCurlyBracket = UInt8(ascii: "{")
private let asciiCloseCurlyBracket = UInt8(ascii: "}")
private let asciiUpperA = UInt8(ascii: "A")
private let asciiUpperB = UInt8(ascii: "B")
private let asciiUpperC = UInt8(ascii: "C")
private let asciiUpperD = UInt8(ascii: "D")
private let asciiUpperE = UInt8(ascii: "E")
private let asciiUpperF = UInt8(ascii: "F")
private let asciiUpperZ = UInt8(ascii: "Z")
private let asciiLowerA = UInt8(ascii: "a")
private let asciiLowerZ = UInt8(ascii: "z")

private let base64Digits: [UInt8] = {
    var digits = [UInt8]()
    digits.append(contentsOf: asciiUpperA...asciiUpperZ)
    digits.append(contentsOf: asciiLowerA...asciiLowerZ)
    digits.append(contentsOf: asciiZero...asciiNine)
    digits.append(asciiPlus)
    digits.append(asciiForwardSlash)
    return digits
}()

private let hexDigits: [UInt8] = {
    var digits = [UInt8]()
    digits.append(contentsOf: asciiZero...asciiNine)
    digits.append(contentsOf: asciiUpperA...asciiUpperF)
    return digits
}()

internal struct JSONEncoder {
    private var data = [UInt8]()
    private var separator: UInt8?

    internal init() {}

    internal var dataResult: Data { return Data(data) }

    internal var stringResult: String {
        get {
            return String(bytes: data, encoding: String.Encoding.utf8)!
        }
    }

    /// Append a `StaticString` to the JSON text.  Because
    /// `StaticString` is already UTF8 internally, this is faster
    /// than appending a regular `String`.
    internal mutating func append(staticText: StaticString) {
        let buff = UnsafeBufferPointer(start: staticText.utf8Start, count: staticText.utf8CodeUnitCount)
        data.append(contentsOf: buff)
    }

    /// Append a `_NameMap.Name` to the JSON text surrounded by quotes.
    /// As with StaticString above, a `_NameMap.Name` provides pre-converted
    /// UTF8 bytes, so this is much faster than appending a regular
    /// `String`.
    internal mutating func appendQuoted(name: _NameMap.Name) {
        data.append(asciiDoubleQuote)
        data.append(contentsOf: name.utf8Buffer)
        data.append(asciiDoubleQuote)
    }

    /// Append a `String` to the JSON text.
    internal mutating func append(text: String) {
        data.append(contentsOf: text.utf8)
    }

    /// Append a raw utf8 in a `Data` to the JSON text.
    internal mutating func append(utf8Data: Data) {
        data.append(contentsOf: utf8Data)
    }

    /// Begin a new field whose name is given as a `_NameMap.Name`
    internal mutating func startField(name: _NameMap.Name) {
        if let s = separator {
            data.append(s)
        }
        appendQuoted(name: name)
        data.append(asciiColon)
        separator = asciiComma
    }

    /// Begin a new field whose name is given as a `String`.
    internal mutating func startField(name: String) {
        if let s = separator {
            data.append(s)
        }
        data.append(asciiDoubleQuote)
        // Can avoid overhead of putStringValue, since
        // the JSON field names are always clean ASCII.
        data.append(contentsOf: name.utf8)
        append(staticText: "\":")
        separator = asciiComma
    }

    /// Append an open square bracket `[` to the JSON.
    internal mutating func startArray() {
        data.append(asciiOpenSquareBracket)
        separator = nil
    }

    /// Append a close square bracket `]` to the JSON.
    internal mutating func endArray() {
        data.append(asciiCloseSquareBracket)
        separator = asciiComma
    }

    /// Append a comma `,` to the JSON.
    internal mutating func comma() {
        data.append(asciiComma)
    }

    /// Append an open curly brace `{` to the JSON.
    internal mutating func startObject() {
        if let s = separator {
            data.append(s)
        }
        data.append(asciiOpenCurlyBracket)
        separator = nil
    }

    internal mutating func startNestedObject() {
        data.append(asciiOpenCurlyBracket)
        separator = nil
    }

    /// Append a close curly brace `}` to the JSON.
    internal mutating func endObject() {
        data.append(asciiCloseCurlyBracket)
        separator = asciiComma
    }

    /// Write a JSON `null` token to the output.
    internal mutating func putNullValue() {
        append(staticText: "null")
    }

    /// Append a float value to the output.
    /// This handles Nan and infinite values by
    /// writing well-known string values.
    internal mutating func putFloatValue(value: Float) {
        if value.isNaN {
            append(staticText: "\"NaN\"")
        } else if !value.isFinite {
            if value < 0 {
                append(staticText: "\"-Infinity\"")
            } else {
                append(staticText: "\"Infinity\"")
            }
        } else {
            data.append(contentsOf: value.debugDescription.utf8)
        }
    }

    /// Append a double value to the output.
    /// This handles Nan and infinite values by
    /// writing well-known string values.
    internal mutating func putDoubleValue(value: Double) {
        if value.isNaN {
            append(staticText: "\"NaN\"")
        } else if !value.isFinite {
            if value < 0 {
                append(staticText: "\"-Infinity\"")
            } else {
                append(staticText: "\"Infinity\"")
            }
        } else {
            data.append(contentsOf: value.debugDescription.utf8)
        }
    }

    /// Append a UInt64 to the output (without quoting).
    private mutating func appendUInt(value: UInt64) {
        if value >= 10 {
            appendUInt(value: value / 10)
        }
        data.append(asciiZero + UInt8(value % 10))
    }

    /// Append an Int64 to the output (without quoting).
    private mutating func appendInt(value: Int64) {
        if value < 0 {
            data.append(asciiMinus)
            // This is the twos-complement negation of value,
            // computed in a way that won't overflow a 64-bit
            // signed integer.
            appendUInt(value: 1 + ~UInt64(bitPattern: value))
        } else {
            appendUInt(value: UInt64(bitPattern: value))
        }
    }

    /// Write an Enum as an int.
    internal mutating func putEnumInt(value: Int) {
        appendInt(value: Int64(value))
    }

    /// Write an `Int64` using protobuf JSON quoting conventions.
    internal mutating func putInt64(value: Int64) {
        data.append(asciiDoubleQuote)
        appendInt(value: value)
        data.append(asciiDoubleQuote)
    }

    /// Write an `Int32` with quoting suitable for
    /// using the value as a map key.
    internal mutating func putQuotedInt32(value: Int32) {
        data.append(asciiDoubleQuote)
        appendInt(value: Int64(value))
        data.append(asciiDoubleQuote)
    }

    /// Write an `Int32` in the default format.
    internal mutating func putInt32(value: Int32) {
        appendInt(value: Int64(value))
    }

    /// Write a `UInt64` using protobuf JSON quoting conventions.
    internal mutating func putUInt64(value: UInt64) {
        data.append(asciiDoubleQuote)
        appendUInt(value: value)
        data.append(asciiDoubleQuote)
    }

    /// Write a `UInt32` with quoting suitable for
    /// using the value as a map key.
    internal mutating func putQuotedUInt32(value: UInt32) {
        data.append(asciiDoubleQuote)
        appendUInt(value: UInt64(value))
        data.append(asciiDoubleQuote)
    }

    /// Write a `UInt32` in the default format.
    internal mutating func putUInt32(value: UInt32) {
        appendUInt(value: UInt64(value))
    }

    /// Write a `Bool` with quoting suitable for
    /// using the value as a map key.
    internal mutating func putQuotedBoolValue(value: Bool) {
        data.append(asciiDoubleQuote)
        putBoolValue(value: value)
        data.append(asciiDoubleQuote)
    }

    /// Write a `Bool` in the default format.
    internal mutating func putBoolValue(value: Bool) {
        if value {
            append(staticText: "true")
        } else {
            append(staticText: "false")
        }
    }

    /// Append a string value escaping special characters as needed.
    internal mutating func putStringValue(value: String) {
        data.append(asciiDoubleQuote)
        for c in value.unicodeScalars {
            switch c.value {
            // Special two-byte escapes
            case 8: append(staticText: "\\b")
            case 9: append(staticText: "\\t")
            case 10: append(staticText: "\\n")
            case 12: append(staticText: "\\f")
            case 13: append(staticText: "\\r")
            case 34: append(staticText: "\\\"")
            case 92: append(staticText: "\\\\")
            case 0...31, 127...159: // Hex form for C0 control chars
                append(staticText: "\\u00")
                data.append(hexDigits[Int(c.value / 16)])
                data.append(hexDigits[Int(c.value & 15)])
            case 23...126:
                data.append(UInt8(truncatingIfNeeded: c.value))
            case 0x80...0x7ff:
                data.append(0xc0 + UInt8(truncatingIfNeeded: c.value >> 6))
                data.append(0x80 + UInt8(truncatingIfNeeded: c.value & 0x3f))
            case 0x800...0xffff:
                data.append(0xe0 + UInt8(truncatingIfNeeded: c.value >> 12))
                data.append(0x80 + UInt8(truncatingIfNeeded: (c.value >> 6) & 0x3f))
                data.append(0x80 + UInt8(truncatingIfNeeded: c.value & 0x3f))
            default:
                data.append(0xf0 + UInt8(truncatingIfNeeded: c.value >> 18))
                data.append(0x80 + UInt8(truncatingIfNeeded: (c.value >> 12) & 0x3f))
                data.append(0x80 + UInt8(truncatingIfNeeded: (c.value >> 6) & 0x3f))
                data.append(0x80 + UInt8(truncatingIfNeeded: c.value & 0x3f))
            }
        }
        data.append(asciiDoubleQuote)
    }

    /// Append a bytes value using protobuf JSON Base-64 encoding.
    internal mutating func putBytesValue(value: Data) {
        data.append(asciiDoubleQuote)
        if value.count > 0 {
            value.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
              if let p = body.baseAddress, body.count > 0 {
                var t: Int = 0
                var bytesInGroup: Int = 0
                for i in 0..<body.count {
                    if bytesInGroup == 3 {
                        data.append(base64Digits[(t >> 18) & 63])
                        data.append(base64Digits[(t >> 12) & 63])
                        data.append(base64Digits[(t >> 6) & 63])
                        data.append(base64Digits[t & 63])
                        t = 0
                        bytesInGroup = 0
                    }
                    t = (t << 8) + Int(p[i])
                    bytesInGroup += 1
                }
                switch bytesInGroup {
                case 3:
                    data.append(base64Digits[(t >> 18) & 63])
                    data.append(base64Digits[(t >> 12) & 63])
                    data.append(base64Digits[(t >> 6) & 63])
                    data.append(base64Digits[t & 63])
                case 2:
                    t <<= 8
                    data.append(base64Digits[(t >> 18) & 63])
                    data.append(base64Digits[(t >> 12) & 63])
                    data.append(base64Digits[(t >> 6) & 63])
                    data.append(asciiEquals)
                case 1:
                    t <<= 16
                    data.append(base64Digits[(t >> 18) & 63])
                    data.append(base64Digits[(t >> 12) & 63])
                    data.append(asciiEquals)
                    data.append(asciiEquals)
                default:
                    break
                }
              }
            }
        }
        data.append(asciiDoubleQuote)
    }
}

