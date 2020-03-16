// Sources/SwiftProtobuf/JSONScanner.swift - JSON format decoding
//
// Copyright (c) 2014 - 2019 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// JSON format decoding engine.
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
private let asciiEqualSign = UInt8(ascii: "=")
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
private let asciiUpperI = UInt8(ascii: "I")
private let asciiLowerL = UInt8(ascii: "l")
private let asciiLowerN = UInt8(ascii: "n")
private let asciiUpperN = UInt8(ascii: "N")
private let asciiLowerR = UInt8(ascii: "r")
private let asciiLowerS = UInt8(ascii: "s")
private let asciiLowerT = UInt8(ascii: "t")
private let asciiLowerU = UInt8(ascii: "u")
private let asciiLowerZ = UInt8(ascii: "z")
private let asciiUpperZ = UInt8(ascii: "Z")

private func fromHexDigit(_ c: UnicodeScalar) -> UInt32? {
  let n = c.value
  if n >= 48 && n <= 57 {
    return UInt32(n - 48)
  }
  switch n {
  case 65, 97: return 10
  case 66, 98: return 11
  case 67, 99: return 12
  case 68, 100: return 13
  case 69, 101: return 14
  case 70, 102: return 15
  default:
    return nil
  }
}

// Decode both the RFC 4648 section 4 Base 64 encoding and the RFC
// 4648 section 5 Base 64 variant.  The section 5 variant is also
// known as "base64url" or the "URL-safe alphabet".
// Note that both "-" and "+" decode to 62 and "/" and "_" both
// decode as 63.
let base64Values: [Int] = [
/* 0x00 */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
/* 0x10 */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
/* 0x20 */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 62, -1, 62, -1, 63,
/* 0x30 */ 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, -1, -1, -1,
/* 0x40 */ -1,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
/* 0x50 */ 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, 63,
/* 0x60 */ -1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
/* 0x70 */ 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -1, -1, -1, -1, -1,
/* 0x80 */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
/* 0x90 */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
/* 0xa0 */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
/* 0xb0 */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
/* 0xc0 */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
/* 0xd0 */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
/* 0xe0 */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
/* 0xf0 */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
]

/// Returns a `Data` value containing bytes equivalent to the given
/// Base64-encoded string, or nil if the conversion fails.
///
/// Notes on Google's implementation (Base64Unescape() in strutil.cc):
///  * Google's C++ implementation accepts arbitrary whitespace
///    mixed in with the base-64 characters
///  * Google's C++ implementation ignores missing '=' characters
///    but if present, there must be the exact correct number of them.
///  * The conformance test requires us to accept both standard RFC4648
///    Base 64 encoding and the "URL and Filename Safe Alphabet" variant.
///
private func parseBytes(
  source: UnsafeRawBufferPointer,
  index: inout UnsafeRawBufferPointer.Index,
  end: UnsafeRawBufferPointer.Index
) throws -> Data {
    let c = source[index]
    if c != asciiDoubleQuote {
        throw JSONDecodingError.malformedString
    }
    source.formIndex(after: &index)

    // Count the base-64 digits
    // Ignore most unrecognized characters in this first pass,
    // stop at the closing double quote.
    let digitsStart = index
    var rawChars = 0
    var sawSection4Characters = false
    var sawSection5Characters = false
    while index != end {
        var digit = source[index]
        if digit == asciiDoubleQuote {
            break
        }

        if digit == asciiBackslash {
            source.formIndex(after: &index)
            if index == end {
                throw JSONDecodingError.malformedString
            }
            let escaped = source[index]
            switch escaped {
            case asciiLowerU:
                // TODO: Parse hex escapes such as \u0041.  Note that
                // such escapes are going to be extremely rare, so
                // there's little point in optimizing for them.
                throw JSONDecodingError.malformedString
            case asciiForwardSlash:
                digit = escaped
            default:
                // Reject \b \f \n \r \t \" or \\ and all illegal escapes
                throw JSONDecodingError.malformedString
            }
        }

        if digit == asciiPlus || digit == asciiForwardSlash {
            sawSection4Characters = true
        } else if digit == asciiMinus || digit == asciiUnderscore {
            sawSection5Characters = true
        }
        let k = base64Values[Int(digit)]
        if k >= 0 {
            rawChars += 1
        }
        source.formIndex(after: &index)
    }

    // We reached the end without seeing the close quote
    if index == end {
        throw JSONDecodingError.malformedString
    }
    // Reject mixed encodings.
    if sawSection4Characters && sawSection5Characters {
        throw JSONDecodingError.malformedString
    }

    // Allocate a Data object of exactly the right size
    var value = Data(count: rawChars * 3 / 4)

    // Scan the digits again and populate the Data object.
    // In this pass, we check for (and fail) if there are
    // unexpected characters.  But we don't check for end-of-input,
    // because the loop above already verified that there was
    // a closing double quote.
    index = digitsStart
    try value.withUnsafeMutableBytes {
        (body: UnsafeMutableRawBufferPointer) in
      if var p = body.baseAddress, body.count > 0 {
        var n = 0
        var chars = 0 // # chars in current group
        var padding = 0 // # padding '=' chars
        digits: while true {
            let digit = source[index]
            var k = base64Values[Int(digit)]
            if k < 0 {
                switch digit {
                case asciiDoubleQuote:
                    break digits
                case asciiBackslash:
                    source.formIndex(after: &index)
                    let escaped = source[index]
                    switch escaped {
                    case asciiForwardSlash:
                        k = base64Values[Int(escaped)]
                    default:
                        // Note: Invalid backslash escapes were caught
                        // above; we should never get here.
                        throw JSONDecodingError.malformedString
                    }
                case asciiSpace:
                    source.formIndex(after: &index)
                    continue digits
                case asciiEqualSign: // Count padding
                    while true {
                        switch source[index] {
                        case asciiDoubleQuote:
                            break digits
                        case asciiSpace:
                            break
                        case 61:
                            padding += 1
                        default: // Only '=' and whitespace permitted
                            throw JSONDecodingError.malformedString
                        }
                        source.formIndex(after: &index)
                    }
                default:
                    throw JSONDecodingError.malformedString
                }
            }
            n <<= 6
            n |= k
            chars += 1
            if chars == 4 {
                p[0] = UInt8(truncatingIfNeeded: n >> 16)
                p[1] = UInt8(truncatingIfNeeded: n >> 8)
                p[2] = UInt8(truncatingIfNeeded: n)
                p += 3
                chars = 0
                n = 0
            }
            source.formIndex(after: &index)
        }
        switch chars {
        case 3:
            p[0] = UInt8(truncatingIfNeeded: n >> 10)
            p[1] = UInt8(truncatingIfNeeded: n >> 2)
            if padding == 1 || padding == 0 {
                return
            }
        case 2:
            p[0] = UInt8(truncatingIfNeeded: n >> 4)
            if padding == 2 || padding == 0 {
                return
            }
        case 0:
            if padding == 0 {
                return
            }
        default:
            break
        }
        throw JSONDecodingError.malformedString
      }
    }
    source.formIndex(after: &index)
    return value
}

