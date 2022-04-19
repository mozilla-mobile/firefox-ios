// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared
import Account
import Storage
@testable import Sync
import UIKit

import XCTest
import SwiftyJSON

class RecordTests: XCTestCase {
    func testGUIDs() {
        let s = Bytes.generateGUID()
        print("Got GUID: \(s)", terminator: "\n")
        XCTAssertEqual(12, s.lengthOfBytes(using: .utf8))
    }

    func testSwiftyJSONSerializingControlChars() {
        let input = "{\"foo\":\"help \\u000b this\"}"
        let json = JSON(parseJSON: input)
        XCTAssertNil(json.error)
        XCTAssertNil(json.null)
        XCTAssertEqual(input, json.stringify())

        let pairs: [String: Any] = ["foo": "help \(Character(UnicodeScalar(11))) this"]
        let built = JSON(pairs)
        XCTAssertEqual(input, built.stringify())
    }

    func testEnvelopeNullTTL() {
        let p = CleartextPayloadJSON(JSON(["id": "guid"]))
        let r = Record<CleartextPayloadJSON>(id: "guid", payload: p, modified: Date.now(), sortindex: 15, ttl: nil)
        let k = KeyBundle.random()
        let s = keysPayloadSerializer(keyBundle: k, { $0.json })
        let json = s(r)!
        XCTAssertEqual(json["id"].stringValue, "guid")
        XCTAssertTrue(json["ttl"].isNull())
    }

    func testParsedNulls() {
        // Make this a thorough test: use a real-ish blob of JSON.
        // Look to see whether fields with explicit null values match isNull().
        let fullRecord = "{\"id\":\"global\"," +
            "\"payload\":" +
            "\"{\\\"syncID\\\":\\\"zPSQTm7WBVWB\\\"," +
            "\\\"declined\\\":[\\\"bookmarks\\\"]," +
            "\\\"storageVersion\\\":5," +
            "\\\"engines\\\":{" +
            "\\\"clients\\\":{\\\"version\\\":1,\\\"syncID\\\": null}," +
            "\\\"tabs\\\":null}}\"," +
            "\"username\":\"5817483\"," +
        "\"modified\":1.32046073744E9}"

        let record = EnvelopeJSON(fullRecord)
        let bodyJSON = JSON(parseJSON: record.payload)

        XCTAssertTrue(bodyJSON["engines"]["tabs"].isNull())

        let clients = bodyJSON["engines"]["clients"]

        // Make sure we're really getting a value out.
        XCTAssertEqual(clients["version"].int, 1)

        // An explicit null in the input has .type == null, so our .isNull works.
        XCTAssertTrue(clients["syncID"].isNull())

        // Oh, and it's a valid meta/global.
        let global = MetaGlobal.fromJSON(bodyJSON)
        XCTAssertTrue(global != nil)
    }

    func testEnvelopeJSON() {
        let e = EnvelopeJSON(JSON(parseJSON: "{}"))
        XCTAssertFalse(e.isValid())

        let ee = EnvelopeJSON("{\"id\": \"foo\"}")
        XCTAssertFalse(ee.isValid())
        XCTAssertEqual(ee.id, "foo")

        let eee = EnvelopeJSON(JSON(parseJSON: "{\"id\": \"foo\", \"collection\": \"bar\", \"payload\": \"baz\"}"))
        XCTAssertTrue(eee.isValid())
        XCTAssertEqual(eee.id, "foo")
        XCTAssertEqual(eee.collection, "bar")
        XCTAssertEqual(eee.payload, "baz")
    }

