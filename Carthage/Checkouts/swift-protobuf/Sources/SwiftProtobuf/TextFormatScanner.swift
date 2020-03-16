// Sources/SwiftProtobuf/TextFormatScanner.swift - Text format decoding
//
// Copyright (c) 2014 - 2019 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Test format decoding engine.
///
// -----------------------------------------------------------------------------

import Foundation

private let asciiBell = UInt8(7)
private let asciiBackspace = UInt8(8)
private let asciiTab = UInt8(9)
private let asciiNewLine = UInt8(10)
private let asciiVerticalTab = UInt8(11)
private let asciiFormFeed = UInt8(12)
private let asciiCarriageReturn = UInt8(13)
private let asciiZero = UInt8(ascii: "0")
private let asciiOne = UInt8(ascii: "1")
private let asciiThree = UInt8(ascii: "3")
private let asciiSeven = UInt8(ascii: "7")
private let asciiNine = UInt8(ascii: "9")
private let asciiColon = UInt8(ascii: ":")
private let asciiPeriod = UInt8(ascii: ".")
private let asciiPlus = UInt8(ascii: "+")
private let asciiComma = UInt8(ascii: ",")
private let asciiSemicolon = UInt8(ascii: ";")
private let asciiDoubleQuote = UInt8(ascii: "\"")
private let asciiSingleQuote = UInt8(ascii: "\'")
private let asciiBackslash = UInt8(ascii: "\\")
private let asciiForwardSlash = UInt8(ascii: "/")
private let asciiHash = UInt8(ascii: "#")
private let asciiUnderscore = UInt8(ascii: "_")
private let asciiQuestionMark = UInt8(ascii: "?")
private let asciiSpace = UInt8(ascii: " ")
private let asciiOpenSquareBracket = UInt8(ascii: "[")
private let asciiCloseSquareBracket = UInt8(ascii: "]")
private let asciiOpenCurlyBracket = UInt8(ascii: "{")
private let asciiCloseCurlyBracket = UInt8(ascii: "}")
private let asciiOpenAngleBracket = UInt8(ascii: "<")
private let asciiCloseAngleBracket = UInt8(ascii: ">")
private let asciiMinus = UInt8(ascii: "-")
private let asciiLowerA = UInt8(ascii: "a")
private let asciiUpperA = UInt8(ascii: "A")
private let asciiLowerB = UInt8(ascii: "b")
private let asciiLowerE = UInt8(ascii: "e")
private let asciiUpperE = UInt8(ascii: "E")
private let asciiLowerF = UInt8(ascii: "f")
private let asciiUpperF = UInt8(ascii: "F")
private let asciiLowerI = UInt8(ascii: "i")
private let asciiLowerL = UInt8(ascii: "l")
private let asciiLowerN = UInt8(ascii: "n")
private let asciiLowerR = UInt8(ascii: "r")
private let asciiLowerS = UInt8(ascii: "s")
private let asciiLowerT = UInt8(ascii: "t")
private let asciiUpperT = UInt8(ascii: "T")
private let asciiLowerU = UInt8(ascii: "u")
private let asciiLowerV = UInt8(ascii: "v")
private let asciiLowerX = UInt8(ascii: "x")
private let asciiLowerY = UInt8(ascii: "y")
private let asciiLowerZ = UInt8(ascii: "z")
private let asciiUpperZ = UInt8(ascii: "Z")

private func fromHexDigit(_ c: UInt8) -> UInt8? {
  if c >= asciiZero && c <= asciiNine {
    return c - asciiZero
  }
  if c >= asciiUpperA && c <= asciiUpperF {
      return c - asciiUpperA + UInt8(10)
  }
  if c >= asciiLowerA && c <= asciiLowerF {
      return c - asciiLowerA + UInt8(10)
  }
  return nil
}