// JSON encoding allows a variety of \-escapes, including
// escaping UTF-16 code points (which may be surrogate pairs).
private func decodeString(_ s: String) -> String? {
  var out = String.UnicodeScalarView()
  var chars = s.unicodeScalars.makeIterator()
  while let c = chars.next() {
    switch c.value {
    case UInt32(asciiBackslash): // backslash
      if let escaped = chars.next() {
        switch escaped.value {
        case UInt32(asciiLowerU): // "\u"
          // Exactly 4 hex digits:
          if let digit1 = chars.next(),
            let d1 = fromHexDigit(digit1),
            let digit2 = chars.next(),
            let d2 = fromHexDigit(digit2),
            let digit3 = chars.next(),
            let d3 = fromHexDigit(digit3),
            let digit4 = chars.next(),
            let d4 = fromHexDigit(digit4) {
            let codePoint = ((d1 * 16 + d2) * 16 + d3) * 16 + d4
            if let scalar = UnicodeScalar(codePoint) {
              out.append(scalar)
            } else if codePoint < 0xD800 || codePoint >= 0xE000 {
              // Not a valid Unicode scalar.
              return nil
            } else if codePoint >= 0xDC00 {
              // Low surrogate without a preceding high surrogate.
              return nil
            } else {
              // We have a high surrogate (in the range 0xD800..<0xDC00), so
              // verify that it is followed by a low surrogate.
              guard chars.next() == "\\", chars.next() == "u" else {
                // High surrogate was not followed by a Unicode escape sequence.
                return nil
              }
              if let digit1 = chars.next(),
                let d1 = fromHexDigit(digit1),
                let digit2 = chars.next(),
                let d2 = fromHexDigit(digit2),
                let digit3 = chars.next(),
                let d3 = fromHexDigit(digit3),
                let digit4 = chars.next(),
                let d4 = fromHexDigit(digit4) {
                let follower = ((d1 * 16 + d2) * 16 + d3) * 16 + d4
                guard 0xDC00 <= follower && follower < 0xE000 else {
                  // High surrogate was not followed by a low surrogate.
                  return nil
                }
                let high = codePoint - 0xD800
                let low = follower - 0xDC00
                let composed = 0x10000 | high << 10 | low
                guard let composedScalar = UnicodeScalar(composed) else {
                  // Composed value is not a valid Unicode scalar.
                  return nil
                }
                out.append(composedScalar)
              } else {
                // Malformed \u escape for low surrogate
                return nil
              }
            }
          } else {
            // Malformed \u escape
            return nil
          }
        case UInt32(asciiLowerB): // \b
          out.append("\u{08}")
        case UInt32(asciiLowerF): // \f
          out.append("\u{0c}")
        case UInt32(asciiLowerN): // \n
          out.append("\u{0a}")
        case UInt32(asciiLowerR): // \r
          out.append("\u{0d}")
        case UInt32(asciiLowerT): // \t
          out.append("\u{09}")
        case UInt32(asciiDoubleQuote), UInt32(asciiBackslash),
             UInt32(asciiForwardSlash): // " \ /
          out.append(escaped)
        default:
          return nil // Unrecognized escape
        }
      } else {
        return nil // Input ends with backslash
      }
    default:
      out.append(c)
    }
  }
  return String(out)
}

///
/// The basic scanner support is entirely private
///
/// For performance, it works directly against UTF-8 bytes in memory.
///
internal struct JSONScanner {
  private let source: UnsafeRawBufferPointer
  private var index: UnsafeRawBufferPointer.Index
  private var numberParser = DoubleParser()
  internal var recursionLimit: Int
  internal var recursionBudget: Int
  private var ignoreUnknownFields: Bool

