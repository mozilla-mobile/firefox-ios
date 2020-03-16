// Tests/SwiftProtobufTests/Test_Any.swift - Verify well-known Any type
//
// Copyright (c) 2014 - 2019 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Any is tricky.  Some of the more interesting cases:
/// * Transcoding protobuf to/from JSON with or without the schema being known
/// * Any fields that contain well-known or user-defined types
/// * Any fields that contain Any fields
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

class Test_Any: XCTestCase {

    func test_Any() throws {
        var content = ProtobufUnittest_TestAllTypes()
        content.optionalInt32 = 7

        var m = ProtobufUnittest_TestAny()
        m.int32Value = 12
        m.anyValue = try Google_Protobuf_Any(message: content)

        // The Any holding an object can be JSON serialized
        XCTAssertNotNil(try m.jsonString())

        let encoded = try m.serializedBytes()
        XCTAssertEqual(encoded, [8, 12, 18, 56, 10, 50, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 112, 114, 111, 116, 111, 98, 117, 102, 95, 117, 110, 105, 116, 116, 101, 115, 116, 46, 84, 101, 115, 116, 65, 108, 108, 84, 121, 112, 101, 115, 18, 2, 8, 7])
        let decoded = try ProtobufUnittest_TestAny(serializedBytes: encoded)
        XCTAssertEqual(decoded.anyValue.typeURL, "type.googleapis.com/protobuf_unittest.TestAllTypes")
        XCTAssertEqual(decoded.anyValue.value, Data([8, 7]))
        XCTAssertEqual(decoded.int32Value, 12)
        XCTAssertNotNil(decoded.anyValue)
        let any = decoded.anyValue
        do {
            let extracted = try ProtobufUnittest_TestAllTypes(unpackingAny: any)
            XCTAssertEqual(extracted.optionalInt32, 7)
        } catch {
            XCTFail("Failed to unpack \(any)")
        }

        XCTAssertThrowsError(try ProtobufUnittest_TestEmptyMessage(unpackingAny: any))
        let recoded = try decoded.serializedBytes()
        XCTAssertEqual(encoded, recoded)
    }

    /// The typeURL prefix should be ignored for purposes of determining the actual type.
    /// The prefix is only used for dynamically loading type data from a remote server
    /// (There are currently no such servers, and no plans to build any.)
    ///
    /// This test verifies that we can decode an Any with a different prefix
    func test_Any_different_prefix() throws {
        let encoded =  Data([8, 12, 18, 40, 10, 34, 88, 47, 89, 47, 112, 114, 111, 116, 111, 98, 117, 102, 95, 117, 110, 105, 116, 116, 101, 115, 116, 46, 84, 101, 115, 116, 65, 108, 108, 84, 121, 112, 101, 115, 18, 2, 8, 7])
        let decoded: ProtobufUnittest_TestAny
        do {
            decoded = try ProtobufUnittest_TestAny(serializedData: encoded)
        } catch {
            XCTFail("Failed to decode \(encoded): \(error)")
            return
        }
        XCTAssertEqual(decoded.anyValue.typeURL, "X/Y/protobuf_unittest.TestAllTypes")
        XCTAssertEqual(decoded.anyValue.value, Data([8, 7]))
        XCTAssertEqual(decoded.int32Value, 12)
        XCTAssertNotNil(decoded.anyValue)
        let any = decoded.anyValue
        do {
            let extracted = try ProtobufUnittest_TestAllTypes(unpackingAny: any)
            XCTAssertEqual(extracted.optionalInt32, 7)
        } catch {
            XCTFail("Failed to unpack \(any)")
        }

        XCTAssertThrowsError(try ProtobufUnittest_TestEmptyMessage(unpackingAny: any))
        let recoded = try decoded.serializedData()
        XCTAssertEqual(encoded, recoded)
    }