// Protobuf Text encoding assumes that you're working directly
// in UTF-8.  So this implementation converts the string to UTF8,
// then decodes it into a sequence of bytes, then converts
// it back into a string.
private func decodeString(_ s: String) -> String? {
  var out = [UInt8]()
  var bytes = s.utf8.makeIterator()
  while let byte = bytes.next() {
    switch byte {
    case asciiBackslash: // backslash
      if let escaped = bytes.next() {
        switch escaped {
        case asciiZero...asciiSeven: // 0...7
          // C standard allows 1, 2, or 3 octal digits.
          let savedPosition = bytes
          let digit1 = escaped
          let digit1Value = digit1 - asciiZero
          if let digit2 = bytes.next(),
            digit2 >= asciiZero && digit2 <= asciiSeven {
            let digit2Value = digit2 - asciiZero
            let innerSavedPosition = bytes
            if let digit3 = bytes.next(),
              digit3 >= asciiZero && digit3 <= asciiSeven {
              let digit3Value = digit3 - asciiZero
              let n = digit1Value * 64 + digit2Value * 8 + digit3Value
              out.append(n)
            } else {
              let n = digit1Value * 8 + digit2Value
              out.append(n)
              bytes = innerSavedPosition
            }
          } else {
            let n = digit1Value
            out.append(n)
            bytes = savedPosition
          }
        case asciiLowerX: // "x"
          // Unlike C/C++, protobuf only allows 1 or 2 digits here:
          if let byte = bytes.next(), let digit = fromHexDigit(byte) {
            var n = digit
            let savedPosition = bytes
            if let byte = bytes.next(), let digit = fromHexDigit(byte) {
              n = n &* 16 + digit
            } else {
              // No second digit; reset the iterator
              bytes = savedPosition
            }
            out.append(n)
          } else {
            return nil // Hex escape must have at least 1 digit
          }
        case asciiLowerA: // \a
          out.append(asciiBell)
        case asciiLowerB: // \b
          out.append(asciiBackspace)
        case asciiLowerF: // \f
          out.append(asciiFormFeed)
        case asciiLowerN: // \n
          out.append(asciiNewLine)
        case asciiLowerR: // \r
          out.append(asciiCarriageReturn)
        case asciiLowerT: // \t
          out.append(asciiTab)
        case asciiLowerV: // \v
          out.append(asciiVerticalTab)
        case asciiDoubleQuote,
             asciiSingleQuote,
             asciiQuestionMark,
             asciiBackslash: // " ' ? \
          out.append(escaped)
        default:
          return nil // Unrecognized escape
        }
      } else {
        return nil // Input ends with backslash
      }
    default:
      out.append(byte)
    }
  }
  // There has got to be an easier way to convert a [UInt8] into a String.
  return out.withUnsafeBufferPointer { ptr in
    if let addr = ptr.baseAddress {
        return utf8ToString(bytes: addr, count: ptr.count)
    } else {
      return String()
    }
  }
}

///
/// TextFormatScanner has no public members.
///
internal struct TextFormatScanner {
    internal var extensions: ExtensionMap?
    private var p: UnsafeRawPointer
    private var end: UnsafeRawPointer
    private var doubleParser = DoubleParser()

    internal var complete: Bool {
        mutating get {
            return p == end
        }
    }

    internal init(utf8Pointer: UnsafeRawPointer, count: Int, extensions: ExtensionMap? = nil) {
        p = utf8Pointer
        end = p + count
        self.extensions = extensions
        skipWhitespace()
    }

    /// Skip whitespace
    private mutating func skipWhitespace() {
        while p != end {
            let u = p[0]
            switch u {
            case asciiSpace,
                 asciiTab,
                 asciiNewLine,
                 asciiCarriageReturn: // space, tab, NL, CR
                p += 1
            case asciiHash: // # comment
                p += 1
                while p != end {
                    // Skip until end of line
                    let c = p[0]
                    p += 1
                    if c == asciiNewLine || c == asciiCarriageReturn {
                        break
                    }
                }
            default:
                return
            }
        }
    }