  /// True if the scanner has read all of the data from the source, with the
  /// exception of any trailing whitespace (which is consumed by reading this
  /// property).
  internal var complete: Bool {
    mutating get {
      skipWhitespace()
      return !hasMoreContent
    }
  }

  /// True if the scanner has not yet reached the end of the source.
  private var hasMoreContent: Bool {
    return index != source.endIndex
  }

  /// The byte (UTF-8 code unit) at the scanner's current position.
  private var currentByte: UInt8 {
    return source[index]
  }

  internal init(
    source: UnsafeRawBufferPointer,
    messageDepthLimit: Int,
    ignoreUnknownFields: Bool
  ) {
    self.source = source
    self.index = source.startIndex
    self.recursionLimit = messageDepthLimit
    self.recursionBudget = messageDepthLimit
    self.ignoreUnknownFields = ignoreUnknownFields
  }

  private mutating func incrementRecursionDepth() throws {
    recursionBudget -= 1
    if recursionBudget < 0 {
      throw JSONDecodingError.messageDepthLimit
    }
  }

  private mutating func decrementRecursionDepth() {
    recursionBudget += 1
    // This should never happen, if it does, something is probably corrupting memory, and
    // simply throwing doesn't make much sense.
    if recursionBudget > recursionLimit {
      fatalError("Somehow JSONDecoding unwound more objects than it started")
    }
  }

  /// Advances the scanner to the next position in the source.
  private mutating func advance() {
    source.formIndex(after: &index)
  }

  /// Skip whitespace
  private mutating func skipWhitespace() {
    while hasMoreContent {
      let u = currentByte
      switch u {
      case asciiSpace, asciiTab, asciiNewLine, asciiCarriageReturn:
        advance()
      default:
        return
      }
    }
  }

  /// Returns (but does not consume) the next non-whitespace
  /// character.  This is used by google.protobuf.Value, for
  /// example, for custom JSON parsing.
  internal mutating func peekOneCharacter() throws -> Character {
    skipWhitespace()
    guard hasMoreContent else {
      throw JSONDecodingError.truncated
    }
    return Character(UnicodeScalar(UInt32(currentByte))!)
  }

  // Parse the leading UInt64 from the provided utf8 bytes.
  //
  // This is called in three different situations:
  //
  // * Unquoted number.
  //
  // * Simple quoted number.  If a number is quoted but has no
  //   backslashes, the caller can use this directly on the UTF8 by
  //   just verifying the quote marks.  This code returns `nil` if it
  //   sees a backslash, in which case the caller will need to handle ...
  //
  // * Complex quoted number.  In this case, the caller must parse the
  //   quoted value as a string, then convert the string to utf8 and
  //   use this to parse the result.  This is slow but fortunately
  //   rare.
  //
  // In the common case where the number is written in integer form,
  // this code does a simple straight conversion.  If the number is in
  // floating-point format, this uses a slower and less accurate
  // approach: it identifies a substring comprising a float, and then
  // uses Double() and UInt64() to convert that string to an unsigned
  // integer.  In particular, it cannot preserve full 64-bit integer
  // values when they are written in floating-point format.
  //
  // If it encounters a "\" backslash character, it returns a nil.  This
  // is used by callers that are parsing quoted numbers.  See nextSInt()
  // and nextUInt() below.
  private func parseBareUInt64(
    source: UnsafeRawBufferPointer,
    index: inout UnsafeRawBufferPointer.Index,
    end: UnsafeRawBufferPointer.Index
  ) throws -> UInt64? {
    if index == end {
      throw JSONDecodingError.truncated
    }
    let start = index
    let c = source[index]
    switch c {
    case asciiZero: // 0
      source.formIndex(after: &index)
      if index != end {
        let after = source[index]
        switch after {
        case asciiZero...asciiNine: // 0...9
          // leading '0' forbidden unless it is the only digit
          throw JSONDecodingError.leadingZero
        case asciiPeriod, asciiLowerE, asciiUpperE: // . e
          // Slow path: JSON numbers can be written in floating-point notation
          index = start
          if let d = try parseBareDouble(source: source,
                                         index: &index,
                                         end: end) {
            if let u = UInt64(exactly: d) {
              return u
            }
          }
          throw JSONDecodingError.malformedNumber
        case asciiBackslash:
          return nil
        default:
          return 0
        }
      }
      return 0
    case asciiOne...asciiNine: // 1...9
      var n = 0 as UInt64
      while index != end {
        let digit = source[index]
        switch digit {
        case asciiZero...asciiNine: // 0...9
          let val = UInt64(digit - asciiZero)
          if n > UInt64.max / 10 || n * 10 > UInt64.max - val {
            throw JSONDecodingError.numberRange
          }
          source.formIndex(after: &index)
          n = n * 10 + val
        case asciiPeriod, asciiLowerE, asciiUpperE: // . e
          // Slow path: JSON allows floating-point notation for integers
          index = start
          if let d = try parseBareDouble(source: source,
                                         index: &index,
                                         end: end) {
            if let u = UInt64(exactly: d) {
              return u
            }
          }
          throw JSONDecodingError.malformedNumber
        case asciiBackslash:
          return nil
        default:
          return n
        }
      }
      return n
    case asciiBackslash:
      return nil
    default:
      throw JSONDecodingError.malformedNumber
    }
  }

