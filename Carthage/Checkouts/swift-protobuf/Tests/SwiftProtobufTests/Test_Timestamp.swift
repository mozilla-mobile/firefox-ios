// Tests/SwiftProtobufTests/Test_Timestamp.swift - VerifyA well-known Timestamp type
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Proto3 defines a standard Timestamp message type that represents a
/// single moment in time with nanosecond precision.  The in-memory form
/// stores a count of seconds since the Unix epoch and a separate count
/// of nanoseconds.  The binary serialized form is unexceptional.  The JSON
/// serialized form represents the time as a string using an ISO8601 variant.
/// The implementation in the runtime library includes a variety of convenience
/// methods to simplify use, including arithmetic operations on timestamps
/// and durations.
///
// -----------------------------------------------------------------------------


import Foundation
import XCTest
import SwiftProtobuf

class Test_Timestamp: XCTestCase, PBTestHelpers {
    typealias MessageTestType = Google_Protobuf_Timestamp

    func testJSON() throws {
        XCTAssertEqual("\"1970-01-01T00:00:00Z\"",
                       try Google_Protobuf_Timestamp().jsonString())

        assertJSONEncode("\"1970-01-01T00:00:01.000000001Z\"") {
            (o: inout MessageTestType) in
            o.seconds = 1 // 1 second
            o.nanos = 1
        }

        assertJSONEncode("\"1970-01-01T00:01:00.000000010Z\"") {
            (o: inout MessageTestType) in
            o.seconds = 60 // 1 minute
            o.nanos = 10
        }

        assertJSONEncode("\"1970-01-01T01:00:00.000000100Z\"") {
            (o: inout MessageTestType) in
            o.seconds = 3600 // 1 hour
            o.nanos = 100
        }

        assertJSONEncode("\"1970-01-02T00:00:00.000001Z\"") {
            (o: inout MessageTestType) in
            o.seconds = 86400 // 1 day
            o.nanos = 1000
        }

        assertJSONEncode("\"1970-02-01T00:00:00.000010Z\"") {
            (o: inout MessageTestType) in
            o.seconds = 2678400 // 1 month
            o.nanos = 10000
        }

        assertJSONEncode("\"1971-01-01T00:00:00.000100Z\"") {
            (o: inout MessageTestType) in
            o.seconds = 31536000 // 1 year
            o.nanos = 100000
        }

        assertJSONEncode("\"1970-01-01T00:00:01.001Z\"") {
            (o: inout MessageTestType) in
            o.seconds = 1
            o.nanos = 1000000
        }

        assertJSONEncode("\"1970-01-01T00:00:01.010Z\"") {
            (o: inout MessageTestType) in
            o.seconds = 1
            o.nanos = 10000000
        }

        assertJSONEncode("\"1970-01-01T00:00:01.100Z\"") {
            (o: inout MessageTestType) in
            o.seconds = 1
            o.nanos = 100000000
        }

        assertJSONEncode("\"1970-01-01T00:00:01Z\"") {
            (o: inout MessageTestType) in
            o.seconds = 1
            o.nanos = 0
        }

        // Largest representable date
        assertJSONEncode("\"9999-12-31T23:59:59.999999999Z\"") {
            (o: inout MessageTestType) in
            o.seconds = 253402300799
            o.nanos = 999999999
        }

        // 10 billion seconds after Epoch
        assertJSONEncode("\"2286-11-20T17:46:40Z\"") {
            (o: inout MessageTestType) in
            o.seconds = 10000000000
            o.nanos = 0
        }

        // 1 billion seconds after Epoch
        assertJSONEncode("\"2001-09-09T01:46:40Z\"") {
            (o: inout MessageTestType) in
            o.seconds = 1000000000
            o.nanos = 0
        }

        // 1 million seconds after Epoch
        assertJSONEncode("\"1970-01-12T13:46:40Z\"") {
            (o: inout MessageTestType) in
            o.seconds = 1000000
            o.nanos = 0
        }

        // 1 thousand seconds after Epoch
        assertJSONEncode("\"1970-01-01T00:16:40Z\"") {
            (o: inout MessageTestType) in
            o.seconds = 1000
            o.nanos = 0
        }

        // 1 thousand seconds before Epoch
        assertJSONEncode("\"1969-12-31T23:43:20Z\"") {
            (o: inout MessageTestType) in
            o.seconds = -1000
            o.nanos = 0
        }

        // 1 million seconds before Epoch
        assertJSONEncode("\"1969-12-20T10:13:20Z\"") {
            (o: inout MessageTestType) in
            o.seconds = -1000000
            o.nanos = 0
        }

        // 1 billion seconds before Epoch
        assertJSONEncode("\"1938-04-24T22:13:20Z\"") {
            (o: inout MessageTestType) in
            o.seconds = -1000000000
            o.nanos = 0
        }

        // 10 billion seconds before Epoch
        assertJSONEncode("\"1653-02-10T06:13:20Z\"") {
            (o: inout MessageTestType) in
            o.seconds = -10000000000
            o.nanos = 0
        }

        // Earliest leap year
        assertJSONEncode("\"0004-02-19T02:50:24Z\"") {
            (o: inout MessageTestType) in
            o.seconds = -62036744976
            o.nanos = 0
        }

        // Earliest representable date
        assertJSONEncode("\"0001-01-01T00:00:00Z\"") {
            (o: inout MessageTestType) in
            o.seconds = -62135596800
            o.nanos = 0
        }
    }