    /// Return a buffer containing the raw UTF8 for an identifier.
    /// Assumes that you already know the current byte is a valid
    /// start of identifier.
    private mutating func parseUTF8Identifier() -> UnsafeRawBufferPointer {
        let start = p
        loop: while p != end {
            let c = p[0]
            switch c {
            case asciiLowerA...asciiLowerZ,
                 asciiUpperA...asciiUpperZ,
                 asciiZero...asciiNine,
                 asciiUnderscore:
                p += 1
            default:
                break loop
            }
        }
        let s = UnsafeRawBufferPointer(start: start, count: p - start)
        skipWhitespace()
        return s
    }

    /// Return a String containing the next identifier.
    private mutating func parseIdentifier() -> String {
        let buff = parseUTF8Identifier()
        let s = utf8ToString(bytes: buff.baseAddress!, count: buff.count)
        // Force-unwrap is OK:  we never have invalid UTF8 at this point.
        return s!
    }

    /// Parse the rest of an [extension_field_name] in the input, assuming the
    /// initial "[" character has already been read (and is in the prefix)
    /// This is also used for AnyURL, so we include "/", "."
    private mutating func parseExtensionKey() -> String? {
        let start = p
        if p == end {
            return nil
        }
        let c = p[0]
        switch c {
        case asciiLowerA...asciiLowerZ, asciiUpperA...asciiUpperZ:
            p += 1
        default:
            return nil
        }
        while p != end {
            let c = p[0]
            switch c {
            case asciiLowerA...asciiLowerZ,
                 asciiUpperA...asciiUpperZ,
                 asciiZero...asciiNine,
                 asciiUnderscore,
                 asciiPeriod,
                 asciiForwardSlash:
                p += 1
            case asciiCloseSquareBracket: // ]
                return utf8ToString(bytes: start, count: p - start)
            default:
                return nil
            }
        }
        return nil
    }

    /// Scan a string that encodes a byte field, return a count of
    /// the number of bytes that should be decoded from it
    private mutating func validateAndCountBytesFromString(terminator: UInt8, sawBackslash: inout Bool) throws -> Int {
      var count = 0
      let start = p
      sawBackslash = false
      while p != end {
        let byte = p[0]
        p += 1
        if byte == terminator {
          p = start
          return count
        }
        switch byte {
        case asciiBackslash: //  "\\"
          sawBackslash = true
          if p != end {
            let escaped = p[0]
            p += 1
            switch escaped {
              case asciiZero...asciiSeven: // '0'...'7'
                // C standard allows 1, 2, or 3 octal digits.
                if p != end, p[0] >= asciiZero, p[0] <= asciiSeven {
                  p += 1
                  if p != end, p[0] >= asciiZero, p[0] <= asciiSeven {
                    if escaped > asciiThree {
                       // Out of range octal: three digits and first digit is greater than 3
                      throw TextFormatDecodingError.malformedText
                    }
                    p += 1
                  }
                }
                count += 1
              case asciiLowerX: // 'x' hexadecimal escape
                if p != end && fromHexDigit(p[0]) != nil {
                  p += 1
                  if p != end && fromHexDigit(p[0]) != nil {
                    p += 1
                  }
                } else {
                  throw TextFormatDecodingError.malformedText // Hex escape must have at least 1 digit
                }
                count += 1
              case asciiLowerA, // \a ("alert")
                   asciiLowerB, // \b
                   asciiLowerF, // \f
                   asciiLowerN, // \n
                   asciiLowerR, // \r
                   asciiLowerT, // \t
                   asciiLowerV, // \v
                   asciiSingleQuote, // \'
                   asciiDoubleQuote, // \"
                   asciiQuestionMark, // \?
                   asciiBackslash: // \\
                count += 1
              default:
                throw TextFormatDecodingError.malformedText // Unrecognized escape
            }
          }
        default:
          count += 1
        }
      }
      throw TextFormatDecodingError.malformedText
    }