  // Parse the leading Int64 from the provided utf8.
  //
  // This uses parseBareUInt64() to do the heavy lifting;
  // we just check for a leading minus and negate the result
  // as necessary.
  //
  // As with parseBareUInt64(), if it encounters a "\" backslash
  // character, it returns a nil.  This allows callers to use this to
  // do a "fast-path" decode of simple quoted numbers by parsing the
  // UTF8 directly, only falling back to a full String decode when
  // absolutely necessary.
  private func parseBareSInt64(
    source: UnsafeRawBufferPointer,
    index: inout UnsafeRawBufferPointer.Index,
    end: UnsafeRawBufferPointer.Index
  ) throws -> Int64? {
    if index == end {
      throw JSONDecodingError.truncated
    }
    let c = source[index]
    if c == asciiMinus { // -
      source.formIndex(after: &index)
      if index == end {
        throw JSONDecodingError.truncated
      }
      // character after '-' must be digit
      let digit = source[index]
      if digit < asciiZero || digit > asciiNine {
        throw JSONDecodingError.malformedNumber
      }
      if let n = try parseBareUInt64(source: source, index: &index, end: end) {
        let limit: UInt64 = 0x8000000000000000 // -Int64.min
        if n >= limit {
          if n > limit {
            // Too large negative number
            throw JSONDecodingError.numberRange
          } else {
            return Int64.min // Special case for Int64.min
          }
        }
        return -Int64(bitPattern: n)
      } else {
        return nil
      }
    } else if let n = try parseBareUInt64(source: source, index: &index, end: end) {
      if n > UInt64(bitPattern: Int64.max) {
        throw JSONDecodingError.numberRange
      }
      return Int64(bitPattern: n)
    } else {
      return nil
    }
  }

  // Identify a floating-point token in the upcoming UTF8 bytes.
  //
  // This implements the full grammar defined by the JSON RFC 7159.
  // Note that Swift's string-to-number conversions are much more
  // lenient, so this is necessary if we want to accurately reject
  // malformed JSON numbers.
  //
  // This is used by nextDouble() and nextFloat() to parse double and
  // floating-point values, including values that happen to be in quotes.
  // It's also used by the slow path in parseBareSInt64() and parseBareUInt64()
  // above to handle integer values that are written in float-point notation.
  private func parseBareDouble(
    source: UnsafeRawBufferPointer,
    index: inout UnsafeRawBufferPointer.Index,
    end: UnsafeRawBufferPointer.Index
  ) throws -> Double? {
    // RFC 7159 defines the grammar for JSON numbers as:
    // number = [ minus ] int [ frac ] [ exp ]
    if index == end {
      throw JSONDecodingError.truncated
    }
    let start = index
    var c = source[index]
    if c == asciiBackslash {
      return nil
    }

    // Optional leading minus sign
    if c == asciiMinus { // -
      source.formIndex(after: &index)
      if index == end {
        index = start
        throw JSONDecodingError.truncated
      }
      c = source[index]
      if c == asciiBackslash {
        return nil
      }
    } else if c == asciiUpperN { // Maybe NaN?
      // Return nil, let the caller deal with it.
      return nil
    }

    if c == asciiUpperI { // Maybe Infinity, Inf, -Infinity, or -Inf ?
      // Return nil, let the caller deal with it.
      return nil
    }

    // Integer part can be zero or a series of digits not starting with zero
    // int = zero / (digit1-9 *DIGIT)
    switch c {
    case asciiZero:
      // First digit can be zero only if not followed by a digit
      source.formIndex(after: &index)
      if index == end {
        return 0.0
      }
      c = source[index]
      if c == asciiBackslash {
        return nil
      }
      if c >= asciiZero && c <= asciiNine {
        throw JSONDecodingError.leadingZero
      }
    case asciiOne...asciiNine:
      while c >= asciiZero && c <= asciiNine {
        source.formIndex(after: &index)
        if index == end {
          if let d = numberParser.utf8ToDouble(bytes: source, start: start, end: index) {
            return d
          } else {
            throw JSONDecodingError.invalidUTF8
          }
        }
        c = source[index]
        if c == asciiBackslash {
          return nil
        }
      }
    default:
      // Integer part cannot be empty
      throw JSONDecodingError.malformedNumber
    }

    // frac = decimal-point 1*DIGIT
    if c == asciiPeriod {
      source.formIndex(after: &index)
      if index == end {
        // decimal point must have a following digit
        throw JSONDecodingError.truncated
      }
      c = source[index]
      switch c {
      case asciiZero...asciiNine: // 0...9
        while c >= asciiZero && c <= asciiNine {
          source.formIndex(after: &index)
          if index == end {
            if let d = numberParser.utf8ToDouble(bytes: source, start: start, end: index) {
              return d
            } else {
              throw JSONDecodingError.invalidUTF8
            }
          }
          c = source[index]
          if c == asciiBackslash {
            return nil
          }
        }
      case asciiBackslash:
        return nil
      default:
        // decimal point must be followed by at least one digit
        throw JSONDecodingError.malformedNumber
      }
    }

    // exp = e [ minus / plus ] 1*DIGIT
    if c == asciiLowerE || c == asciiUpperE {
      source.formIndex(after: &index)
      if index == end {
        // "e" must be followed by +,-, or digit
        throw JSONDecodingError.truncated
      }
      c = source[index]
      if c == asciiBackslash {
        return nil
      }
      if c == asciiPlus || c == asciiMinus { // + -
        source.formIndex(after: &index)
        if index == end {
          // must be at least one digit in exponent
          throw JSONDecodingError.truncated
        }
        c = source[index]
        if c == asciiBackslash {
          return nil
        }
      }
      switch c {
      case asciiZero...asciiNine:
        while c >= asciiZero && c <= asciiNine {
          source.formIndex(after: &index)
          if index == end {
            if let d = numberParser.utf8ToDouble(bytes: source, start: start, end: index) {
              return d
            } else {
              throw JSONDecodingError.invalidUTF8
            }
          }
          c = source[index]
          if c == asciiBackslash {
            return nil
          }
        }
      default:
        // must be at least one digit in exponent
        throw JSONDecodingError.malformedNumber
      }
    }
    if let d = numberParser.utf8ToDouble(bytes: source, start: start, end: index) {
      return d
    } else {
      throw JSONDecodingError.invalidUTF8
    }
  }