    func testJSON_range() throws {
        // Check that JSON timestamps round-trip correctly over a wide range.
        // This checks about 15,000 dates scattered over a 10,000 year period
        // to verify that our JSON encoder and decoder agree with each other.
        // Combined with the above checks of specific known dates, this gives a
        // pretty high confidence that our date calculations are correct.
        let earliest: Int64 = -62135596800
        let latest: Int64 = 253402300799
        // Use a smaller increment to get more exhaustive testing.  An
        // increment of 12345 will test every single day in the entire
        // 10,000 year range and require about 15 minutes to run.
        // An increment of 12345678 will pick about one day out of
        // every 5 months and require only a few seconds to run.
        let increment: Int64 = 12345678
        var t: Int64 = earliest
        // If things are broken, this test can easily generate >10,000 failures.
        // That many failures can break a lot of tools (Xcode, for example), so
        // we do a little extra work here to only print out the first failure
        // of each type and the total number of failures at the end.
        var encodingFailures = 0
        var decodingFailures = 0
        var roundTripFailures = 0
        while t < latest {
            let start = Google_Protobuf_Timestamp(seconds: t)
            do {
                let encoded = try start.jsonString()
                do {
                    let decoded = try Google_Protobuf_Timestamp(jsonString: encoded)
                    if decoded.seconds != t {
                        if roundTripFailures == 0 {
                            // Only the first round-trip failure will be reported here
                            XCTAssertEqual(decoded.seconds, t, "Round-trip failed for \(encoded): \(t) != \(decoded.seconds)")
                        }
                        roundTripFailures += 1
                    }
                } catch {
                    if decodingFailures == 0 {
                        // Only the first decoding failure will be reported here
                        XCTFail("Could not decode \(encoded)")
                    }
                    decodingFailures += 1
                }
            } catch {
                if encodingFailures == 0 {
                    // Only the first encoding failure will be reported here
                    XCTFail("Could not encode \(start)")
                }
                encodingFailures += 1
            }
            t += increment
        }
        // Report the total number of failures (but silence if there weren't any)
        XCTAssertEqual(encodingFailures, 0)
        XCTAssertEqual(decodingFailures, 0)
        XCTAssertEqual(roundTripFailures, 0)
    }

    func testJSON_timezones() {
        assertJSONDecodeSucceeds("\"1970-01-01T08:00:00+08:00\"") {$0.seconds == 0}
        assertJSONDecodeSucceeds("\"1969-12-31T16:00:00-08:00\"") {$0.seconds == 0}
        assertJSONDecodeFails("\"0001-01-01T00:00:00+23:59\"")
        assertJSONDecodeFails("\"9999-12-31T23:59:59-23:59\"")
    }

    func testJSON_timestampField() throws {
        do {
            let valid = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: "{\"optionalTimestamp\": \"0001-01-01T00:00:00Z\"}")
            XCTAssertEqual(valid.optionalTimestamp, Google_Protobuf_Timestamp(seconds: -62135596800))
        } catch {
            XCTFail("Should have decoded correctly")
        }