    /// Protobuf Text format uses C ASCII conventions for
    /// encoding byte sequences, including the use of octal
    /// and hexadecimal escapes.
    ///
    /// Assumes that validateAndCountBytesFromString() has already
    /// verified the correctness.  So we get to avoid error checks here.
    private mutating func parseBytesFromString(terminator: UInt8, into data: inout Data) {
      data.withUnsafeMutableBytes {
        (body: UnsafeMutableRawBufferPointer) in
        if var out = body.baseAddress, body.count > 0 {
          while p[0] != terminator {
            let byte = p[0]
            p += 1
            switch byte {
            case asciiBackslash: //  "\\"
              let escaped = p[0]
              p += 1
              switch escaped {
              case asciiZero...asciiSeven: // '0'...'7'
                // C standard allows 1, 2, or 3 octal digits.
                let digit1Value = escaped - asciiZero
                let digit2 = p[0]
                if digit2 >= asciiZero, digit2 <= asciiSeven {
                  p += 1
                  let digit2Value = digit2 - asciiZero
                  let digit3 = p[0]
                  if digit3 >= asciiZero, digit3 <= asciiSeven {
                    p += 1
                    let digit3Value = digit3 - asciiZero
                    out[0] = digit1Value &* 64 + digit2Value * 8 + digit3Value
                    out += 1
                  } else {
                    out[0] = digit1Value * 8 + digit2Value
                    out += 1
                  }
                } else {
                  out[0] = digit1Value
                  out += 1
                }
              case asciiLowerX: // 'x' hexadecimal escape
                // We already validated, so we know there's at least one digit:
                var n = fromHexDigit(p[0])!
                p += 1
                if let digit = fromHexDigit(p[0]) {
                  n = n &* 16 &+ digit
                  p += 1
                }
                out[0] = n
                out += 1
              case asciiLowerA: // \a ("alert")
                out[0] = asciiBell
                out += 1
              case asciiLowerB: // \b
                out[0] = asciiBackspace
                out += 1
              case asciiLowerF: // \f
                out[0] = asciiFormFeed
                out += 1
              case asciiLowerN: // \n
                out[0] = asciiNewLine
                out += 1
              case asciiLowerR: // \r
                out[0] = asciiCarriageReturn
                out += 1
              case asciiLowerT: // \t
                out[0] = asciiTab
                out += 1
              case asciiLowerV: // \v
                out[0] = asciiVerticalTab
                out += 1
              default:
                out[0] = escaped
                out += 1
              }
            default:
              out[0] = byte
              out += 1
            }
          }
          p += 1 // Consume terminator
        }
      }
    }

    /// Assumes the leading quote has already been consumed
    private mutating func parseStringSegment(terminator: UInt8) -> String? {
        let start = p
        var sawBackslash = false
        while p != end {
            let c = p[0]
            if c == terminator {
                let s = utf8ToString(bytes: start, count: p - start)
                p += 1
                skipWhitespace()
                if let s = s, sawBackslash {
                    return decodeString(s)
                } else {
                    return s
                }
            }
            p += 1
            if c == asciiBackslash { //  \
                if p == end {
                    return nil
                }
                sawBackslash = true
                p += 1
            }
        }
        return nil // Unterminated quoted string
    }