    func testRecord() {
        // This is malformed JSON (no closing brace).
        let malformedPayload = "{\"id\": \"abcdefghijkl\", \"collection\": \"clients\", \"payload\": \"in"

        // Invalid: the payload isn't stringified JSON.
        let invalidPayload = "{\"id\": \"abcdefghijkl\", \"collection\": \"clients\", \"payload\": \"invalid\"}"

        // Invalid: the payload is missing a GUID.
        let emptyPayload = "{\"id\": \"abcdefghijkl\", \"collection\": \"clients\", \"payload\": \"{}\"}"

        // This one is invalid because the payload "id" isn't a string.
        // (It'll also fail implicitly because the guid doesn't match the envelope.)
        let badPayloadGUIDPayload: [String: Any] = ["id": 0]
        let badPayloadGUIDPayloadString = JSON(badPayloadGUIDPayload).stringify()!
        let badPayloadGUIDRecord: [String: Any] = ["id": "abcdefghijkl",
                                                   "collection": "clients",
                                                   "payload": badPayloadGUIDPayloadString]
        let badPayloadGUIDRecordString = JSON(badPayloadGUIDRecord).stringify()!

        // This one is invalid because the payload doesn't contain an "id" at all, but it's non-empty.
        // See also `emptyPayload` above.
        // (It'll also fail implicitly because the guid doesn't match the envelope.)
        let noPayloadGUIDPayload: [String: Any] = ["some": "thing"]
        let noPayloadGUIDPayloadString = JSON(noPayloadGUIDPayload).stringify()!
        let noPayloadGUIDRecord: [String: Any] = ["id": "abcdefghijkl",
                                                  "collection": "clients",
                                                  "payload": noPayloadGUIDPayloadString]
        let noPayloadGUIDRecordString = JSON(noPayloadGUIDRecord).stringify()!

        // And this is a valid record.
        let clientBody: [String: Any] = ["id": "abcdefghijkl", "name": "Foobar", "commands": [], "type": "mobile"]
        let clientBodyString = JSON(clientBody).stringify()!
        let clientRecord: [String: Any] = ["id": "abcdefghijkl", "collection": "clients", "payload": clientBodyString]
        let clientPayload = JSON(clientRecord).stringify()!

        let cleartextClientsFactory: (String) -> ClientPayload? = {
            (s: String) -> ClientPayload? in
            return ClientPayload(s)
        }

        let clearFactory: (String) -> CleartextPayloadJSON? = {
            (s: String) -> CleartextPayloadJSON? in
            return CleartextPayloadJSON(s)
        }

        print(clientPayload, terminator: "\n")

        // Non-JSON malformed payloads don't even yield a value.
        XCTAssertNil(Record<CleartextPayloadJSON>.fromEnvelope(EnvelopeJSON(malformedPayload), payloadFactory: clearFactory))

        // Only payloads that parse as JSON objects are valid.
        XCTAssertNil(Record<CleartextPayloadJSON>.fromEnvelope(EnvelopeJSON(invalidPayload), payloadFactory: clearFactory))

        // Missing ID.
        XCTAssertNil(Record<CleartextPayloadJSON>.fromEnvelope(EnvelopeJSON(emptyPayload), payloadFactory: clearFactory))

        // No ID in non-empty payload.
        let noPayloadGUIDEnvelope = EnvelopeJSON(noPayloadGUIDRecordString)

        // The envelope is valid...
        XCTAssertTrue(noPayloadGUIDEnvelope.isValid())

        // ... but the payload is not.
        let noID = Record<CleartextPayloadJSON>.fromEnvelope(noPayloadGUIDEnvelope, payloadFactory: cleartextClientsFactory)
        XCTAssertNil(noID)

        // Non-string ID in payload.
        let badPayloadGUIDEnvelope = EnvelopeJSON(badPayloadGUIDRecordString)

        // The envelope is valid...
        XCTAssertTrue(badPayloadGUIDEnvelope.isValid())

        // ... but the payload is not.
        let badID = Record<CleartextPayloadJSON>.fromEnvelope(badPayloadGUIDEnvelope, payloadFactory: cleartextClientsFactory)
        XCTAssertNil(badID)

        // Only valid ClientPayloads are valid.
        XCTAssertNil(Record<ClientPayload>.fromEnvelope(EnvelopeJSON(invalidPayload), payloadFactory: cleartextClientsFactory))
        XCTAssertTrue(Record<ClientPayload>.fromEnvelope(EnvelopeJSON(clientPayload), payloadFactory: cleartextClientsFactory)!.payload.isValid())
    }

