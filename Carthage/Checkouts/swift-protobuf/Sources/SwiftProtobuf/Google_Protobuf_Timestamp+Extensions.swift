// Sources/SwiftProtobuf/Google_Protobuf_Timestamp+Extensions.swift - Timestamp extensions
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extend the generated Timestamp message with customized JSON coding,
/// arithmetic operations, and convenience methods.
///
// -----------------------------------------------------------------------------

import Foundation

private let minTimestampSeconds: Int64 = -62135596800  // 0001-01-01T00:00:00Z
private let maxTimestampSeconds: Int64 = 253402300799  // 9999-12-31T23:59:59Z

// TODO: Add convenience methods to interoperate with standard
// date/time classes:  an initializer that accepts Unix timestamp as
// Int or Double, an easy way to convert to/from Foundation's
// NSDateTime (on Apple platforms only?), others?


// Parse an RFC3339 timestamp into a pair of seconds-since-1970 and nanos.
private func parseTimestamp(s: String) throws -> (Int64, Int32) {
  // Convert to an array of integer character values
  let value = s.utf8.map{Int($0)}
  if value.count < 20 {
    throw JSONDecodingError.malformedTimestamp
  }
  // Since the format is fixed-layout, we can just decode
  // directly as follows.
  let zero = Int(48)
  let nine = Int(57)
  let dash = Int(45)
  let colon = Int(58)
  let plus = Int(43)
  let letterT = Int(84)
  let letterZ = Int(90)
  let period = Int(46)

  func fromAscii2(_ digit0: Int, _ digit1: Int) throws -> Int {
    if digit0 < zero || digit0 > nine || digit1 < zero || digit1 > nine {
      throw JSONDecodingError.malformedTimestamp
    }
    return digit0 * 10 + digit1 - 528
  }

  func fromAscii4(
    _ digit0: Int,
    _ digit1: Int,
    _ digit2: Int,
    _ digit3: Int
  ) throws -> Int {
    if (digit0 < zero || digit0 > nine
      || digit1 < zero || digit1 > nine
      || digit2 < zero || digit2 > nine
      || digit3 < zero || digit3 > nine) {
      throw JSONDecodingError.malformedTimestamp
    }
    return digit0 * 1000 + digit1 * 100 + digit2 * 10 + digit3 - 53328
  }

  // Year: 4 digits followed by '-'
  let year = try fromAscii4(value[0], value[1], value[2], value[3])
  if value[4] != dash || year < Int(1) || year > Int(9999) {
    throw JSONDecodingError.malformedTimestamp
  }

  // Month: 2 digits followed by '-'
  let month = try fromAscii2(value[5], value[6])
  if value[7] != dash || month < Int(1) || month > Int(12) {
    throw JSONDecodingError.malformedTimestamp
  }

  // Day: 2 digits followed by 'T'
  let mday = try fromAscii2(value[8], value[9])
  if value[10] != letterT || mday < Int(1) || mday > Int(31) {
    throw JSONDecodingError.malformedTimestamp
  }

  // Hour: 2 digits followed by ':'
  let hour = try fromAscii2(value[11], value[12])
  if value[13] != colon || hour > Int(23) {
    throw JSONDecodingError.malformedTimestamp
  }

  // Minute: 2 digits followed by ':'
  let minute = try fromAscii2(value[14], value[15])
  if value[16] != colon || minute > Int(59) {
    throw JSONDecodingError.malformedTimestamp
  }

  // Second: 2 digits (following char is checked below)
  let second = try fromAscii2(value[17], value[18])
  if second > Int(61) {
    throw JSONDecodingError.malformedTimestamp
  }

  // timegm() is almost entirely useless.  It's nonexistent on
  // some platforms, broken on others.  Everything else I've tried
  // is even worse.  Hence the code below.
  // (If you have a better way to do this, try it and see if it
  // passes the test suite on both Linux and OS X.)

  // Day of year
  let mdayStart: [Int] = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
  var yday = Int64(mdayStart[month - 1])
  let isleap = (year % 400 == 0) || ((year % 100 != 0) && (year % 4 == 0))
  if isleap && (month > 2) {
    yday += 1
  }
  yday += Int64(mday - 1)

  // Days since start of epoch (including leap days)
  var daysSinceEpoch = yday
  daysSinceEpoch += Int64(365 * year) - Int64(719527)
  daysSinceEpoch += Int64((year - 1) / 4)
  daysSinceEpoch -= Int64((year - 1) / 100)
  daysSinceEpoch += Int64((year - 1) / 400)

  // Second within day
  var daySec = Int64(hour)
  daySec *= 60
  daySec += Int64(minute)
  daySec *= 60
  daySec += Int64(second)

  // Seconds since start of epoch
  let t = daysSinceEpoch * Int64(86400) + daySec

  // After seconds, comes various optional bits
  var pos = 19

  var nanos: Int32 = 0
  if value[pos] == period { // "." begins fractional seconds
    pos += 1
    var digitValue = 100000000
    while pos < value.count && value[pos] >= zero && value[pos] <= nine {
      nanos += Int32(digitValue * (value[pos] - zero))
      digitValue /= 10
      pos += 1
    }
  }

  var seconds: Int64 = 0
  // "+" or "-" starts Timezone offset
  if value[pos] == plus || value[pos] == dash {
    if pos + 6 > value.count {
      throw JSONDecodingError.malformedTimestamp
    }
    let hourOffset = try fromAscii2(value[pos + 1], value[pos + 2])
    let minuteOffset = try fromAscii2(value[pos + 4], value[pos + 5])
    if hourOffset > Int(13) || minuteOffset > Int(59) || value[pos + 3] != colon {
      throw JSONDecodingError.malformedTimestamp
    }
    var adjusted: Int64 = t
    if value[pos] == plus {
      adjusted -= Int64(hourOffset) * Int64(3600)
      adjusted -= Int64(minuteOffset) * Int64(60)
    } else {
      adjusted += Int64(hourOffset) * Int64(3600)
      adjusted += Int64(minuteOffset) * Int64(60)
    }
    if adjusted < minTimestampSeconds || adjusted > maxTimestampSeconds {
      throw JSONDecodingError.malformedTimestamp
    }
    seconds = adjusted
    pos += 6
  } else if value[pos] == letterZ { // "Z" indicator for UTC
    seconds = t
    pos += 1
  } else {
    throw JSONDecodingError.malformedTimestamp
  }
  if pos != value.count {
    throw JSONDecodingError.malformedTimestamp
  }
  return (seconds, nanos)
}

