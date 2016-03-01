/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Storage
@testable import Sync
import UIKit

import XCTest

class RecordTests: XCTestCase {
    func testGUIDs() {
        let s = Bytes.generateGUID()
        print("Got GUID: \(s)", terminator: "\n")
        XCTAssertEqual(12, s.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
    }

    func testEnvelopeNullTTL() {
        let p = CleartextPayloadJSON(JSON([]))
        let r = Record<CleartextPayloadJSON>(id: "guid", payload: p, modified: NSDate.now(), sortindex: 15, ttl: nil)
        let k = KeyBundle.random()
        let s = k.serializer({ $0 })
        let json = s(r)!
        XCTAssertEqual(json["id"].asString!, "guid")
        XCTAssertTrue(json["ttl"].isNull)
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

        let clientBody: [String: AnyObject] = ["id": "abcdefghijkl", "name": "Foobar", "commands": [], "type": "mobile"]
        let clientBodyString = JSON(clientBody).toString(false)
        let clientRecord: [String : AnyObject] = ["id": "abcdefghijkl", "collection": "clients", "payload": clientBodyString]
        let clientPayload = JSON(clientRecord).toString(false)

        let cleartextClientsFactory: (String) -> ClientPayload? = {
            (s: String) -> ClientPayload? in
            return ClientPayload(s)
        }

        let clearFactory: (String) -> CleartextPayloadJSON? = {
            (s: String) -> CleartextPayloadJSON? in
            return CleartextPayloadJSON(s)
        }

        print(clientPayload, terminator: "\n")

        // Only payloads that parse as JSON are valid.
        XCTAssertNil(Record<CleartextPayloadJSON>.fromEnvelope(EnvelopeJSON(invalidPayload), payloadFactory: clearFactory))

        // Missing ID.
        XCTAssertNil(Record<CleartextPayloadJSON>.fromEnvelope(EnvelopeJSON(emptyPayload), payloadFactory: clearFactory))

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

        let record = EnvelopeJSON(fullRecord)
        XCTAssertTrue(record.isValid())

        let global = MetaGlobal.fromJSON(JSON.parse(record.payload))
        XCTAssertTrue(global != nil)

        if let global = global {
            XCTAssertEqual(["bookmarks"], global.declined)
            XCTAssertEqual(5, global.storageVersion)
            let modified = record.modified
            XCTAssertTrue(1320460737440 == modified)
            let forms = global.engines["forms"]
            let syncID = forms!.syncID
            XCTAssertEqual("GXF29AFprnvc", syncID)

            let payload: JSON = global.asPayload()
            XCTAssertEqual("GXF29AFprnvc", payload["engines"]["forms"]["syncID"].asString!)
            XCTAssertEqual(1, payload["engines"]["forms"]["version"].asInt!)
            XCTAssertEqual("bookmarks", payload["declined"].asArray![0].asString!)
        }
    }

    func testHistoryPayload() {
        let payloadJSON = "{\"id\":\"--DzSJTCw-zb\",\"histUri\":\"https://bugzilla.mozilla.org/show_bug.cgi?id=1154549\",\"title\":\"1154549 – Encapsulate synced profile data within an account-centric object\",\"visits\":[{\"date\":1429061233163240,\"type\":1}]}"
        let json = JSON(string: payloadJSON)
        if let payload = HistoryPayload.fromJSON(json) {
            XCTAssertEqual("--DzSJTCw-zb", payload["id"].asString!)
            XCTAssertEqual("1154549 – Encapsulate synced profile data within an account-centric object", payload["title"].asString!)
            XCTAssertEqual(1, payload.visits[0].type.rawValue)
            XCTAssertEqual(1429061233163240, payload.visits[0].date)

            let v = payload.visits[0]
            let j = v.toJSON()
            XCTAssertEqual(1, j["type"].asInt!)
            XCTAssertEqual(1429061233163240, j["date"].asInt64!)
        } else {
            XCTFail("Should have parsed.")
        }
    }

    func testHistoryPayloadWithNoTitle() {
        let payloadJSON = "{\"id\":\"--DzSJTCw-zb\",\"histUri\":\"https://foo.com/\",\"title\":null,\"visits\":[{\"date\":1429061233163240,\"type\":1}]}"
        let json = JSON(string: payloadJSON)
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
            // No formSubmitURL.
            "httpRealm": "",
        ])