    func testEncryptedClientRecord() {
        let b64E = "0A7mU5SZ/tu7ZqwXW1og4qHVHN+zgEi4Xwfwjw+vEJw="
        let b64H = "11GN34O9QWXkjR06g8t0gWE1sGgQeWL0qxxWwl8Dmxs="

        let expectedGUID = "0-P9fabp9vJD"
        let expectedSortIndex = 131
        let expectedLastModified: Timestamp = 1326254123650

        let inputString = "{\"sortindex\": 131, \"payload\": \"{\\\"ciphertext\\\":\\\"YJB4dr0vZEIWPirfU2FCJvfzeSLiOP5QWasol2R6ILUxdHsJWuUuvTZVhxYQfTVNou6hVV67jfAvi5Cs+bqhhQsv7icZTiZhPTiTdVGt+uuMotxauVA5OryNGVEZgCCTvT3upzhDFdDbJzVd9O3/gU/b7r/CmAHykX8bTlthlbWeZ8oz6gwHJB5tPRU15nM/m/qW1vyKIw5pw/ZwtAy630AieRehGIGDk+33PWqsfyuT4EUFY9/Ly+8JlnqzxfiBCunIfuXGdLuqTjJOxgrK8mI4wccRFEdFEnmHvh5x7fjl1ID52qumFNQl8zkB75C8XK25alXqwvRR6/AQSP+BgQ==\\\",\\\"IV\\\":\\\"v/0BFgicqYQsd70T39rraA==\\\",\\\"hmac\\\":\\\"59605ed696f6e0e6e062a03510cff742bf6b50d695c042e8372a93f4c2d37dac\\\"}\", \"id\": \"0-P9fabp9vJD\", \"modified\": 1326254123.65}"

        let keyBundle = KeyBundle(encKeyB64: b64E, hmacKeyB64: b64H)!
        let decryptClient = keysPayloadFactory(keyBundle: keyBundle, { CleartextPayloadJSON($0) })
        let encryptClient = keysPayloadSerializer(keyBundle: keyBundle, { $0.json }) // It's already a JSON.

        let toRecord = {
            return Record<CleartextPayloadJSON>.fromEnvelope($0, payloadFactory: decryptClient)
        }

        let envelope = EnvelopeJSON(inputString)
        if let r = toRecord(envelope) {
            XCTAssertEqual(r.id, expectedGUID)
            XCTAssertTrue(r.modified == expectedLastModified) //1326254123650
            XCTAssertEqual(r.sortindex, expectedSortIndex)

            if let ee = encryptClient(r) {
                let envelopePrime = EnvelopeJSON(ee)
                XCTAssertEqual(envelopePrime.id, expectedGUID)
                XCTAssertEqual(envelopePrime.id, envelope.id)
                XCTAssertEqual(envelopePrime.sortindex, envelope.sortindex)
                XCTAssertTrue(envelopePrime.modified == 0)

                if let rPrime = toRecord(envelopePrime) {
                    // The payloads should be identical.
                    XCTAssertTrue(rPrime.equalPayloads(r))
                } else {
                    XCTFail("No record.")
                }
            } else {
                XCTFail("No record.")
            }
        } else {
            XCTFail("No record.")
        }

        // Test invalid Base64.
        let badInputString = "{\"sortindex\": 131, \"payload\": \"{\\\"ciphertext\\\":\\\"~~~YJB4dr0vZEIWPirfU2FCJvfzeSLiOP5QWasol2R6ILUxdHsJWuUuvTZVhxYQfTVNou6hVV67jfAvi5Cs+bqhhQsv7icZTiZhPTiTdVGt+uuMotxauVA5OryNGVEZgCCTvT3upzhDFdDbJzVd9O3/gU/b7r/CmAHykX8bTlthlbWeZ8oz6gwHJB5tPRU15nM/m/qW1vyKIw5pw/ZwtAy630AieRehGIGDk+33PWqsfyuT4EUFY9/Ly+8JlnqzxfiBCunIfuXGdLuqTjJOxgrK8mI4wccRFEdFEnmHvh5x7fjl1ID52qumFNQl8zkB75C8XK25alXqwvRR6/AQSP+BgQ==\\\",\\\"IV\\\":\\\"v/0BFgicqYQsd70T39rraA==\\\",\\\"hmac\\\":\\\"59605ed696f6e0e6e062a03510cff742bf6b50d695c042e8372a93f4c2d37dac\\\"}\", \"id\": \"0-P9fabp9vJD\", \"modified\": 1326254123.65}"
        let badEnvelope = EnvelopeJSON(badInputString)
        XCTAssertTrue(badEnvelope.isValid())      // It's a valid envelope containing nonsense ciphertext.
        XCTAssertNil(toRecord(badEnvelope))       // Even though the envelope is valid, the payload is invalid, so we can't construct a record.
    }