  /// Returns a fully-parsed string with all backslash escapes
  /// correctly processed, or nil if next token is not a string.
  ///
  /// Assumes the leading quote has been verified (but not consumed)
  private mutating func parseOptionalQuotedString() -> String? {
    // Caller has already asserted that currentByte == quote here
    var sawBackslash = false
    advance()
    let start = index
    while hasMoreContent {
      switch currentByte {
      case asciiDoubleQuote: // "
        let s = utf8ToString(bytes: source, start: start, end: index)
        advance()
        if let t = s {
          if sawBackslash {
            return decodeString(t)
          } else {
            return t
          }
        } else {
          return nil // Invalid UTF8
        }
      case asciiBackslash: //  \
        advance()
        guard hasMoreContent else {
          return nil // Unterminated escape
        }
        sawBackslash = true
      default:
        break
      }
      advance()
    }
    return nil // Unterminated quoted string
  }

  /// Parse an unsigned integer, whether or not its quoted.
  /// This also handles cases such as quoted numbers that have
  /// backslash escapes in them.
  ///
  /// This supports the full range of UInt64 (whether quoted or not)
  /// unless the number is written in floating-point format.  In that
  /// case, we decode it with only Double precision.
  internal mutating func nextUInt() throws -> UInt64 {
    skipWhitespace()
    guard hasMoreContent else {
      throw JSONDecodingError.truncated
    }
    let c = currentByte
    if c == asciiDoubleQuote {
      let start = index
      advance()
      if let u = try parseBareUInt64(source: source,
                                     index: &index,
                                     end: source.endIndex) {
        guard hasMoreContent else {
          throw JSONDecodingError.truncated
        }
        if currentByte != asciiDoubleQuote {
          throw JSONDecodingError.malformedNumber
        }
        advance()
        return u
      } else {
        // Couldn't parse because it had a "\" in the string,
        // so parse out the quoted string and then reparse
        // the result to get a UInt
        index = start
        let s = try nextQuotedString()
        let raw = s.data(using: String.Encoding.utf8)!
        let n = try raw.withUnsafeBytes {
          (body: UnsafeRawBufferPointer) -> UInt64? in
          if body.count > 0 {
            var index = body.startIndex
            let end = body.endIndex
            if let u = try parseBareUInt64(source: body,
                                           index: &index,
                                           end: end) {
              if index == end {
                return u
              }
            }
          }
          return nil
        }
        if let n = n {
          return n
        }
      }
    } else if let u = try parseBareUInt64(source: source,
                                          index: &index,
                                          end: source.endIndex) {
      return u
    }
    throw JSONDecodingError.malformedNumber
  }

  /// Parse a signed integer, quoted or not, including handling
  /// backslash escapes for quoted values.
  ///
  /// This supports the full range of Int64 (whether quoted or not)
  /// unless the number is written in floating-point format.  In that
  /// case, we decode it with only Double precision.
  internal mutating func nextSInt() throws -> Int64 {
    skipWhitespace()
    guard hasMoreContent else {
      throw JSONDecodingError.truncated
    }
    let c = currentByte
    if c == asciiDoubleQuote {
      let start = index
      advance()
      if let s = try parseBareSInt64(source: source,
                                     index: &index,
                                     end: source.endIndex) {
        guard hasMoreContent else {
          throw JSONDecodingError.truncated
        }
        if currentByte != asciiDoubleQuote {
          throw JSONDecodingError.malformedNumber
        }
        advance()
        return s
      } else {
        // Couldn't parse because it had a "\" in the string,
        // so parse out the quoted string and then reparse
        // the result as an SInt
        index = start
        let s = try nextQuotedString()
        let raw = s.data(using: String.Encoding.utf8)!
        let n = try raw.withUnsafeBytes {
          (body: UnsafeRawBufferPointer) -> Int64? in
          if body.count > 0 {
            var index = body.startIndex
            let end = body.endIndex
            if let s = try parseBareSInt64(source: body,
                                           index: &index,
                                           end: end) {
              if index == end {
                return s
              }
            }
          }
          return nil
        }
        if let n = n {
          return n
        }
      }
    } else if let s = try parseBareSInt64(source: source,
                                          index: &index,
                                          end: source.endIndex) {
      return s
    }
    throw JSONDecodingError.malformedNumber
  }