private func formatTimestamp(seconds: Int64, nanos: Int32) -> String? {
  let (seconds, nanos) = normalizeForTimestamp(seconds: seconds, nanos: nanos)
  guard seconds >= minTimestampSeconds && seconds <= maxTimestampSeconds else {
    return nil
  }

  let (hh, mm, ss) = timeOfDayFromSecondsSince1970(seconds: seconds)
  let (YY, MM, DD) = gregorianDateFromSecondsSince1970(seconds: seconds)

  if nanos == 0 {
    return String(format: "%04d-%02d-%02dT%02d:%02d:%02dZ",
                  YY, MM, DD, hh, mm, ss)
  } else if nanos % 1000000 == 0 {
    return String(format: "%04d-%02d-%02dT%02d:%02d:%02d.%03dZ",
                  YY, MM, DD, hh, mm, ss, nanos / 1000000)
  } else if nanos % 1000 == 0 {
    return String(format: "%04d-%02d-%02dT%02d:%02d:%02d.%06dZ",
                  YY, MM, DD, hh, mm, ss, nanos / 1000)
  } else {
    return String(format: "%04d-%02d-%02dT%02d:%02d:%02d.%09dZ",
                  YY, MM, DD, hh, mm, ss, nanos)
  }
}

extension Google_Protobuf_Timestamp {
  /// Creates a new `Google_Protobuf_Timestamp` equal to the given number of
  /// seconds and nanoseconds.
  ///
  /// - Parameter seconds: The number of seconds.
  /// - Parameter nanos: The number of nanoseconds.
  public init(seconds: Int64 = 0, nanos: Int32 = 0) {
    self.init()
    self.seconds = seconds
    self.nanos = nanos
  }
}

extension Google_Protobuf_Timestamp: _CustomJSONCodable {
  mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
    let s = try decoder.scanner.nextQuotedString()
    (seconds, nanos) = try parseTimestamp(s: s)
  }

  func encodedJSONString(options: JSONEncodingOptions) throws -> String {
    if let formatted = formatTimestamp(seconds: seconds, nanos: nanos) {
      return "\"\(formatted)\""
    } else {
      throw JSONEncodingError.timestampRange
    }
  }
}