    internal mutating func nextUInt() throws -> UInt64 {
        if p == end {
            throw TextFormatDecodingError.malformedNumber
        }
        let c = p[0]
        p += 1
        if c == asciiZero { // leading '0' precedes octal or hex
            if p[0] == asciiLowerX { // 'x' => hex
                p += 1
                var n: UInt64 = 0
                while p != end {
                    let digit = p[0]
                    let val: UInt64
                    switch digit {
                    case asciiZero...asciiNine: // 0...9
                        val = UInt64(digit - asciiZero)
                    case asciiLowerA...asciiLowerF: // a...f
                        val = UInt64(digit - asciiLowerA + 10)
                    case asciiUpperA...asciiUpperF:
                        val = UInt64(digit - asciiUpperA + 10)
                    case asciiLowerU: // trailing 'u'
                        p += 1
                        skipWhitespace()
                        return n
                    default:
                        skipWhitespace()
                        return n
                    }
                    if n > UInt64.max / 16 {
                        throw TextFormatDecodingError.malformedNumber
                    }
                    p += 1
                    n = n * 16 + val
                }
                skipWhitespace()
                return n
            } else { // octal
                var n: UInt64 = 0
                while p != end {
                    let digit = p[0]
                    if digit == asciiLowerU { // trailing 'u'
                        p += 1
                        skipWhitespace()
                        return n
                    }
                    if digit < asciiZero || digit > asciiSeven {
                        skipWhitespace()
                        return n // not octal digit
                    }
                    let val = UInt64(digit - asciiZero)
                    if n > UInt64.max / 8 {
                        throw TextFormatDecodingError.malformedNumber
                    }
                    p += 1
                    n = n * 8 + val
                }
                skipWhitespace()
                return n
            }
        } else if c > asciiZero && c <= asciiNine { // 1...9
            var n = UInt64(c - asciiZero)
            while p != end {
                let digit = p[0]
                if digit == asciiLowerU { // trailing 'u'
                    p += 1
                    skipWhitespace()
                    return n
                }
                if digit < asciiZero || digit > asciiNine {
                    skipWhitespace()
                    return n // not a digit
                }
                let val = UInt64(digit - asciiZero)
                if n > UInt64.max / 10 || n * 10 > UInt64.max - val {
                    throw TextFormatDecodingError.malformedNumber
                }
                p += 1
                n = n * 10 + val
            }
            skipWhitespace()
            return n
        }
        throw TextFormatDecodingError.malformedNumber
    }

    internal mutating func nextSInt() throws -> Int64 {
        if p == end {
            throw TextFormatDecodingError.malformedNumber
        }
        let c = p[0]
        if c == asciiMinus { // -
            p += 1
            // character after '-' must be digit
            let digit = p[0]
            if digit < asciiZero || digit > asciiNine {
                throw TextFormatDecodingError.malformedNumber
            }
            let n = try nextUInt()
            let limit: UInt64 = 0x8000000000000000 // -Int64.min
            if n >= limit {
                if n > limit {
                    // Too large negative number
                    throw TextFormatDecodingError.malformedNumber
                } else {
                    return Int64.min // Special case for Int64.min
                }
            }
            return -Int64(bitPattern: n)
        } else {
            let n = try nextUInt()
            if n > UInt64(bitPattern: Int64.max) {
                throw TextFormatDecodingError.malformedNumber
            }
            return Int64(bitPattern: n)
        }
    }

    internal mutating func nextStringValue() throws -> String {
        var result: String
        skipWhitespace()
        if p == end {
            throw TextFormatDecodingError.malformedText
        }
        let c = p[0]
        if c != asciiSingleQuote && c != asciiDoubleQuote {
            throw TextFormatDecodingError.malformedText
        }
        p += 1
        if let s = parseStringSegment(terminator: c) {
            result = s
        } else {
            throw TextFormatDecodingError.malformedText
        }

        while true {
            if p == end {
                return result
            }
            let c = p[0]
            if c != asciiSingleQuote && c != asciiDoubleQuote {
                return result
            }
            p += 1
            if let s = parseStringSegment(terminator: c) {
                result.append(s)
            } else {
                throw TextFormatDecodingError.malformedText
            }
        }
    }

    /// Protobuf Text Format allows a single bytes field to
    /// contain multiple quoted strings.  The values
    /// are separately decoded and then concatenated:
    ///  field1: "bytes" 'more bytes'
    ///        "and even more bytes"
    internal mutating func nextBytesValue() throws -> Data {
        // Get the first string's contents
        var result: Data
        skipWhitespace()
        if p == end {
            throw TextFormatDecodingError.malformedText
        }
        let c = p[0]
        if c != asciiSingleQuote && c != asciiDoubleQuote {
            throw TextFormatDecodingError.malformedText
        }
        p += 1
        var sawBackslash = false
        let n = try validateAndCountBytesFromString(terminator: c, sawBackslash: &sawBackslash)
        if sawBackslash {
          result = Data(count: n)
          parseBytesFromString(terminator: c, into: &result)
        } else {
          result = Data(bytes: p, count: n)
          p += n + 1 // Skip string body + close quote
        }

        // If there are more strings, decode them
        // and append to the result:
        while true {
            skipWhitespace()
            if p == end {
                return result
            }
            let c = p[0]
            if c != asciiSingleQuote && c != asciiDoubleQuote {
                return result
            }
            p += 1
            var sawBackslash = false
            let n = try validateAndCountBytesFromString(terminator: c, sawBackslash: &sawBackslash)
            if sawBackslash {
              var b = Data(count: n)
              parseBytesFromString(terminator: c, into: &b)
              result.append(b)
            } else {
              result.append(Data(bytes: p, count: n))
              p += n + 1 // Skip string body + close quote
            }
        }
    }