  /// Parse the next Float value, regardless of whether it
  /// is quoted, including handling backslash escapes for
  /// quoted strings.
  internal mutating func nextFloat() throws -> Float {
    skipWhitespace()
    guard hasMoreContent else {
      throw JSONDecodingError.truncated
    }
    let c = currentByte
    if c == asciiDoubleQuote { // "
      let start = index
      advance()
      if let d = try parseBareDouble(source: source,
                                     index: &index,
                                     end: source.endIndex) {
        guard hasMoreContent else {
          throw JSONDecodingError.truncated
        }
        if currentByte != asciiDoubleQuote {
          throw JSONDecodingError.malformedNumber
        }
        advance()
        return Float(d)
      } else {
        // Slow Path: parseBareDouble returned nil: It might be
        // a valid float, but had something that
        // parseBareDouble cannot directly handle.  So we reset,
        // try a full string parse, then examine the result:
        index = start
        let s = try nextQuotedString()
        switch s {
        case "NaN": return Float.nan
        case "Inf": return Float.infinity
        case "-Inf": return -Float.infinity
        case "Infinity": return Float.infinity
        case "-Infinity": return -Float.infinity
        default:
          let raw = s.data(using: String.Encoding.utf8)!
          let n = try raw.withUnsafeBytes {
            (body: UnsafeRawBufferPointer) -> Float? in
            if body.count > 0 {
              var index = body.startIndex
              let end = body.endIndex
              if let d = try parseBareDouble(source: body,
                                             index: &index,
                                             end: end) {
                let f = Float(d)
                if index == end && f.isFinite {
                  return f
                }
              }
            }
            return nil
          }
          if let n = n {
            return n
          }
        }
      }
    } else {
      if let d = try parseBareDouble(source: source,
                                     index: &index,
                                     end: source.endIndex) {
        let f = Float(d)
        if f.isFinite {
          return f
        }
      }
    }
    throw JSONDecodingError.malformedNumber
  }

  /// Parse the next Double value, regardless of whether it
  /// is quoted, including handling backslash escapes for
  /// quoted strings.
  internal mutating func nextDouble() throws -> Double {
    skipWhitespace()
    guard hasMoreContent else {
      throw JSONDecodingError.truncated
    }
    let c = currentByte
    if c == asciiDoubleQuote { // "
      let start = index
      advance()
      if let d = try parseBareDouble(source: source,
                                     index: &index,
                                     end: source.endIndex) {
        guard hasMoreContent else {
          throw JSONDecodingError.truncated
        }
        if currentByte != asciiDoubleQuote {
          throw JSONDecodingError.malformedNumber
        }
        advance()
        return d
      } else {
        // Slow Path: parseBareDouble returned nil: It might be
        // a valid float, but had something that
        // parseBareDouble cannot directly handle.  So we reset,
        // try a full string parse, then examine the result:
        index = start
        let s = try nextQuotedString()
        switch s {
        case "NaN": return Double.nan
        case "Inf": return Double.infinity
        case "-Inf": return -Double.infinity
        case "Infinity": return Double.infinity
        case "-Infinity": return -Double.infinity
        default:
          let raw = s.data(using: String.Encoding.utf8)!
          let n = try raw.withUnsafeBytes {
            (body: UnsafeRawBufferPointer) -> Double? in
            if body.count > 0 {
              var index = body.startIndex
              let end = body.endIndex
              if let d = try parseBareDouble(source: body,
                                             index: &index,
                                             end: end) {
                if index == end {
                  return d
                }
              }
            }
            return nil
          }
          if let n = n {
            return n
          }
        }
      }
    } else {
      if let d = try parseBareDouble(source: source,
                                     index: &index,
                                     end: source.endIndex) {
        return d
      }
    }
    throw JSONDecodingError.malformedNumber
  }

  /// Return the contents of the following quoted string,
  /// or throw an error if the next token is not a string.
  internal mutating func nextQuotedString() throws -> String {
    skipWhitespace()
    guard hasMoreContent else {
      throw JSONDecodingError.truncated
    }
    let c = currentByte
    if c != asciiDoubleQuote {
      throw JSONDecodingError.malformedString
    }
    if let s = parseOptionalQuotedString() {
      return s
    } else {
      throw JSONDecodingError.malformedString
    }
  }

  /// Return the contents of the following quoted string,
  /// or nil if the next token is not a string.
  /// This will only throw an error if the next token starts
  /// out as a string but is malformed in some way.
  internal mutating func nextOptionalQuotedString() throws -> String? {
    skipWhitespace()
    guard hasMoreContent else {
      return nil
    }
    let c = currentByte
    if c != asciiDoubleQuote {
      return nil
    }
    return try nextQuotedString()
  }

  /// Return a Data with the decoded contents of the
  /// following base-64 string.
  ///
  /// Notes on Google's implementation:
  ///  * Google's C++ implementation accepts arbitrary whitespace
  ///    mixed in with the base-64 characters
  ///  * Google's C++ implementation ignores missing '=' characters
  ///    but if present, there must be the exact correct number of them.
  ///  * Google's C++ implementation accepts both "regular" and
  ///    "web-safe" base-64 variants (it seems to prefer the
  ///    web-safe version as defined in RFC 4648
  internal mutating func nextBytesValue() throws -> Data {
    skipWhitespace()
    guard hasMoreContent else {
      throw JSONDecodingError.truncated
    }
    return try parseBytes(source: source, index: &index, end: source.endIndex)
  }