    /// The typeURL prefix should be ignored for purposes of determining the actual type.
    /// The prefix is only used for dynamically loading type data from a remote server
    /// (There are currently no such servers, and no plans to build any.)
    ///
    /// This test verifies that we can decode an Any with an empty prefix
    func test_Any_noprefix() throws {
        let encoded =  Data([8, 12, 18, 37, 10, 31, 47, 112, 114, 111, 116, 111, 98, 117, 102, 95, 117, 110, 105, 116, 116, 101, 115, 116, 46, 84, 101, 115, 116, 65, 108, 108, 84, 121, 112, 101, 115, 18, 2, 8, 7])
        let decoded: ProtobufUnittest_TestAny
        do {
            decoded = try ProtobufUnittest_TestAny(serializedData: encoded)
        } catch {
            XCTFail("Failed to decode \(encoded): \(error)")
            return
        }
        XCTAssertEqual(decoded.anyValue.typeURL, "/protobuf_unittest.TestAllTypes")
        XCTAssertEqual(decoded.anyValue.value, Data([8, 7]))
        XCTAssertEqual(decoded.int32Value, 12)
        XCTAssertNotNil(decoded.anyValue)
        let any = decoded.anyValue
        do {
            let extracted = try ProtobufUnittest_TestAllTypes(unpackingAny: any)
            XCTAssertEqual(extracted.optionalInt32, 7)
        } catch {
            XCTFail("Failed to unpack \(any)")
        }

        XCTAssertThrowsError(try ProtobufUnittest_TestEmptyMessage(unpackingAny: any))
        let recoded = try decoded.serializedData()
        XCTAssertEqual(encoded, recoded)
    }

    /// Though Google discourages this, we should be able to match and decode an Any
    /// if the typeURL holds just the type name:
    func test_Any_shortesttype() throws {
        let encoded = Data([8, 12, 18, 36, 10, 30, 112, 114, 111, 116, 111, 98, 117, 102, 95, 117, 110, 105, 116, 116, 101, 115, 116, 46, 84, 101, 115, 116, 65, 108, 108, 84, 121, 112, 101, 115, 18, 2, 8, 7])
        let decoded: ProtobufUnittest_TestAny
        do {
            decoded = try ProtobufUnittest_TestAny(serializedData: encoded)
        } catch {
            XCTFail("Failed to decode \(encoded): \(error)")
            return
        }
        XCTAssertEqual(decoded.anyValue.typeURL, "protobuf_unittest.TestAllTypes")
        XCTAssertEqual(decoded.anyValue.value, Data([8, 7]))
        XCTAssertEqual(decoded.int32Value, 12)
        XCTAssertNotNil(decoded.anyValue)
        let any = decoded.anyValue
        do {
            let extracted = try ProtobufUnittest_TestAllTypes(unpackingAny: any)
            XCTAssertEqual(extracted.optionalInt32, 7)
        } catch {
            XCTFail("Failed to unpack \(any)")
        }

        XCTAssertThrowsError(try ProtobufUnittest_TestEmptyMessage(unpackingAny: any))
        let recoded = try decoded.serializedData()
        XCTAssertEqual(encoded, recoded)
    }