    func testMeta() {
        let fullRecord = "{\"id\":\"global\"," +
            "\"payload\":" +
            "\"{\\\"syncID\\\":\\\"zPSQTm7WBVWB\\\"," +
            "\\\"declined\\\":[\\\"bookmarks\\\"]," +
            "\\\"storageVersion\\\":5," +
            "\\\"engines\\\":{" +
            "\\\"clients\\\":{\\\"version\\\":1,\\\"syncID\\\":\\\"fDg0MS5bDtV7\\\"}," +
            "\\\"forms\\\":{\\\"version\\\":1,\\\"syncID\\\":\\\"GXF29AFprnvc\\\"}," +
            "\\\"history\\\":{\\\"version\\\":1,\\\"syncID\\\":\\\"av75g4vm-_rp\\\"}," +
            "\\\"passwords\\\":{\\\"version\\\":1,\\\"syncID\\\":\\\"LT_ACGpuKZ6a\\\"}," +
            "\\\"prefs\\\":{\\\"version\\\":2,\\\"syncID\\\":\\\"-3nsksP9wSAs\\\"}," +
            "\\\"tabs\\\":{\\\"version\\\":1,\\\"syncID\\\":\\\"W4H5lOMChkYA\\\"}}}\"," +
            "\"username\":\"5817483\"," +
            "\"modified\":1.32046073744E9}"

        let record = EnvelopeJSON(fullRecord)
        XCTAssertTrue(record.isValid())

        let global = MetaGlobal.fromJSON(JSON(parseJSON: record.payload))
        XCTAssertTrue(global != nil)

        if let global = global {
            XCTAssertEqual(["bookmarks"], global.declined)
            XCTAssertEqual(5, global.storageVersion)
            let modified = record.modified
            XCTAssertTrue(1320460737440 == modified)
            let forms = global.engines["forms"]
            let syncID = forms!.syncID
            XCTAssertEqual("GXF29AFprnvc", syncID)

            let payload: JSON = global.asPayload().json
            XCTAssertEqual("GXF29AFprnvc", payload["engines"]["forms"]["syncID"].stringValue)
            XCTAssertEqual(1, payload["engines"]["forms"]["version"].intValue)
            XCTAssertEqual("bookmarks", payload["declined"].arrayValue[0].stringValue)
        }
    }

    func testHistoryPayload() {
        let payloadJSON = "{\"id\":\"--DzSJTCw-zb\",\"histUri\":\"https://bugzilla.mozilla.org/show_bug.cgi?id=1154549\",\"title\":\"1154549 – Encapsulate synced profile data within an account-centric object\",\"visits\":[{\"date\":1429061233163240,\"type\":1}]}"
        let json = JSON(parseJSON: payloadJSON)
        if let payload = HistoryPayload.fromJSON(json) {
            XCTAssertEqual("--DzSJTCw-zb", payload["id"].stringValue)
            XCTAssertEqual("1154549 – Encapsulate synced profile data within an account-centric object", payload["title"].stringValue)
            XCTAssertEqual(1, payload.visits[0].type.rawValue)
            XCTAssertEqual(1429061233163240, payload.visits[0].date)

            let v = payload.visits[0]
            let j = v.toJSON()
            XCTAssertEqual(1, j["type"] as! Int)
            XCTAssertEqual(1429061233163240, j["date"] as! Int64)
        } else {
            XCTFail("Should have parsed.")
        }
    }

    func testHistoryPayloadWithNoURL() {
        let payloadJSON = "{\"id\":\"--DzSJTCw-zb\",\"histUri\":null,\"visits\":[{\"date\":1429061233163240,\"type\":1}]}"
        let json = JSON(parseJSON: payloadJSON)
        XCTAssertNil(HistoryPayload.fromJSON(json))
    }

    func testHistoryPayloadWithNoTitle() {
        let payloadJSON = "{\"id\":\"--DzSJTCw-zb\",\"histUri\":\"https://foo.com/\",\"visits\":[{\"date\":1429061233163240,\"type\":1}]}"
        let json = JSON(parseJSON: payloadJSON)
        if let payload = HistoryPayload.fromJSON(json) {
            // Missing fields are null-valued in SwiftyJSON.
            XCTAssertTrue(payload["title"].isNull())
            XCTAssertEqual("", payload.title)
        } else {
            XCTFail("Should have parsed.")
        }
    }

    func testHistoryPayloadWithNullTitle() {
        let payloadJSON = "{\"id\":\"--DzSJTCw-zb\",\"histUri\":\"https://foo.com/\",\"title\":null,\"visits\":[{\"date\":1429061233163240,\"type\":1}]}"
        let json = JSON(parseJSON: payloadJSON)
        if let payload = HistoryPayload.fromJSON(json) {
            XCTAssertEqual("", payload.title)
        } else {
            XCTFail("Should have parsed.")
        }
    }

    func testLoginPayload() {
        let input = JSON([
            "id": "abcdefabcdef",
            "hostname": "http://foo.com/",
            "username": "foo",
            "password": "bar",
            "usernameField": "field",
            "passwordField": "bar",
            // No formSubmitUrl.
            "httpRealm": "",
        ])

        // fromJSON returns nil if not valid.
        XCTAssertNotNil(LoginPayload.fromJSON(input))
    }
}