  /// Private function to help parse keywords.
  private mutating func skipOptionalKeyword(bytes: [UInt8]) -> Bool {
    let start = index
    for b in bytes {
      guard hasMoreContent else {
        index = start
        return false
      }
      let c = currentByte
      if c != b {
        index = start
        return false
      }
      advance()
    }
    if hasMoreContent {
      let c = currentByte
      if (c >= asciiUpperA && c <= asciiUpperZ) ||
        (c >= asciiLowerA && c <= asciiLowerZ) {
        index = start
        return false
      }
    }
    return true
  }

  /// If the next token is the identifier "null", consume it and return true.
  internal mutating func skipOptionalNull() -> Bool {
    skipWhitespace()
    if hasMoreContent && currentByte == asciiLowerN {
      return skipOptionalKeyword(bytes: [
        asciiLowerN, asciiLowerU, asciiLowerL, asciiLowerL
      ])
    }
    return false
  }

  /// Return the following Bool "true" or "false", including
  /// full processing of quoted boolean values.  (Used in map
  /// keys, for instance.)
  internal mutating func nextBool() throws -> Bool {
    skipWhitespace()
    guard hasMoreContent else {
      throw JSONDecodingError.truncated
    }
    let c = currentByte
    switch c {
    case asciiLowerF: // f
      if skipOptionalKeyword(bytes: [
        asciiLowerF, asciiLowerA, asciiLowerL, asciiLowerS, asciiLowerE
      ]) {
        return false
      }
    case asciiLowerT: // t
      if skipOptionalKeyword(bytes: [
        asciiLowerT, asciiLowerR, asciiLowerU, asciiLowerE
      ]) {
        return true
      }
    default:
      break
    }
    throw JSONDecodingError.malformedBool
  }

  /// Return the following Bool "true" or "false", including
  /// full processing of quoted boolean values.  (Used in map
  /// keys, for instance.)
  internal mutating func nextQuotedBool() throws -> Bool {
    skipWhitespace()
    guard hasMoreContent else {
      throw JSONDecodingError.truncated
    }
    if currentByte != asciiDoubleQuote {
      throw JSONDecodingError.unquotedMapKey
    }
    if let s = parseOptionalQuotedString() {
      switch s {
      case "false": return false
      case "true": return true
      default: break
      }
    }
    throw JSONDecodingError.malformedBool
  }

  /// Returns pointer/count spanning the UTF8 bytes of the next regular
  /// key or nil if the key contains a backslash (and therefore requires
  /// the full string-parsing logic to properly parse).
  private mutating func nextOptionalKey() throws -> UnsafeRawBufferPointer? {
    skipWhitespace()
    let stringStart = index
    guard hasMoreContent else {
      throw JSONDecodingError.truncated
    }
    if currentByte != asciiDoubleQuote {
      return nil
    }
    advance()
    let nameStart = index
    while hasMoreContent && currentByte != asciiDoubleQuote {
      if currentByte == asciiBackslash {
        index = stringStart // Reset to open quote
        return nil
      }
      advance()
    }
    guard hasMoreContent else {
      throw JSONDecodingError.truncated
    }
    let buff = UnsafeRawBufferPointer(
      start: source.baseAddress! + nameStart,
      count: index - nameStart)
    advance()
    return buff
  }

  /// Parse a field name, look it up in the provided field name map,
  /// and return the corresponding field number.
  ///
  /// Throws if field name cannot be parsed.
  /// If it encounters an unknown field name, it silently skips
  /// the value and looks at the following field name.
  internal mutating func nextFieldNumber(names: _NameMap) throws -> Int? {
    while true {
      if let key = try nextOptionalKey() {
        // Fast path:  We parsed it as UTF8 bytes...
        try skipRequiredCharacter(asciiColon) // :
        if let fieldNumber = names.number(forJSONName: key) {
          return fieldNumber
        }
        if !ignoreUnknownFields {
          let fieldName = utf8ToString(bytes: key.baseAddress!, count: key.count)!
          throw JSONDecodingError.unknownField(fieldName)
        }
      } else {
        // Slow path:  We parsed a String; lookups from String are slower.
        let key = try nextQuotedString()
        try skipRequiredCharacter(asciiColon) // :
        if let fieldNumber = names.number(forJSONName: key) {
          return fieldNumber
        }
        if !ignoreUnknownFields {
          throw JSONDecodingError.unknownField(key)
        }
      }
      // Unknown field, skip it and try to parse the next field name
      try skipValue()
      if skipOptionalObjectEnd() {
        return nil
      }
      try skipRequiredComma()
    }
  }

  /// Parse the next token as a string or numeric enum value.  Throws
  /// unrecognizedEnumValue if the string/number can't initialize the
  /// enum.  Will throw other errors if the JSON is malformed.
  internal mutating func nextEnumValue<E: Enum>() throws -> E {
    skipWhitespace()
    guard hasMoreContent else {
        throw JSONDecodingError.truncated
    }
    if currentByte == asciiDoubleQuote {
      if let name = try nextOptionalKey() {
        if let e = E(rawUTF8: name) {
          return e
        } else {
          throw JSONDecodingError.unrecognizedEnumValue
        }
      }
      let name = try nextQuotedString()
      if let e = E(name: name) {
        return e
      } else {
        throw JSONDecodingError.unrecognizedEnumValue
      }
    } else {
      let n = try nextSInt()
      if let i = Int(exactly: n) {
        if let e = E(rawValue: i) {
          return e
        } else {
          throw JSONDecodingError.unrecognizedEnumValue
        }
      } else {
        throw JSONDecodingError.numberRange
      }
    }
  }