    func test_Any_UserMessage() throws {
        Google_Protobuf_Any.register(messageType: ProtobufUnittest_TestAllTypes.self)
        var content = ProtobufUnittest_TestAllTypes()
        content.optionalInt32 = 7

        var m = ProtobufUnittest_TestAny()
        m.int32Value = 12
        m.anyValue = try Google_Protobuf_Any(message: content)

        let encoded = try m.jsonString()
        XCTAssertEqual(encoded, "{\"int32Value\":12,\"anyValue\":{\"@type\":\"type.googleapis.com/protobuf_unittest.TestAllTypes\",\"optionalInt32\":7}}")
        do {
            let decoded = try ProtobufUnittest_TestAny(jsonString: encoded)
            XCTAssertNotNil(decoded.anyValue)
            XCTAssertEqual(Data([8, 7]), decoded.anyValue.value)
            XCTAssertEqual(decoded.int32Value, 12)
            XCTAssertNotNil(decoded.anyValue)
            let any = decoded.anyValue
            do {
                let extracted = try ProtobufUnittest_TestAllTypes(unpackingAny: any)
                XCTAssertEqual(extracted.optionalInt32, 7)
                XCTAssertThrowsError(try ProtobufUnittest_TestEmptyMessage(unpackingAny: any))
            } catch {
                XCTFail("Failed to unpack \(any)")
            }
            let recoded = try decoded.jsonString()
            XCTAssertEqual(encoded, recoded)
            XCTAssertEqual([8, 12, 18, 56, 10, 50, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 112, 114, 111, 116, 111, 98, 117, 102, 95, 117, 110, 105, 116, 116, 101, 115, 116, 46, 84, 101, 115, 116, 65, 108, 108, 84, 121, 112, 101, 115, 18, 2, 8, 7], try decoded.serializedBytes())
        } catch {
            XCTFail("Failed to decode \(encoded)")
        }
    }

    func test_Any_UnknownUserMessage_JSON() throws {
        Google_Protobuf_Any.register(messageType: ProtobufUnittest_TestAllTypes.self)
        let start = "{\"int32Value\":12,\"anyValue\":{\"@type\":\"type.googleapis.com/UNKNOWN\",\"optionalInt32\":7}}"
        let decoded = try ProtobufUnittest_TestAny(jsonString: start)

        // JSON-to-JSON transcoding succeeds
        let recoded = try decoded.jsonString()
        XCTAssertEqual(recoded, start)

        let anyValue = decoded.anyValue
        XCTAssertNotNil(anyValue)
        XCTAssertEqual(anyValue.typeURL, "type.googleapis.com/UNKNOWN")
        XCTAssertEqual(anyValue.value, Data())

        XCTAssertEqual(anyValue.textFormatString(), "type_url: \"type.googleapis.com/UNKNOWN\"\n#json: \"{\\\"optionalInt32\\\":7}\"\n")

        // Verify:  JSON-to-protobuf transcoding should fail here
        // since the Any does not have type information
        XCTAssertThrowsError(try decoded.serializedBytes())
    }

    func test_Any_UnknownUserMessage_protobuf() throws {
        Google_Protobuf_Any.register(messageType: ProtobufUnittest_TestAllTypes.self)
        let start = Data([8, 12, 18, 33, 10, 27, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 85, 78, 75, 78, 79, 87, 78, 18, 2, 8, 7])

        let decoded = try ProtobufUnittest_TestAny(serializedData: start)

        // Protobuf-to-protobuf transcoding succeeds
        let recoded = try decoded.serializedData()
        XCTAssertEqual(recoded, start)

        let anyValue = decoded.anyValue
        XCTAssertNotNil(anyValue)
        XCTAssertEqual(anyValue.typeURL, "type.googleapis.com/UNKNOWN")
        XCTAssertEqual(anyValue.value, Data([8, 7]))

        XCTAssertEqual(anyValue.textFormatString(), "type_url: \"type.googleapis.com/UNKNOWN\"\nvalue: \"\\b\\007\"\n")

        // Protobuf-to-JSON transcoding fails
        XCTAssertThrowsError(try decoded.jsonString())
    }