        XCTAssertThrowsError(try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: "{\"optionalTimestamp\": \"10000-01-01T00:00:00Z\"}"))
        XCTAssertThrowsError(try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: "{\"optionalTimestamp\": \"0001-01-01T00:00:00\"}"))
        XCTAssertThrowsError(try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: "{\"optionalTimestamp\": \"0001-01-01 00:00:00Z\"}"))
        XCTAssertThrowsError(try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: "{\"optionalTimestamp\": \"0001-01-01T00:00:00z\"}"))
        XCTAssertThrowsError(try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: "{\"optionalTimestamp\": \"0001-01-01t00:00:00Z\"}"))
    }

    // A couple more test cases transcribed from conformance test
    func testJSON_conformance() throws {
        let t1 = Google_Protobuf_Timestamp(seconds: 0, nanos: 10000000)
        var m1 = ProtobufTestMessages_Proto3_TestAllTypesProto3()
        m1.optionalTimestamp = t1
        let expected1 = "{\"optionalTimestamp\":\"1970-01-01T00:00:00.010Z\"}"
        XCTAssertEqual(try m1.jsonString(), expected1)

        let json2 = "{\"optionalTimestamp\": \"1970-01-01T00:00:00.010000000Z\"}"
        let expected2 = "{\"optionalTimestamp\":\"1970-01-01T00:00:00.010Z\"}"
        do {
            let m2 = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: json2)
            do {
                let recoded2 = try m2.jsonString()
                XCTAssertEqual(recoded2, expected2)
            } catch {
                XCTFail()
            }
        } catch {
            XCTFail()
        }

        // Extra spaces around all the tokens.
        let json3 = " { \"repeatedTimestamp\" : [ \"0001-01-01T00:00:00Z\" , \"9999-12-31T23:59:59.999999999Z\" ] } "
        let m3 = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: json3)
        let expected3 = [Google_Protobuf_Timestamp(seconds: -62135596800),
                Google_Protobuf_Timestamp(seconds: 253402300799, nanos: 999999999)]
        XCTAssertEqual(m3.repeatedTimestamp, expected3)
    }

    func testSerializationFailure() throws {
        let maxOutOfRange = Google_Protobuf_Timestamp(seconds:-62135596800, nanos: -1)
        XCTAssertThrowsError(try maxOutOfRange.jsonString())
        let minInRange = Google_Protobuf_Timestamp(seconds:-62135596800)
        XCTAssertNotNil(try minInRange.jsonString())
        let maxInRange = Google_Protobuf_Timestamp(seconds:253402300799, nanos: 999999999)
        XCTAssertNotNil(try maxInRange.jsonString())
        let minOutOfRange = Google_Protobuf_Timestamp(seconds:253402300800)
        XCTAssertThrowsError(try minOutOfRange.jsonString())
    }

    func testBasicArithmetic() throws {
        let tn1_n1 = Google_Protobuf_Timestamp(seconds: -2, nanos: 999999999)
        let t0 = Google_Protobuf_Timestamp()
        let t1_1 = Google_Protobuf_Timestamp(seconds: 1, nanos: 1)
        let t2_2 = Google_Protobuf_Timestamp(seconds: 2, nanos: 2)
        let t3_3 = Google_Protobuf_Timestamp(seconds: 3, nanos: 3)
        let t4_4 = Google_Protobuf_Timestamp(seconds: 4, nanos: 4)

        let dn1_n1 = Google_Protobuf_Duration(seconds: -1, nanos: -1)
        let d0 = Google_Protobuf_Duration()
        let d1_1 = Google_Protobuf_Duration(seconds: 1, nanos: 1)
        let d2_2 = Google_Protobuf_Duration(seconds: 2, nanos: 2)
        let d3_3 = Google_Protobuf_Duration(seconds: 3, nanos: 3)
        let d4_4 = Google_Protobuf_Duration(seconds: 4, nanos: 4)

        // Durations can be added to or subtracted from timestamps
        XCTAssertEqual(t1_1, t0 + d1_1)
        XCTAssertEqual(t1_1, t1_1 + d0)
        XCTAssertEqual(t2_2, t1_1 + d1_1)
        XCTAssertEqual(t3_3, t1_1 + d2_2)
        XCTAssertEqual(t1_1, t4_4 - d3_3)
        XCTAssertEqual(tn1_n1, t3_3 - d4_4)
        XCTAssertEqual(tn1_n1, t3_3 + -d4_4)

        // Difference of two timestamps is a duration
        XCTAssertEqual(d1_1, t4_4 - t3_3)
        XCTAssertEqual(dn1_n1, t3_3 - t4_4)
    }

    func testArithmeticNormalizes() throws {
        // Addition normalizes the result
        let r1: Google_Protobuf_Timestamp = Google_Protobuf_Timestamp() + Google_Protobuf_Duration(seconds: 0, nanos: 2000000001)
        XCTAssertEqual(r1.seconds, 2)
        XCTAssertEqual(r1.nanos, 1)

        // Subtraction normalizes the result
        let r2: Google_Protobuf_Timestamp = Google_Protobuf_Timestamp() - Google_Protobuf_Duration(seconds: 0, nanos: 2000000001)
        XCTAssertEqual(r2.seconds, -3)
        XCTAssertEqual(r2.nanos, 999999999)

        // Subtraction normalizes the result
        let r3: Google_Protobuf_Duration = Google_Protobuf_Timestamp() - Google_Protobuf_Timestamp(seconds: 0, nanos: 2000000001)
        XCTAssertEqual(r3.seconds, -2)
        XCTAssertEqual(r3.nanos, -1)

        let r4: Google_Protobuf_Duration = Google_Protobuf_Timestamp(seconds: 1) - Google_Protobuf_Timestamp(nanos: 2000000001)
        XCTAssertEqual(r4.seconds, -1)
        XCTAssertEqual(r4.nanos, -1)

        let r5: Google_Protobuf_Duration = Google_Protobuf_Timestamp(seconds: -1) - Google_Protobuf_Timestamp(nanos: -2000000001)
        XCTAssertEqual(r5.seconds, 1)
        XCTAssertEqual(r5.nanos, 1)

        let r6: Google_Protobuf_Duration = Google_Protobuf_Timestamp(seconds: -10) - Google_Protobuf_Timestamp(nanos: -2000000001)
        XCTAssertEqual(r6.seconds, -7)
        XCTAssertEqual(r6.nanos, -999999999)

        let r7: Google_Protobuf_Duration = Google_Protobuf_Timestamp(seconds: 10) - Google_Protobuf_Timestamp(nanos: 2000000001)
        XCTAssertEqual(r7.seconds, 7)
        XCTAssertEqual(r7.nanos, 999999999)
    }

    // TODO: Should setter correct for out-of-range
    // nanos and other minor inconsistencies?

    func testInitializationByTimestamps() throws {
        // Negative timestamp
        let t1 = Google_Protobuf_Timestamp(timeIntervalSince1970: -123.456)
        XCTAssertEqual(t1.seconds, -124)
        XCTAssertEqual(t1.nanos, 544000000)

        // Full precision
        let t2 = Google_Protobuf_Timestamp(timeIntervalSince1970: -123.999999999)
        XCTAssertEqual(t2.seconds, -124)
        XCTAssertEqual(t2.nanos, 1)

        // Round up
        let t3 = Google_Protobuf_Timestamp(timeIntervalSince1970: -123.9999999994)
        XCTAssertEqual(t3.seconds, -124)
        XCTAssertEqual(t3.nanos, 1)

        // Round down
        let t4 = Google_Protobuf_Timestamp(timeIntervalSince1970: -123.9999999996)
        XCTAssertEqual(t4.seconds, -124)
        XCTAssertEqual(t4.nanos, 0)

        let t5 = Google_Protobuf_Timestamp(timeIntervalSince1970: 0)
        XCTAssertEqual(t5.seconds, 0)
        XCTAssertEqual(t5.nanos, 0)

        // Positive timestamp
        let t6 = Google_Protobuf_Timestamp(timeIntervalSince1970: 123.456)
        XCTAssertEqual(t6.seconds, 123)
        XCTAssertEqual(t6.nanos, 456000000)

        // Full precision
        let t7 = Google_Protobuf_Timestamp(timeIntervalSince1970: 123.999999999)
        XCTAssertEqual(t7.seconds, 123)
        XCTAssertEqual(t7.nanos, 999999999)

        // Round down
        let t8 = Google_Protobuf_Timestamp(timeIntervalSince1970: 123.9999999994)
        XCTAssertEqual(t8.seconds, 123)
        XCTAssertEqual(t8.nanos, 999999999)

        // Round up
        let t9 = Google_Protobuf_Timestamp(timeIntervalSince1970: 123.9999999996)
        XCTAssertEqual(t9.seconds, 124)
        XCTAssertEqual(t9.nanos, 0)
    }

    func testInitializationByReferenceTimestamp() throws {
        let t1 = Google_Protobuf_Timestamp(timeIntervalSinceReferenceDate: 123.456)
        XCTAssertEqual(t1.seconds, 978307323)
        XCTAssertEqual(t1.nanos, 456000000)
    }

    func testInitializationByDates() throws {
        let t1 = Google_Protobuf_Timestamp(date: Date(timeIntervalSinceReferenceDate: 123.456))
        XCTAssertEqual(t1.seconds, 978307323)
        XCTAssertEqual(t1.nanos, 456000000)
    }

    func testTimestampGetters() throws {
        let t1 = Google_Protobuf_Timestamp(seconds: 12345678, nanos: 12345678)
        XCTAssertEqual(t1.seconds, 12345678)
        XCTAssertEqual(t1.nanos, 12345678)
        XCTAssertEqual(t1.timeIntervalSince1970, 12345678.012345678)
        XCTAssertEqual(t1.timeIntervalSinceReferenceDate, -965961521.987654322)
        let d = t1.date
        XCTAssertEqual(d.timeIntervalSinceReferenceDate, -965961521.987654322)
    }
}