  /// Helper for skipping a single-character token.
  private mutating func skipRequiredCharacter(_ required: UInt8) throws {
    skipWhitespace()
    guard hasMoreContent else {
      throw JSONDecodingError.truncated
    }
    let next = currentByte
    if next == required {
      advance()
      return
    }
    throw JSONDecodingError.failure
  }

  /// Skip "{", throw if that's not the next character
  internal mutating func skipRequiredObjectStart() throws {
    try skipRequiredCharacter(asciiOpenCurlyBracket) // {
    try incrementRecursionDepth()
  }

  /// Skip ",", throw if that's not the next character
  internal mutating func skipRequiredComma() throws {
    try skipRequiredCharacter(asciiComma)
  }

  /// Skip ":", throw if that's not the next character
  internal mutating func skipRequiredColon() throws {
    try skipRequiredCharacter(asciiColon)
  }

  /// Skip "[", throw if that's not the next character
  internal mutating func skipRequiredArrayStart() throws {
    try skipRequiredCharacter(asciiOpenSquareBracket) // [
  }

  /// Helper for skipping optional single-character tokens
  private mutating func skipOptionalCharacter(_ c: UInt8) -> Bool {
    skipWhitespace()
    if hasMoreContent && currentByte == c {
      advance()
      return true
    }
    return false
  }

  /// If the next non-whitespace character is "]", skip it
  /// and return true.  Otherwise, return false.
  internal mutating func skipOptionalArrayEnd() -> Bool {
    return skipOptionalCharacter(asciiCloseSquareBracket) // ]
  }

  /// If the next non-whitespace character is "}", skip it
  /// and return true.  Otherwise, return false.
  internal mutating func skipOptionalObjectEnd() -> Bool {
    let result = skipOptionalCharacter(asciiCloseCurlyBracket) // }
    if result {
      decrementRecursionDepth()
    }
    return result
  }

  /// Return the next complete JSON structure as a string.
  /// For example, this might return "true", or "123.456",
  /// or "{\"foo\": 7, \"bar\": [8, 9]}"
  ///
  /// Used by Any to get the upcoming JSON value as a string.
  /// Note: The value might be an object or array.
  internal mutating func skip() throws -> String {
    skipWhitespace()
    let start = index
    try skipValue()
    if let s = utf8ToString(bytes: source, start: start, end: index) {
      return s
    } else {
      throw JSONDecodingError.invalidUTF8
    }
  }

  /// Advance index past the next value.  This is used
  /// by skip() and by unknown field handling.
  private mutating func skipValue() throws {
    skipWhitespace()
    guard hasMoreContent else {
      throw JSONDecodingError.truncated
    }
    switch currentByte {
    case asciiDoubleQuote: // " begins a string
      try skipString()
    case asciiOpenCurlyBracket: // { begins an object
      try skipObject()
    case asciiOpenSquareBracket: // [ begins an array
      try skipArray()
    case asciiLowerN: // n must be null
      if !skipOptionalKeyword(bytes: [
        asciiLowerN, asciiLowerU, asciiLowerL, asciiLowerL
      ]) {
        throw JSONDecodingError.truncated
      }
    case asciiLowerF: // f must be false
      if !skipOptionalKeyword(bytes: [
        asciiLowerF, asciiLowerA, asciiLowerL, asciiLowerS, asciiLowerE
      ]) {
        throw JSONDecodingError.truncated
      }
    case asciiLowerT: // t must be true
      if !skipOptionalKeyword(bytes: [
        asciiLowerT, asciiLowerR, asciiLowerU, asciiLowerE
      ]) {
        throw JSONDecodingError.truncated
      }
    default: // everything else is a number token
      _ = try nextDouble()
    }
  }

  /// Advance the index past the next complete {...} construct.
  private mutating func skipObject() throws {
    try skipRequiredObjectStart()
    if skipOptionalObjectEnd() {
      return
    }
    while true {
      skipWhitespace()
      try skipString()
      try skipRequiredColon()
      try skipValue()
      if skipOptionalObjectEnd() {
        return
      }
      try skipRequiredComma()
    }
  }

  /// Advance the index past the next complete [...] construct.
  private mutating func skipArray() throws {
    try skipRequiredArrayStart()
    if skipOptionalArrayEnd() {
      return
    }
    while true {
      try skipValue()
      if skipOptionalArrayEnd() {
        return
      }
      try skipRequiredComma()
    }
  }

  /// Advance the index past the next complete quoted string.
  ///
  // Caveat:  This does not fully validate; it will accept
  // strings that have malformed \ escapes.
  //
  // It would be nice to do better, but I don't think it's critical,
  // since there are many reasons that strings (and other tokens for
  // that matter) may be skippable but not parseable.  For example:
  // Old clients that don't know new field types will skip fields
  // they don't know; newer clients may reject the same input due to
  // schema mismatches or other issues.
  private mutating func skipString() throws {
    if currentByte != asciiDoubleQuote {
      throw JSONDecodingError.malformedString
    }
    advance()
    while hasMoreContent {
      let c = currentByte
      switch c {
      case asciiDoubleQuote:
        advance()
        return
      case asciiBackslash:
        advance()
        guard hasMoreContent else {
          throw JSONDecodingError.truncated
        }
        advance()
      default:
        advance()
      }
    }
    throw JSONDecodingError.truncated
  }
}