    func test_Any_Any() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Any\",\"value\":{\"@type\":\"type.googleapis.com/google.protobuf.Int32Value\",\"value\":1}}}"
        let decoded: ProtobufTestMessages_Proto3_TestAllTypesProto3
        do {
             decoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: start)
        } catch {
            XCTFail("Failed to decode \(start)")
            return
        }
        XCTAssertNotNil(decoded.optionalAny)
        let outerAny = decoded.optionalAny
        do {
            let innerAny = try Google_Protobuf_Any(unpackingAny: outerAny)
            do {
                let value = try Google_Protobuf_Int32Value(unpackingAny: innerAny)
                XCTAssertEqual(value.value, 1)
            } catch {
                XCTFail("Failed to decode innerAny")
                return
            }
        } catch {
            XCTFail("Failed to unpack outerAny \(outerAny): \(error)")
            return
        }

        let protobuf: Data
        do {
            protobuf = try decoded.serializedData()
        } catch {
            XCTFail("Failed to serialize \(decoded)")
            return
        }
        XCTAssertEqual(protobuf, Data([138, 19, 95, 10, 39, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 65, 110, 121, 18, 52, 10, 46, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 73, 110, 116, 51, 50, 86, 97, 108, 117, 101, 18, 2, 8, 1]))

        let redecoded: ProtobufTestMessages_Proto3_TestAllTypesProto3
        do {
            redecoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(serializedData: protobuf)
        } catch {
            XCTFail("Failed to decode \(protobuf)")
            return
        }

        let json: String
        do {
            json = try redecoded.jsonString()
        } catch {
            XCTFail("Failed to recode \(redecoded)")
            return
        }
        XCTAssertEqual(json, start)

        do {
            let recoded = try decoded.jsonString()
            XCTAssertEqual(recoded, start)
        } catch {
            XCTFail("Failed to recode \(start)")
        }
    }

    func test_Any_Duration_JSON_roundtrip() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Duration\",\"value\":\"99.001s\"}}"
        do {
            let decoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: start)

            XCTAssertNotNil(decoded.optionalAny)
            let anyField = decoded.optionalAny
            do {
                let unpacked = try Google_Protobuf_Duration(unpackingAny: anyField)
                XCTAssertEqual(unpacked.seconds, 99)
                XCTAssertEqual(unpacked.nanos, 1000000)
            } catch {
                XCTFail("Failed to unpack \(anyField)")
            }

            let encoded = try decoded.jsonString()
            XCTAssertEqual(encoded, start)
        } catch {
            XCTFail("Failed to decode \(start)")
        }
    }

    func test_Any_Duration_transcode() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Duration\",\"value\":\"99.001s\"}}"
        do {
            let decoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: start)
            let protobuf = try decoded.serializedData()
            XCTAssertEqual(protobuf, Data([138, 19, 54, 10, 44, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 68, 117, 114, 97, 116, 105, 111, 110, 18, 6, 8, 99, 16, 192, 132, 61]))
            do {
                let redecoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(serializedData: protobuf)
                let json = try redecoded.jsonString()
                XCTAssertEqual(json, start)
            } catch let e {
                XCTFail("Failed to redecode \(protobuf): \(e)")
            }
        } catch let e {
            XCTFail("Failed to decode \(start): \(e)")
        }
    }

    func test_Any_FieldMask_JSON_roundtrip() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.FieldMask\",\"value\":\"foo,bar.bazQuux\"}}"
        do {
            let decoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: start)
            XCTAssertNotNil(decoded.optionalAny)
            let anyField = decoded.optionalAny
            do {
                let unpacked = try Google_Protobuf_FieldMask(unpackingAny: anyField)
                XCTAssertEqual(unpacked.paths, ["foo", "bar.baz_quux"])
            } catch {
                XCTFail("Failed to unpack anyField \(anyField)")
            }

            let encoded = try decoded.jsonString()
            XCTAssertEqual(encoded, start)
        } catch {
            XCTFail("Failed to decode \(start)")
        }
    }

    func test_Any_FieldMask_transcode() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.FieldMask\",\"value\":\"foo,bar.bazQuux\"}}"
        do {
            let decoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: start)
            let protobuf = try decoded.serializedData()
            XCTAssertEqual(protobuf, Data([138, 19, 68, 10, 45, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 70, 105, 101, 108, 100, 77, 97, 115, 107, 18, 19, 10, 3, 102, 111, 111, 10, 12, 98, 97, 114, 46, 98, 97, 122, 95, 113, 117, 117, 120]))
            do {
                let redecoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(serializedData: protobuf)
                let json = try redecoded.jsonString()
                XCTAssertEqual(json, start)
            } catch let e {
                XCTFail("Failed to redecode \(protobuf): \(e)")
            }
        } catch let e {
            XCTFail("Failed to decode \(start): \(e)")
        }
    }

    func test_Any_Int32Value_JSON_roundtrip() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Int32Value\",\"value\":1}}"
        do {
            let decoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: start)
            XCTAssertNotNil(decoded.optionalAny)
            let anyField = decoded.optionalAny
            do {
                let unpacked = try Google_Protobuf_Int32Value(unpackingAny: anyField)
                XCTAssertEqual(unpacked.value, 1)
            } catch {
                XCTFail("failed to unpack \(anyField)")
            }

            let encoded = try decoded.jsonString()
            XCTAssertEqual(encoded, start)
        } catch {
            XCTFail("Failed to decode \(start)")
        }
    }

    func test_Any_Int32Value_transcode() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Int32Value\",\"value\":1}}"
        do {
            let decoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: start)
            let protobuf = try decoded.serializedData()
            XCTAssertEqual(protobuf, Data([138, 19, 52, 10, 46, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 73, 110, 116, 51, 50, 86, 97, 108, 117, 101, 18, 2, 8, 1]))
            do {
                let redecoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(serializedData: protobuf)
                let json = try redecoded.jsonString()
                XCTAssertEqual(json, start)
            } catch let e {
                XCTFail("Failed to redecode \(protobuf): \(e)")
            }
        } catch let e {
            XCTFail("Failed to decode \(start): \(e)")
        }
    }

    // TODO: Test remaining XxxValue types

    func test_Any_Struct_JSON_roundtrip() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Struct\",\"value\":{\"foo\":1}}}"
        do {
            let decoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: start)
            XCTAssertNotNil(decoded.optionalAny)
            let anyField = decoded.optionalAny
            do {
                let unpacked = try Google_Protobuf_Struct(unpackingAny: anyField)
                XCTAssertEqual(unpacked.fields["foo"], Google_Protobuf_Value(numberValue:1))
            } catch {
                XCTFail("Failed to unpack \(anyField)")
            }

            let encoded = try decoded.jsonString()
            XCTAssertEqual(encoded, start)
        } catch {
            XCTFail("Failed to decode \(start)")
        }
    }

    func test_Any_Struct_transcode() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Struct\",\"value\":{\"foo\":1.0}}}"
        do {
            let decoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: start)
            let protobuf = try decoded.serializedData()
            XCTAssertEqual(protobuf, Data([138, 19, 64, 10, 42, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 83, 116, 114, 117, 99, 116, 18, 18, 10, 16, 10, 3, 102, 111, 111, 18, 9, 17, 0, 0, 0, 0, 0, 0, 240, 63]))
            do {
                let redecoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(serializedData: protobuf)
                let json = try redecoded.jsonString()
                XCTAssertEqual(json, start)
            } catch let e {
                XCTFail("Redecode failed for \(protobuf): \(e)")
            }
        } catch let e {
            XCTFail("Redecode failed for \(start): \(e)")
        }
    }

    func test_Any_Timestamp_JSON_roundtrip() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Timestamp\",\"value\":\"1970-01-01T00:00:01Z\"}}"
        do {
            let decoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: start)
            XCTAssertNotNil(decoded.optionalAny)
            let anyField = decoded.optionalAny
            do {
                let unpacked = try Google_Protobuf_Timestamp(unpackingAny: anyField)
                XCTAssertEqual(unpacked.seconds, 1)
                XCTAssertEqual(unpacked.nanos, 0)
            } catch {
                XCTFail("Failed to unpack \(anyField)")
            }

            let encoded = try decoded.jsonString()
            XCTAssertEqual(encoded, start)
        } catch {
            XCTFail("Failed to decode \(start)")
        }
    }

    func test_Any_Timestamp_transcode() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Timestamp\",\"value\":\"1970-01-01T00:00:01.000000001Z\"}}"
        do {
            let decoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: start)
            let protobuf = try decoded.serializedData()
            XCTAssertEqual(protobuf, Data([138, 19, 53, 10, 45, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 84, 105, 109, 101, 115, 116, 97, 109, 112, 18, 4, 8, 1, 16, 1]))
            do {
                let redecoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(serializedData: protobuf)
                let json = try redecoded.jsonString()
                XCTAssertEqual(json, start)
            } catch let e {
                XCTFail("Decode failed for \(start): \(e)")
            }
        } catch let e {
            XCTFail("Decode failed for \(start): \(e)")
        }
    }

    func test_Any_ListValue_JSON_roundtrip() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.ListValue\",\"value\":[\"foo\",1]}}"
        do {
            let decoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: start)
            let anyField = decoded.optionalAny
            do {
                let unpacked = try Google_Protobuf_ListValue(unpackingAny: anyField)
                XCTAssertEqual(unpacked.values, [Google_Protobuf_Value(stringValue: "foo"), Google_Protobuf_Value(numberValue: 1)])
            } catch {
                XCTFail("Failed to unpack \(anyField)")
            }

            let encoded = try decoded.jsonString()
            XCTAssertEqual(encoded, start)
        } catch {
            XCTFail("Failed to decode \(start)")
        }
    }

    func test_Any_ListValue_transcode() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.ListValue\",\"value\":[1.0,\"abc\"]}}"
        do {
            let decoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: start)
            let protobuf = try decoded.serializedData()
            XCTAssertEqual(protobuf, Data([138, 19, 67, 10, 45, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 76, 105, 115, 116, 86, 97, 108, 117, 101, 18, 18, 10, 9, 17, 0, 0, 0, 0, 0, 0, 240, 63, 10, 5, 26, 3, 97, 98, 99]))
            do {
                let redecoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(serializedData: protobuf)
                let json = try redecoded.jsonString()
                XCTAssertEqual(json, start)
            } catch let e {
                XCTFail("Redecode failed for \(protobuf): \(e)")
            }
        } catch let e {
            XCTFail("Decode failed for \(start): \(e)")
        }
    }

    func test_Any_Value_struct_JSON_roundtrip() throws {
        // Value holding a JSON Struct
        let start1 = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Value\",\"value\":{\"foo\":1}}}"
        do {
            let decoded1 = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: start1)
            XCTAssertNotNil(decoded1.optionalAny)
            let anyField = decoded1.optionalAny
            XCTAssertThrowsError(try Google_Protobuf_Struct(unpackingAny: anyField))
            do {
                let unpacked = try Google_Protobuf_Value(unpackingAny: anyField)
                XCTAssertEqual(unpacked.structValue.fields["foo"], Google_Protobuf_Value(numberValue:1))
            } catch {
                XCTFail("failed to unpack \(anyField)")
            }

            let encoded1 = try decoded1.jsonString()
            XCTAssertEqual(encoded1, start1)
        } catch {
            XCTFail("Failed to decode \(start1)")
        }
    }

    func test_Any_Value_struct_transcode() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Value\",\"value\":{\"foo\":1.0}}}"
        do {
            let decoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: start)
            let protobuf = try decoded.serializedData()
            XCTAssertEqual(protobuf, Data([138, 19, 65, 10, 41, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 86, 97, 108, 117, 101, 18, 20, 42, 18, 10, 16, 10, 3, 102, 111, 111, 18, 9, 17, 0, 0, 0, 0, 0, 0, 240, 63]))
            do {
                let redecoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(serializedData: protobuf)
                let json = try redecoded.jsonString()
                XCTAssertEqual(json, start)
            } catch let e {
                XCTFail("Decode failed for \(protobuf): \(e)")
            }
        } catch let e {
            XCTFail("Decode failed for \(start): \(e)")
        }
    }

    func test_Any_Value_int_JSON_roundtrip() throws {
        // Value holding an Int
        let start2 = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Value\",\"value\":1}}"
        do {
            let decoded2 = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: start2)
            XCTAssertNotNil(decoded2.optionalAny)
            let anyField = decoded2.optionalAny
            XCTAssertThrowsError(try Google_Protobuf_Struct(unpackingAny: anyField))
            do {
                let unpacked = try Google_Protobuf_Value(unpackingAny: anyField)
                XCTAssertEqual(unpacked.numberValue, 1)
            } catch {
                XCTFail("Failed to unpack \(anyField)")
            }

            let encoded2 = try decoded2.jsonString()
            XCTAssertEqual(encoded2, start2)
        } catch let e {
            XCTFail("Failed to decode \(start2): \(e)")
        }
    }

    func test_Any_Value_int_transcode() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Value\",\"value\":1.0}}"
        do {
            let decoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: start)
            let protobuf = try decoded.serializedData()
            XCTAssertEqual(protobuf, Data([138, 19, 54, 10, 41, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 86, 97, 108, 117, 101, 18, 9, 17, 0, 0, 0, 0, 0, 0, 240, 63]))
            do {
                let redecoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(serializedData: protobuf)
                let json = try redecoded.jsonString()
                XCTAssertEqual(json, start)
            } catch {
                XCTFail("Redecode failed for \(protobuf)")
            }
        } catch {
            XCTFail("Decode failed for \(start)")
        }
    }

    func test_Any_Value_string_JSON_roundtrip() throws {
        // Value holding a String
        let start3 = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Value\",\"value\":\"abc\"}}"
        do {
            let decoded3 = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: start3)
            let anyField = decoded3.optionalAny
            XCTAssertThrowsError(try Google_Protobuf_Struct(unpackingAny: anyField))
            do {
                let unpacked = try Google_Protobuf_Value(unpackingAny: anyField)
                XCTAssertEqual(unpacked.stringValue, "abc")
            } catch {
                XCTFail("Failed to unpack \(anyField)")
            }

            let encoded3 = try decoded3.jsonString()
            XCTAssertEqual(encoded3, start3)
        } catch {
            XCTFail("Failed to decode \(start3)")
        }
    }

    func test_Any_Value_string_transcode() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Value\",\"value\":\"abc\"}}"
        do {
            let decoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(jsonString: start)
            let protobuf = try decoded.serializedData()
            XCTAssertEqual(protobuf, Data([138, 19, 50, 10, 41, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 86, 97, 108, 117, 101, 18, 5, 26, 3, 97, 98, 99]))
            do {
                let redecoded = try ProtobufTestMessages_Proto3_TestAllTypesProto3(serializedData: protobuf)
                let json = try redecoded.jsonString()
                XCTAssertEqual(json, start)
            } catch {
                XCTFail("Redecode failed for \(protobuf)")
            }
        } catch {
            XCTFail("Decode failed for \(start)")
        }
    }

    func test_Any_OddTypeURL_FromValue() throws {
      var msg = ProtobufTestMessages_Proto3_TestAllTypesProto3()
      msg.optionalAny.value = Data([0x1a, 0x03, 0x61, 0x62, 0x63])
      msg.optionalAny.typeURL = "Odd\nType\" prefix/google.protobuf.Value"
      let newJSON = try msg.jsonString()
      XCTAssertEqual(newJSON, "{\"optionalAny\":{\"@type\":\"Odd\\nType\\\" prefix/google.protobuf.Value\",\"value\":\"abc\"}}")
    }

    func test_Any_OddTypeURL_FromMessage() throws {
      let valueMsg = Google_Protobuf_Value.with {
        $0.stringValue = "abc"
      }
      var msg = ProtobufTestMessages_Proto3_TestAllTypesProto3()
      msg.optionalAny = try Google_Protobuf_Any(message: valueMsg, typePrefix: "Odd\nPrefix\"")
      let newJSON = try msg.jsonString()
      XCTAssertEqual(newJSON, "{\"optionalAny\":{\"@type\":\"Odd\\nPrefix\\\"/google.protobuf.Value\",\"value\":\"abc\"}}")
    }

    func test_IsA() {
      var msg = Google_Protobuf_Any()

      msg.typeURL = "type.googleapis.com/protobuf_unittest.TestAllTypes"
      XCTAssertTrue(msg.isA(ProtobufUnittest_TestAllTypes.self))
      XCTAssertFalse(msg.isA(Google_Protobuf_Empty.self))
      msg.typeURL = "random.site.org/protobuf_unittest.TestAllTypes"
      XCTAssertTrue(msg.isA(ProtobufUnittest_TestAllTypes.self))
      XCTAssertFalse(msg.isA(Google_Protobuf_Empty.self))
      msg.typeURL = "/protobuf_unittest.TestAllTypes"
      XCTAssertTrue(msg.isA(ProtobufUnittest_TestAllTypes.self))
      XCTAssertFalse(msg.isA(Google_Protobuf_Empty.self))
      msg.typeURL = "protobuf_unittest.TestAllTypes"
      XCTAssertTrue(msg.isA(ProtobufUnittest_TestAllTypes.self))
      XCTAssertFalse(msg.isA(Google_Protobuf_Empty.self))

      msg.typeURL = ""
      XCTAssertFalse(msg.isA(ProtobufUnittest_TestAllTypes.self))
      XCTAssertFalse(msg.isA(Google_Protobuf_Empty.self))
    }

    func test_Any_Registery() {
      // Registering the same type multiple times is ok.
      XCTAssertTrue(Google_Protobuf_Any.register(messageType: ProtobufUnittestImport_ImportMessage.self))
      XCTAssertTrue(Google_Protobuf_Any.register(messageType: ProtobufUnittestImport_ImportMessage.self))

      // Registering a different type with the same messageName will fail.
      XCTAssertFalse(Google_Protobuf_Any.register(messageType: ConflictingImportMessage.self))

      // Sanity check that the .proto files weren't changed, and they do have the same name.
      XCTAssertEqual(ConflictingImportMessage.protoMessageName, ProtobufUnittestImport_ImportMessage.protoMessageName)

      // Lookup
      XCTAssertTrue(Google_Protobuf_Any.messageType(forMessageName: ProtobufUnittestImport_ImportMessage.protoMessageName) == ProtobufUnittestImport_ImportMessage.self)
      XCTAssertNil(Google_Protobuf_Any.messageType(forMessageName: ProtobufUnittest_TestMap.protoMessageName))

      // All the WKTs should be registered.
      let wkts: [Message.Type] = [
        Google_Protobuf_Any.self,
        Google_Protobuf_BoolValue.self,
        Google_Protobuf_BytesValue.self,
        Google_Protobuf_DoubleValue.self,
        Google_Protobuf_Duration.self,
        Google_Protobuf_Empty.self,
        Google_Protobuf_FieldMask.self,
        Google_Protobuf_FloatValue.self,
        Google_Protobuf_Int32Value.self,
        Google_Protobuf_Int64Value.self,
        Google_Protobuf_ListValue.self,
        Google_Protobuf_StringValue.self,
        Google_Protobuf_Struct.self,
        Google_Protobuf_Timestamp.self,
        Google_Protobuf_UInt32Value.self,
        Google_Protobuf_UInt64Value.self,
        Google_Protobuf_Value.self,
      ]
      for t in wkts {
        XCTAssertTrue(Google_Protobuf_Any.messageType(forMessageName: t.protoMessageName) == t,
                      "Looking up \(t.protoMessageName)")
      }
    }
}

// Dump message class to test registration conflicts

struct ConflictingImportMessage:
    SwiftProtobuf.Message,
    SwiftProtobuf._MessageImplementationBase,
    SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "protobuf_unittest_import.ImportMessage"

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let _ = try decoder.nextFieldNumber() {
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    try unknownFields.traverse(visitor: &visitor)
  }

  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [:]

  func _protobuf_generated_isEqualTo(other: ConflictingImportMessage) -> Bool {
    if unknownFields != other.unknownFields {return false}
    return true
  }
}