extension Google_Protobuf_Timestamp {
  /// Creates a new `Google_Protobuf_Timestamp` initialized relative to 00:00:00
  /// UTC on 1 January 1970 by a given number of seconds.
  ///
  /// - Parameter timeIntervalSince1970: The `TimeInterval`, interpreted as
  ///   seconds relative to 00:00:00 UTC on 1 January 1970.
  public init(timeIntervalSince1970: TimeInterval) {
    let sd = floor(timeIntervalSince1970)
    let nd = round((timeIntervalSince1970 - sd) * TimeInterval(nanosPerSecond))
    let (s, n) = normalizeForTimestamp(seconds: Int64(sd), nanos: Int32(nd))
    self.init(seconds: s, nanos: n)
  }

  /// Creates a new `Google_Protobuf_Timestamp` initialized relative to 00:00:00
  /// UTC on 1 January 2001 by a given number of seconds.
  ///
  /// - Parameter timeIntervalSinceReferenceDate: The `TimeInterval`,
  ///   interpreted as seconds relative to 00:00:00 UTC on 1 January 2001.
  public init(timeIntervalSinceReferenceDate: TimeInterval) {
    let sd = floor(timeIntervalSinceReferenceDate)
    let nd = round(
      (timeIntervalSinceReferenceDate - sd) * TimeInterval(nanosPerSecond))
    // The addition of timeIntervalBetween1970And... is deliberately delayed
    // until the input is separated into an integer part and a fraction
    // part, so that we don't unnecessarily lose precision.
    let (s, n) = normalizeForTimestamp(
      seconds: Int64(sd) + Int64(Date.timeIntervalBetween1970AndReferenceDate),
      nanos: Int32(nd))
    self.init(seconds: s, nanos: n)
  }

  /// Creates a new `Google_Protobuf_Timestamp` initialized to the same time as
  /// the given `Date`.
  ///
  /// - Parameter date: The `Date` with which to initialize the timestamp.
  public init(date: Date) {
    // Note: Internally, Date uses the "reference date," not the 1970 date.
    // We use it when interacting with Dates so that Date doesn't perform
    // any double arithmetic on our behalf, which might cost us precision.
    self.init(
      timeIntervalSinceReferenceDate: date.timeIntervalSinceReferenceDate)
  }

  /// The interval between the timestamp and 00:00:00 UTC on 1 January 1970.
  public var timeIntervalSince1970: TimeInterval {
    return TimeInterval(self.seconds) +
      TimeInterval(self.nanos) / TimeInterval(nanosPerSecond)
  }

  /// The interval between the timestamp and 00:00:00 UTC on 1 January 2001.
  public var timeIntervalSinceReferenceDate: TimeInterval {
    return TimeInterval(
      self.seconds - Int64(Date.timeIntervalBetween1970AndReferenceDate)) +
      TimeInterval(self.nanos) / TimeInterval(nanosPerSecond)
  }

  /// A `Date` initialized to the same time as the timestamp.
  public var date: Date {
    return Date(
      timeIntervalSinceReferenceDate: self.timeIntervalSinceReferenceDate)
  }
}

private func normalizeForTimestamp(
  seconds: Int64,
  nanos: Int32
) -> (seconds: Int64, nanos: Int32) {
  // The Timestamp spec says that nanos must be in the range [0, 999999999),
  // as in actual modular arithmetic.

  let s = seconds + Int64(div(nanos, nanosPerSecond))
  let n = mod(nanos, nanosPerSecond)
  return (seconds: s, nanos: n)
}

public func + (
  lhs: Google_Protobuf_Timestamp,
  rhs: Google_Protobuf_Duration
) -> Google_Protobuf_Timestamp {
  let (s, n) = normalizeForTimestamp(seconds: lhs.seconds + rhs.seconds,
                                     nanos: lhs.nanos + rhs.nanos)
  return Google_Protobuf_Timestamp(seconds: s, nanos: n)
}

public func + (
  lhs: Google_Protobuf_Duration,
  rhs: Google_Protobuf_Timestamp
) -> Google_Protobuf_Timestamp {
  let (s, n) = normalizeForTimestamp(seconds: lhs.seconds + rhs.seconds,
                                     nanos: lhs.nanos + rhs.nanos)
  return Google_Protobuf_Timestamp(seconds: s, nanos: n)
}

public func - (
  lhs: Google_Protobuf_Timestamp,
  rhs: Google_Protobuf_Duration
) -> Google_Protobuf_Timestamp {
  let (s, n) = normalizeForTimestamp(seconds: lhs.seconds - rhs.seconds,
                                     nanos: lhs.nanos - rhs.nanos)
  return Google_Protobuf_Timestamp(seconds: s, nanos: n)
}