    // Tries to identify a sequence of UTF8 characters
    // that represent a numeric floating-point value.
    private mutating func tryParseFloatString() -> Double? {
        guard p != end else {return nil}
        let start = p
        var c = p[0]
        if c == asciiMinus {
            p += 1
            guard p != end else {p = start; return nil}
            c = p[0]
        }
        switch c {
        case asciiZero: // '0' as first character is not allowed followed by digit
            p += 1
            guard p != end else {break}
            c = p[0]
            if c >= asciiZero && c <= asciiNine {
                p = start
                return nil
            }
        case asciiPeriod: // '.' as first char only if followed by digit
            p += 1
            guard p != end else {p = start; return nil}
            c = p[0]
            if c < asciiZero || c > asciiNine {
                p = start
                return nil
            }
        case asciiOne...asciiNine:
            break
        default:
            p = start
            return nil
        }
        loop: while p != end {
            let c = p[0]
            switch c {
            case asciiZero...asciiNine,
                 asciiPeriod,
                 asciiPlus,
                 asciiMinus,
                 asciiLowerE,
                 asciiUpperE: // 0...9, ., +, -, e, E
                p += 1
            case asciiLowerF: // f
                // proto1 allowed floats to be suffixed with 'f'
                let d = doubleParser.utf8ToDouble(bytes: UnsafeRawBufferPointer(start: start, count: p - start))
                // Just skip the 'f'
                p += 1
                skipWhitespace()
                return d
            default:
                break loop
            }
        }
        let d = doubleParser.utf8ToDouble(bytes: UnsafeRawBufferPointer(start: start, count: p - start))
        skipWhitespace()
        return d
    }

    // Skip specified characters if they all match
    private mutating func skipOptionalCharacters(bytes: [UInt8]) {
        let start = p
        for b in bytes {
            if p == end || p[0] != b {
                p = start
                return
            }
            p += 1
        }
    }

    // Skip following keyword if it matches (case-insensitively)
    // the given keyword (specified as a series of bytes).
    private mutating func skipOptionalKeyword(bytes: [UInt8]) -> Bool {
        let start = p
        for b in bytes {
            if p == end {
                p = start
                return false
            }
            var c = p[0]
            if c >= asciiUpperA && c <= asciiUpperZ {
                // Convert to lower case
                // (Protobuf text keywords are case insensitive)
                c += asciiLowerA - asciiUpperA
            }
            if c != b {
                p = start
                return false
            }
            p += 1
        }
        if p == end {
            return true
        }
        let c = p[0]
        if ((c >= asciiUpperA && c <= asciiUpperZ)
            || (c >= asciiLowerA && c <= asciiLowerZ)) {
            p = start
            return false
        }
        skipWhitespace()
        return true
    }

    // If the next token is the identifier "nan", return true.
    private mutating func skipOptionalNaN() -> Bool {
        return skipOptionalKeyword(bytes:
                                  [asciiLowerN, asciiLowerA, asciiLowerN])
    }

    // If the next token is a recognized spelling of "infinity",
    // return Float.infinity or -Float.infinity
    private mutating func skipOptionalInfinity() -> Float? {
        if p == end {
            return nil
        }
        let c = p[0]
        let negated: Bool
        if c == asciiMinus {
            negated = true
            p += 1
        } else {
            negated = false
        }
        let inf = [asciiLowerI, asciiLowerN, asciiLowerF]
        let infinity = [asciiLowerI, asciiLowerN, asciiLowerF, asciiLowerI,
                        asciiLowerN, asciiLowerI, asciiLowerT, asciiLowerY]
        if (skipOptionalKeyword(bytes: inf)
            || skipOptionalKeyword(bytes: infinity)) {
            return negated ? -Float.infinity : Float.infinity
        }
        return nil
    }

