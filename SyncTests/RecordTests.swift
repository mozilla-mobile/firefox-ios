/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import XCTest
import Shared
import Storage
import Sync

class RecordTests: XCTestCase {
    func testGUIDs() {
        let s = Bytes.generateGUID()
        println("Got GUID: \(s)")
        XCTAssertEqual(12, s.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
    }

    func testEnvelopeJSON() {
        let e = EnvelopeJSON(JSON.parse("{}"))
        XCTAssertFalse(e.isValid())
        
        let ee = EnvelopeJSON("{\"id\": \"foo\"}")
        XCTAssertFalse(ee.isValid())
        XCTAssertEqual(ee.id, "foo")
        
        let eee = EnvelopeJSON(JSON.parse("{\"id\": \"foo\", \"collection\": \"bar\", \"payload\": \"baz\"}"))
        XCTAssertTrue(eee.isValid())
        XCTAssertEqual(eee.id, "foo")
        XCTAssertEqual(eee.collection, "bar")
        XCTAssertEqual(eee.payload, "baz")
    }

    func testRecord() {
        let invalidPayload = "{\"id\": \"abcdefghijkl\", \"collection\": \"clients\", \"payload\": \"invalid\"}"
        let emptyPayload = "{\"id\": \"abcdefghijkl\", \"collection\": \"clients\", \"payload\": \"{}\"}"

        let clientBody: [String: AnyObject] = ["name": "Foobar", "commands": [], "type": "mobile"]
        let clientBodyString = JSON(clientBody).toString(pretty: false)
        let clientRecord: [String : AnyObject] = ["id": "abcdefghijkl", "collection": "clients", "payload": clientBodyString]
        let clientPayload = JSON(clientRecord).toString(pretty: false)

        let cleartextClientsFactory: (String) -> ClientPayload? = {
            (s: String) -> ClientPayload? in
            return ClientPayload(s)
        }

        let f: (JSON) -> ClientPayload = {
            j in
            return ClientPayload(j)
        }

        let encoder = RecordEncoder<ClientPayload>(decode: { ClientPayload($0) }, encode: { $0 })
        let encrypter = Keys(defaultBundle: KeyBundle.random()).encrypter("clients", encoder: encoder)
        let ciphertextClientsFactory = encrypter.factory

        let clearFactory: (String) -> CleartextPayloadJSON? = {
            (s: String) -> CleartextPayloadJSON? in
            return CleartextPayloadJSON(s)
        }

        println(clientPayload)

        // Only payloads that parse as JSON are valid.
        XCTAssertNil(Record<CleartextPayloadJSON>.fromEnvelope(EnvelopeJSON(invalidPayload), payloadFactory: clearFactory))
        XCTAssertNotNil(Record<CleartextPayloadJSON>.fromEnvelope(EnvelopeJSON(emptyPayload), payloadFactory: clearFactory))

        // Only valid ClientPayloads are valid.
        XCTAssertNil(Record<ClientPayload>.fromEnvelope(EnvelopeJSON(invalidPayload), payloadFactory: cleartextClientsFactory))
        XCTAssertNotNil(Record<ClientPayload>.fromEnvelope(EnvelopeJSON(clientPayload), payloadFactory: cleartextClientsFactory))
    }

    func testEncryptedClientRecord() {
        let b64E = "0A7mU5SZ/tu7ZqwXW1og4qHVHN+zgEi4Xwfwjw+vEJw="
        let b64H = "11GN34O9QWXkjR06g8t0gWE1sGgQeWL0qxxWwl8Dmxs="
        
        let expectedGUID = "0-P9fabp9vJD"
        let expectedSortIndex = 131
        let expectedLastModified: Timestamp = 1326254123650

        let inputString = "{\"sortindex\": 131, \"payload\": \"{\\\"ciphertext\\\":\\\"YJB4dr0vZEIWPirfU2FCJvfzeSLiOP5QWasol2R6ILUxdHsJWuUuvTZVhxYQfTVNou6hVV67jfAvi5Cs+bqhhQsv7icZTiZhPTiTdVGt+uuMotxauVA5OryNGVEZgCCTvT3upzhDFdDbJzVd9O3/gU/b7r/CmAHykX8bTlthlbWeZ8oz6gwHJB5tPRU15nM/m/qW1vyKIw5pw/ZwtAy630AieRehGIGDk+33PWqsfyuT4EUFY9/Ly+8JlnqzxfiBCunIfuXGdLuqTjJOxgrK8mI4wccRFEdFEnmHvh5x7fjl1ID52qumFNQl8zkB75C8XK25alXqwvRR6/AQSP+BgQ==\\\",\\\"IV\\\":\\\"v/0BFgicqYQsd70T39rraA==\\\",\\\"hmac\\\":\\\"59605ed696f6e0e6e062a03510cff742bf6b50d695c042e8372a93f4c2d37dac\\\"}\", \"id\": \"0-P9fabp9vJD\", \"modified\": 1326254123.65}"

        let keyBundle = KeyBundle(encKeyB64: b64E, hmacKeyB64: b64H)
        let decryptClient = keyBundle.factory({ CleartextPayloadJSON($0) })
        let encryptClient = keyBundle.serializer({ $0 })   // It's already a JSON.

        let toRecord = {
            return Record<CleartextPayloadJSON>.fromEnvelope($0, payloadFactory: decryptClient)
        }

        let envelope = EnvelopeJSON(inputString)
        if let r = toRecord(envelope) {
            XCTAssertEqual(r.id, expectedGUID)
            XCTAssertTrue(r.modified == expectedLastModified)
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

        let record = GlobalEnvelope(fullRecord)
        XCTAssertTrue(record.isValid())

        let global = MetaGlobal.fromPayload(JSON.parse(record.payload))
        XCTAssertTrue(global != nil)

        if let global = global {
            XCTAssertTrue(global.declined != nil)
            XCTAssertTrue(global.engines != nil)
            XCTAssertEqual(["bookmarks"], global.declined!)
            XCTAssertEqual(5, global.storageVersion)
            let modified = record.modified
            XCTAssertTrue(1320460737440 == modified)
            let forms = global.engines!["forms"]
            let syncID = forms!.syncID
            XCTAssertEqual("GXF29AFprnvc", syncID)

            let payload: JSON = global.toPayload()
            XCTAssertEqual("GXF29AFprnvc", payload["engines"]["forms"]["syncID"].asString!)
            XCTAssertEqual(1, payload["engines"]["forms"]["version"].asInt!)
            XCTAssertEqual("bookmarks", payload["declined"].asArray![0].asString!)
        }
    }
}
