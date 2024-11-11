// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// Note that this file is imported into SyncTests, too.

import Foundation
import Shared
@testable import Storage
@testable import Client

import XCTest

import struct MozillaAppServices.VisitObservation

let threeMonthsInMillis: UInt64 = 3 * 30 * 24 * 60 * 60 * 1000
let threeMonthsInMicros = UInt64(threeMonthsInMillis) * UInt64(1000)

// Start everything three months ago.
let baseInstantInMillis = Date.now() - threeMonthsInMillis
let baseInstantInMicros = Date().toMicrosecondsSince1970() - threeMonthsInMicros

func advanceTimestamp(_ timestamp: Timestamp, by: Int) -> Timestamp {
    return timestamp + UInt64(by)
}

func advanceMicrosecondTimestamp(_ timestamp: MicrosecondTimestamp, by: Int) -> MicrosecondTimestamp {
    return timestamp + UInt64(by)
}

enum VisitOrigin {
    case local
    case remote
}

func populateHistoryForFrecencyCalculations(_ places: RustPlaces, siteCount count: Int, visitPerSite: Int = 4) {
    for i in 0...count {
        let site = Site(url: "http://s\(i)ite\(i).com/foo", title: "A \(i)")
        site.guid = "abc\(i)def"

        for j in 0..<visitPerSite {
            let visitTime = advanceMicrosecondTimestamp(baseInstantInMicros, by: (1000000 * i) + (1000 * j))
            addVisitForSite(site, intoPlaces: places, atTime: visitTime)
            addVisitForSite(site, intoPlaces: places, atTime: visitTime - 100)
        }
    }
}

func addVisitForSite(_ site: Site, intoPlaces places: RustPlaces, atTime: MicrosecondTimestamp) {
    let visit = VisitObservation(url: site.url, visitType: .link, at: Int64(atTime) / 1000)
    _ = places.applyObservation(visitObservation: visit).value
}

extension BrowserDB {
    func assertQueryReturns(_ query: String, int: Int) {
        XCTAssertEqual(int, self.runQuery(query, args: nil, factory: IntFactory).value.successValue![0])
    }
}

extension BrowserDB {
    func getGUIDs(_ sql: String) -> [GUID] {
        func guidFactory(_ row: SDRow) -> GUID {
            guard let guid = row[0] as? GUID else {
                XCTFail("Expected GUID for first element in row, but cast failed.")
                return GUID()
            }
            return guid
        }

        guard let cursor = self.runQuery(sql, args: nil, factory: guidFactory).value.successValue else {
            XCTFail("Unable to get cursor.")
            return []
        }
        return cursor.asArray()
    }

    func getPositionsForChildrenOfParent(_ parent: GUID, fromTable table: String) -> [GUID: Int] {
        let args: Args = [parent]
        let factory: (SDRow) -> (GUID, Int) = { row in
            guard let guid = row["child"] as? GUID else {
                XCTFail("Expected GUID for key 'child', but cast failed.")
                return (GUID(), 0)
            }

            guard let index = row["idx"] as? Int else {
                XCTFail("Expected Int for key 'idx', but cast failed.")
                return (guid, 0)
            }
            return (guid, index)
        }
        let cursor = self.runQuery("SELECT child, idx FROM \(table) WHERE parent = ?", args: args, factory: factory).value.successValue!
        return cursor.reduce([:], { (dict, pair) in
            var dict = dict
            if let (k, v) = pair {
                dict[k] = v
            }
            return dict
        })
    }
}