    internal mutating func nextFloat() throws -> Float {
        if let d = tryParseFloatString() {
            return Float(d)
        }
        if skipOptionalNaN() {
            return Float.nan
        }
        if let inf = skipOptionalInfinity() {
            return inf
        }
        throw TextFormatDecodingError.malformedNumber
    }

    internal mutating func nextDouble() throws -> Double {
        if let d = tryParseFloatString() {
            return d
        }
        if skipOptionalNaN() {
            return Double.nan
        }
        if let inf = skipOptionalInfinity() {
            return Double(inf)
        }
        throw TextFormatDecodingError.malformedNumber
    }

    internal mutating func nextBool() throws -> Bool {
        skipWhitespace()
        if p == end {
            throw TextFormatDecodingError.malformedText
        }
        let c = p[0]
        p += 1
        let result: Bool
        switch c {
        case asciiZero:
            result = false
        case asciiOne:
            result = true
        case asciiLowerF, asciiUpperF:
            if p != end {
                let alse = [asciiLowerA, asciiLowerL, asciiLowerS, asciiLowerE]
                skipOptionalCharacters(bytes: alse)
            }
            result = false
        case asciiLowerT, asciiUpperT:
            if p != end {
                let rue = [asciiLowerR, asciiLowerU, asciiLowerE]
                skipOptionalCharacters(bytes: rue)
            }
            result = true
        default:
            throw TextFormatDecodingError.malformedText
        }
        if p == end {
            return result
        }
        switch p[0] {
        case asciiSpace,
             asciiTab,
             asciiNewLine,
             asciiCarriageReturn,
             asciiHash,
             asciiComma,
             asciiSemicolon,
             asciiCloseSquareBracket,
             asciiCloseCurlyBracket,
             asciiCloseAngleBracket:
            skipWhitespace()
            return result
        default:
            throw TextFormatDecodingError.malformedText
        }
    }

    internal mutating func nextOptionalEnumName() throws -> UnsafeRawBufferPointer? {
        skipWhitespace()
        if p == end {
            throw TextFormatDecodingError.malformedText
        }
        switch p[0] {
        case asciiLowerA...asciiLowerZ, asciiUpperA...asciiUpperZ:
            return parseUTF8Identifier()
        default:
            return nil
        }
    }

    /// Any URLs are syntactically (almost) identical to extension
    /// keys, so we share the code for those.
    internal mutating func nextOptionalAnyURL() throws -> String? {
        return try nextOptionalExtensionKey()
    }

    /// Returns next extension key or nil if end-of-input or
    /// if next token is not an extension key.
    ///
    /// Throws an error if the next token starts with '[' but
    /// cannot be parsed as an extension key.
    ///
    /// Note: This accepts / characters to support Any URL parsing.
    /// Technically, Any URLs can contain / characters and extension
    /// key names cannot.  But in practice, accepting / chracters for
    /// extension keys works fine, since the result just gets rejected
    /// when the key is looked up.
    internal mutating func nextOptionalExtensionKey() throws -> String? {
        skipWhitespace()
        if p == end {
            return nil
        }
        if p[0] == asciiOpenSquareBracket { // [
            p += 1
            if let s = parseExtensionKey() {
                if p == end || p[0] != asciiCloseSquareBracket {
                    throw TextFormatDecodingError.malformedText
                }
                // Skip ]
                p += 1
                skipWhitespace()
                return s
            } else {
                throw TextFormatDecodingError.malformedText
            }
        }
        return nil
    }