        // fromJSON returns nil if not valid.
        XCTAssertNotNil(LoginPayload.fromJSON(input))
    }

    func testSeparators() {
        // Mistyped parentid.
        let invalidSeparator = JSON(["type": "separator", "arentid": "toolbar", "parentName": "Bookmarks Toolbar", "pos": 3])
        XCTAssertNil(BookmarkType.payloadFromJSON(invalidSeparator))

        // This one's right.
        let validSeparator = JSON(["id": "abcabcabcabc", "type": "separator", "parentid": "toolbar", "parentName": "Bookmarks Toolbar", "pos": 3])
        let separator = BookmarkType.payloadFromJSON(validSeparator)!
        XCTAssertTrue(separator is SeparatorPayload)
        XCTAssertTrue(separator.isValid())
        XCTAssertEqual(3, separator["pos"].asInt!)
    }

    func testFolders() {
        let validFolder = JSON([
            "id": "abcabcabcabc",
            "type": "folder",
            "parentid": "toolbar",
            "parentName": "Bookmarks Toolbar",
            "title": "Sóme stüff",
            "description": "",
            "children": ["foo", "bar"],
        ])
        let folder = BookmarkType.payloadFromJSON(validFolder)!
        XCTAssertTrue(folder is FolderPayload)
        XCTAssertTrue(folder.isValid() ?? false)
        XCTAssertEqual((folder as! FolderPayload).children, ["foo", "bar"])
    }

    func testMobileBookmarksFolder() {
        let children = ["M87np9Vfh_2s","-JxRyqNte-ue","6lIQzUtbjE8O","eOg3jPSslzXl","1WJIi9EjQErp","z5uRo45Rvfbd","EK3lcNd0sUFN","gFD3GTljgu12","eRZGsbN1ew9-","widfEdgGn9de","l7eTOR4Uf6xq","vPbxG-gpN4Rb","4dwJ8CototFe","zK-kw9Ii6ScW","eDmDU-gtEFW6","lKjqWQaL_syt","ETVDvWgGT31Q","3Z_bMIHPSZQ8","Fqu4_bJOk7fT","Uo_5K1QrA67j","gDTXNg4m1AJZ","zpds8P-9xews","87zjNtVGPtEp","ZJru8Sn3qhW7","txVnzBBBOgLP","JTnRqFaj_oNa","soaMlfmM4kjR","g8AcVBjo6IRf","uPUDaiG4q637","rfq2bUud_w4d","XBGxsiuUG2UD","-VQRnJlyAvMs","6wu7TScKdTU7","ZeFji2hLVpLj","HpCn_TVizMWX","IPR5HZwRdlwi","00JFOGuWnhWB","P1jb3qKt32Vg","D6MQJ43V1Ir5","qWSoXFteRfsq","o2avfYqEdomL","xRS0U0YnjK9G","VgOgzE_xfP4w","SwP3rMJGvoO3","Hf2jEgI_-PWa","AyhmBi7Cv598","-PaMuzTJXxVk","JMhYrg8SlY5K","SQeySEjzyplL","GTAwd2UkEQEe","x3RsZj5Ilebr","sRZWZqPi74FP","amHR50TpygA6","XSk782ceVNN6","ipiMyYQzeypI","ph2k3Nqfhau4","m5JKC3hAEQ0H","yTVerkmQbNxk","7taA6FbbbUbH","PZvpbSRuJLPs","C8atoa25U94F","KOfNJk_ISLc6","Bt74lBG9tJq6","BuHoY2rUhuKA","XTmoWKnwfIPl","ZATwa3oTD1m0","e8TczN5It6Am","6kCUYs8hQtKg","jDD8s5aiKoex","QmpmcrYwLU29","nCRcekynuJ08","resttaI4J9tu","EKSX3HV55VU3","2-yCz0EIsVls","sSeeGw3VbBY-","qfpCrU34w9y0","RKDgzPWecD6m","5SgXEKu_dICW","R143WAeB5E5r","8Ns4-NiKG62r","4AHuZDvop5XX","YCP1OsO1goFF","CYYaU1mQ_N6t","UGkzEOMK8cuU","1RzZOarkzQBa","qSW2Z3cZSI9c","ooPlKEAfQsnn","jIUScoKLiXQt","bjNTKugzRRL1","hR24ZVnHUZcs","3j2IDAZgUyYi","xnWcy-sQDJRu","UCcgJqGk3bTV","WSSRWeptH9tq","4ugv47OGD2E2","XboCZgUx-x3x","HrmWqiqsuLrm","OjdxvRJ3Jb6j"]
        let json = JSON([
            "id": "UjAHxFOGEqU8",
            "type": "folder",
            "parentName": "",
            "title": "mobile",
            "description": JSON.null,
            "children": children,
            "parentid": "places",
        ])

        let bookmark = BookmarkType.payloadFromJSON(json)
        XCTAssertTrue(bookmark is FolderPayload)
        XCTAssertTrue(bookmark?.isValid() ?? false)
    }

    func testLivemarkMissingFields() {
        let json = JSON([
            "id": "M5bwUKK8hPyF",
            "type": "livemark",
            "siteUri": "http://www.bbc.co.uk/go/rss/int/news/-/news/",
            "feedUri": "http://fxfeeds.mozilla.com/en-US/firefox/headlines.xml",
            "parentName": "Bookmarks Toolbar",
            "parentid": "toolbar",
            "children": ["3Qr13GucOtEh"]])

        let bookmark = BookmarkType.payloadFromJSON(json)
        XCTAssertTrue(bookmark is LivemarkPayload)

        let livemark = bookmark as! LivemarkPayload
        XCTAssertTrue(livemark.isValid() ?? false)
        let siteURI = "http://www.bbc.co.uk/go/rss/int/news/-/news/"
        let feedURI = "http://fxfeeds.mozilla.com/en-US/firefox/headlines.xml"
        XCTAssertEqual(feedURI, livemark.feedURI)
        XCTAssertEqual(siteURI, livemark.siteURI)

        let m = (livemark as MirrorItemable).toMirrorItem(NSDate.now())
        XCTAssertEqual("http://fxfeeds.mozilla.com/en-US/firefox/headlines.xml", m.feedURI)
        XCTAssertEqual("http://www.bbc.co.uk/go/rss/int/news/-/news/", m.siteURI)
    }

    func testLivemark() {
        let json = JSON([
            "id": "M5bwUKK8hPyF",
            "type": "livemark",
            "siteUri": "http://www.bbc.co.uk/go/rss/int/news/-/news/",
            "feedUri": "http://fxfeeds.mozilla.com/en-US/firefox/headlines.xml",
            "parentName": "Bookmarks Toolbar",
            "parentid": "toolbar",
            "title": "Latest Headlines",
            "description": "",
            "children":
            ["7oBdEZB-8BMO", "SUd1wktMNCTB", "eZe4QWzo1BcY", "YNBhGwhVnQsN",
            "92Aw2SMEkFg0", "uw0uKqrVFwd-", "x7mx2P3--8FJ", "d-jVF8UuC9Ye",
            "DV1XVtKLEiZ5", "g4mTaTjr837Z", "1Zi5W3lwBw8T", "FEYqlUHtbBWS",
            "qQd2u7LjosCB", "VUs2djqYfbvn", "KuhYnHocu7eg", "u2gcg9ILRg-3",
            "hfK_RP-EC7Ol", "Aq5qsa4E5msH", "6pZIbxuJTn-K", "k_fp0iN3yYMR",
            "59YD3iNOYO8O", "01afpSdAk2iz", "Cq-kjXDEPIoP", "HtNTjt9UwWWg",
            "IOU8QRSrTR--", "HJ5lSlBx6d1D", "j2dz5R5U6Khc", "5GvEjrNR0yJl",
            "67ozIBF5pNVP", "r5YB0cUx6C_w", "FtmFDBNxDQ6J", "BTACeZq9eEtw",
            "ll4ozQ-_VNJe", "HpImsA4_XuW7", "nJvCUQPLSXwA", "94LG-lh6TUYe",
            "WHn_QoOL94Os", "l-RvjgsZYlej", "LipQ8abcRstN", "74TiLvarE3n_",
            "8fCiLQpQGK1P", "Z6h4WkbwfQFa", "GgAzhqakoS6g", "qyt92T8vpMsK",
            "RyOgVCe2EAOE", "bgSEhW3w6kk5", "hWODjHKGD7Ph", "Cky673aqOHbT",
            "gZCYT7nx3Nwu", "iJzaJxxrM58L", "rUHCRv68aY5L", "6Jc1hNJiVrV9",
            "lmNgoayZ-ym8", "R1lyXsDzlfOd", "pinrXwDnRk6g", "Sn7TmZV01vMM",
            "qoXyU6tcS1dd", "TRLanED-QfBK", "xHbhMeX_FYEA", "aPqacdRlAtaW",
            "E3H04Wn2RfSi", "eaSIMI6kSrcz", "rtkRxFoG5Vqi", "dectkUglV0Dz",
            "B4vUE0BE15No", "qgQFW5AQrgB0", "SxAXvwOhu8Zi", "0S6cRPOg-5Z2",
            "zcZZBGeLnaWW", "B0at8hkQqVZQ", "sgPtgGulbP66", "lwtwGHSCPYaQ",
            "mNTdpgoRZMbW", "-L8Vci6CbkJY", "bVzudKSQERc1", "Gxl9lb4DXsmL",
            "3Qr13GucOtEh"]])

        let bookmark = BookmarkType.payloadFromJSON(json)
        XCTAssertTrue(bookmark is LivemarkPayload)

        let livemark = bookmark as! LivemarkPayload
        XCTAssertTrue(livemark.isValid() ?? false)
        let siteURI = "http://www.bbc.co.uk/go/rss/int/news/-/news/"
        let feedURI = "http://fxfeeds.mozilla.com/en-US/firefox/headlines.xml"
        XCTAssertEqual(feedURI, livemark.feedURI)
        XCTAssertEqual(siteURI, livemark.siteURI)

        let m = (livemark as MirrorItemable).toMirrorItem(NSDate.now())
        XCTAssertEqual("http://fxfeeds.mozilla.com/en-US/firefox/headlines.xml", m.feedURI)
        XCTAssertEqual("http://www.bbc.co.uk/go/rss/int/news/-/news/", m.siteURI)
    }

    func testMobileBookmark() {
        let json = JSON([
            "id": "jIUScoKLiXQt",
            "type": "bookmark",
            "title": "Join the Engineering Leisure Class — Medium",
            "parentName": "mobile",
            "bmkUri": "https://medium.com/@chrisloer/join-the-engineering-leisure-class-b3083c09a78e",
            "tags": [],
            "keyword": JSON.null,
            "description": JSON.null,
            "loadInSidebar": false,
            "parentid": "mobile",
        ])

        let bookmark = BookmarkType.payloadFromJSON(json)
        XCTAssertTrue(bookmark is BookmarkPayload)
        XCTAssertTrue(bookmark?.isValid() ?? false)
    }

    func testQuery() {
        let str = "{\"title\":\"Downloads\",\"parentName\":\"\",\"bmkUri\":\"place:transition=7&sort=4\",\"id\":\"7gdp9S1okhKf\",\"parentid\":\"rq6WHyfHkoUV\",\"type\":\"query\"}"
        let query = BookmarkType.payloadFromJSON(JSON(string: str))
        XCTAssertTrue(query is BookmarkQueryPayload)
        let mirror = query?.toMirrorItem(NSDate.now())
        let roundtrip = mirror?.asPayload()
        XCTAssertTrue(roundtrip! is BookmarkQueryPayload)
    }

    func testBookmarks() {
        let validBookmark = JSON([
            "id": "abcabcabcabc",
            "type": "bookmark",
            "parentid": "menu",
            "parentName": "Bookmarks Menu",
            "title": "Anøther",
            "bmkUri": "http://terrible.sync/naming",
            "description": "",
            "tags": [],
            "keyword": "",
            ])
        let bookmark = BookmarkType.payloadFromJSON(validBookmark)
        XCTAssertTrue(bookmark is BookmarkPayload)

        let query = JSON.parse("{\"id\":\"ShCZLGEFQMam\",\"type\":\"query\",\"title\":\"Downloads\",\"parentName\":\"\",\"bmkUri\":\"place:transition=7&sort=4\",\"tags\":[],\"keyword\":null,\"description\":null,\"loadInSidebar\":false,\"parentid\":\"T6XK5oJMU8ih\"}")
        let q = BookmarkType.payloadFromJSON(query)
        XCTAssertTrue(q is BookmarkQueryPayload)
        XCTAssertTrue(q is MirrorItemable)
        guard let item = (q as? MirrorItemable)?.toMirrorItem(NSDate.now()) else {
            XCTFail("Not mirrorable!")
            return
        }

        XCTAssertEqual(6, item.type.rawValue)
        XCTAssertEqual("ShCZLGEFQMam", item.guid)

        let places = JSON.parse("{\"id\":\"places\",\"type\":\"folder\",\"title\":\"\",\"description\":null,\"children\":[\"menu________\",\"toolbar_____\",\"tags________\",\"unfiled_____\",\"jKnyPDrBQSDg\",\"T6XK5oJMU8ih\"],\"parentid\":\"2hYxKgBwvkEH\"}")
        let p = BookmarkType.payloadFromJSON(places)
        XCTAssertTrue(p is FolderPayload)
        XCTAssertTrue(p is MirrorItemable)

        // Items keep their GUID until they're written into the mirror table.
        XCTAssertEqual("places", p!.id)

        guard let pMirror = (p as? MirrorItemable)?.toMirrorItem(NSDate.now()) else {
            XCTFail("Not mirrorable!")
            return
        }

        XCTAssertEqual(2, pMirror.type.rawValue)

        // The mirror item has a translated GUID.
        XCTAssertEqual(BookmarkRoots.RootGUID, pMirror.guid)
    }
}