    /// Returns text of next regular key or nil if end-of-input.
    /// This considers an extension key [keyname] to be an
    /// error, so call nextOptionalExtensionKey first if you
    /// want to handle extension keys.
    ///
    /// This is only used by map parsing; we should be able to
    /// rework that to use nextFieldNumber instead.
    internal mutating func nextKey() throws -> String? {
        skipWhitespace()
        if p == end {
            return nil
        }
        let c = p[0]
        switch c {
        case asciiOpenSquareBracket: // [
            throw TextFormatDecodingError.malformedText
        case asciiLowerA...asciiLowerZ,
             asciiUpperA...asciiUpperZ,
             asciiOne...asciiNine: // a...z, A...Z, 1...9
            return parseIdentifier()
        default:
            throw TextFormatDecodingError.malformedText
        }
    }

    /// Parse a field name, look it up, and return the corresponding
    /// field number.
    ///
    /// returns nil at end-of-input
    ///
    /// Throws if field name cannot be parsed or if field name is
    /// unknown.
    ///
    /// This function accounts for as much as 2/3 of the total run
    /// time of the entire parse.
    internal mutating func nextFieldNumber(names: _NameMap) throws -> Int? {
        if p == end {
            return nil
        }
        let c = p[0]
        switch c {
        case asciiLowerA...asciiLowerZ,
             asciiUpperA...asciiUpperZ: // a...z, A...Z
            let key = parseUTF8Identifier()
            if let fieldNumber = names.number(forProtoName: key) {
                return fieldNumber
            } else {
                throw TextFormatDecodingError.unknownField
            }
        case asciiOne...asciiNine:  // 1-9 (field numbers are 123, not 0123)
            var fieldNum = Int(c) - Int(asciiZero)
            p += 1
            while p != end {
              let c = p[0]
              if c >= asciiZero && c <= asciiNine {
                fieldNum = fieldNum &* 10 &+ (Int(c) - Int(asciiZero))
              } else {
                break
              }
              p += 1
            }
            skipWhitespace()
            if names.names(for: fieldNum) != nil {
              return fieldNum
            } else {
              // It was a number that isn't a known field.
              // The C++ version (TextFormat::Parser::ParserImpl::ConsumeField()),
              // supports an option to file or skip the field's value (this is true
              // of unknown names or numbers).
              throw TextFormatDecodingError.unknownField
            }
        default:
            break
        }
        throw TextFormatDecodingError.malformedText
    }

    private mutating func skipRequiredCharacter(_ c: UInt8) throws {
        skipWhitespace()
        if p != end && p[0] == c {
            p += 1
            skipWhitespace()
        } else {
            throw TextFormatDecodingError.malformedText
        }
    }

    internal mutating func skipRequiredComma() throws {
        try skipRequiredCharacter(asciiComma)
    }

    internal mutating func skipRequiredColon() throws {
        try skipRequiredCharacter(asciiColon)
    }

    private mutating func skipOptionalCharacter(_ c: UInt8) -> Bool {
        if p != end && p[0] == c {
            p += 1
            skipWhitespace()
            return true
        }
        return false
    }

    internal mutating func skipOptionalColon() -> Bool {
        return skipOptionalCharacter(asciiColon)
    }

    internal mutating func skipOptionalEndArray() -> Bool {
        return skipOptionalCharacter(asciiCloseSquareBracket)
    }

    internal mutating func skipOptionalBeginArray() -> Bool {
        return skipOptionalCharacter(asciiOpenSquareBracket)
    }

    internal mutating func skipOptionalObjectEnd(_ c: UInt8) -> Bool {
        return skipOptionalCharacter(c)
    }

    internal mutating func skipOptionalSeparator() {
        if p != end {
            let c = p[0]
            if c == asciiComma || c == asciiSemicolon { // comma or semicolon
                p += 1
                skipWhitespace()
            }
        }
    }

    /// Returns the character that should end this field.
    /// E.g., if object starts with "{", returns "}"
    internal mutating func skipObjectStart() throws -> UInt8 {
        if p != end {
            let c = p[0]
            p += 1
            skipWhitespace()
            switch c {
            case asciiOpenCurlyBracket: // {
                return asciiCloseCurlyBracket // }
            case asciiOpenAngleBracket: // <
                return asciiCloseAngleBracket // >
            default:
                break
            }
        }
        throw TextFormatDecodingError.malformedText
    }
}
