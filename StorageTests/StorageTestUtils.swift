/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// Note that this file is imported into SyncTests, too.

import Foundation
import Shared
@testable import Storage
import XCTest


let threeMonthsInMillis: UInt64 = 3 * 30 * 24 * 60 * 60 * 1000
let threeMonthsInMicros: UInt64 = UInt64(threeMonthsInMillis) * UInt64(1000)

// Start everything three months ago.
let baseInstantInMillis = Date.now() - threeMonthsInMillis
let baseInstantInMicros = Date.nowMicroseconds() - threeMonthsInMicros

func advanceTimestamp(_ timestamp: Timestamp, by: Int) -> Timestamp {
    return timestamp + UInt64(by)
}

func advanceMicrosecondTimestamp(_ timestamp: MicrosecondTimestamp, by: Int) -> MicrosecondTimestamp {
    return timestamp + UInt64(by)
}

extension Site {
    func asPlace() -> Place {
        return Place(guid: self.guid!, url: self.url, title: self.title)
    }
}

enum VisitOrigin {
    case local
    case remote
}

func populateHistoryForFrecencyCalculations(_ history: SQLiteHistory, siteCount count: Int, visitPerSite: Int = 4) {
    for i in 0...count {
        let site = Site(url: "http://s\(i)ite\(i).com/foo", title: "A \(i)")
        site.guid = "abc\(i)def"

        let baseMillis: UInt64 = baseInstantInMillis - 20000
        history.insertOrUpdatePlace(site.asPlace(), modified: baseMillis).succeeded()

        for j in 0..<visitPerSite {
            let visitTime = advanceMicrosecondTimestamp(baseInstantInMicros, by: (1000000 * i) + (1000 * j))
            addVisitForSite(site, intoHistory: history, from: .local, atTime: visitTime)
            addVisitForSite(site, intoHistory: history, from: .remote, atTime: visitTime - 100)
        }
    }
}

func addVisitForSite(_ site: Site, intoHistory history: SQLiteHistory, from: VisitOrigin, atTime: MicrosecondTimestamp) {
    let visit = SiteVisit(site: site, date: atTime, type: VisitType.link)
    switch from {
    case .local:
        history.addLocalVisit(visit).succeeded()
    case .remote:
        history.storeRemoteVisits([visit], forGUID: site.guid!).succeeded()
    }
}

extension BrowserDB {
    func assertQueryReturns(_ query: String, int: Int) {
        XCTAssertEqual(int, self.runQuery(query, args: nil, factory: IntFactory).value.successValue![0])
    }
}

extension BrowserDB {
    func moveLocalToMirrorForTesting() {
        // This is a risky process -- it's not the same logic that the real synchronizer uses
        // (because I haven't written it yet), so it might end up lying. We do what we can.
        let valueSQL = """
            INSERT OR IGNORE INTO bookmarksMirror
                (guid, type, date_added, bmkUri, title, parentid, parentName, feedUri, siteUri, pos,
                description, tags, keyword, folderName, queryId,
                is_overridden, server_modified, faviconID)
            SELECT
                guid, type, date_added, bmkUri, title, parentid, parentName, feedUri, siteUri, pos,
                description, tags, keyword, folderName, queryId,
                0 AS is_overridden, \(Date.now()) AS server_modified, faviconID
            FROM bookmarksLocal
            """

        // Copy its mirror structure.
        let structureSQL = "INSERT INTO bookmarksMirrorStructure SELECT * FROM bookmarksLocalStructure"

        // Throw away the old.
        let deleteLocalStructureSQL = "DELETE FROM bookmarksLocalStructure"
        let deleteLocalSQL = "DELETE FROM bookmarksLocal"

        self.run([
            valueSQL,
            structureSQL,
            deleteLocalStructureSQL,
            deleteLocalSQL,
        ]).succeeded()
    }

    func moveBufferToMirrorForTesting() {
        let valueSQL = """
            INSERT OR IGNORE INTO bookmarksMirror
                (guid, type, date_added, bmkUri, title, parentid, parentName, feedUri, siteUri, pos,
                description, tags, keyword, folderName, queryId, server_modified)
            SELECT
                guid, type, date_added, bmkUri, title, parentid, parentName, feedUri, siteUri, pos,
                description, tags, keyword, folderName, queryId, server_modified
            FROM bookmarksBuffer
            """

        let structureSQL = "INSERT INTO bookmarksMirrorStructure SELECT * FROM bookmarksBufferStructure"
        let deleteBufferStructureSQL = "DELETE FROM bookmarksBufferStructure"
        let deleteBufferSQL = "DELETE FROM bookmarksBuffer"

        self.run([
            valueSQL,
            structureSQL,
            deleteBufferStructureSQL,
            deleteBufferSQL,
        ]).succeeded()
    }
}

extension BrowserDB {
    func getGUIDs(_ sql: String) -> [GUID] {
        func guidFactory(_ row: SDRow) -> GUID {
            return row[0] as! GUID
        }

        guard let cursor = self.runQuery(sql, args: nil, factory: guidFactory).value.successValue else {
            XCTFail("Unable to get cursor.")
            return []
        }
        return cursor.asArray()
    }

    func getPositionsForChildrenOfParent(_ parent: GUID, fromTable table: String) -> [GUID: Int] {
        let args: Args = [parent]
        let factory: (SDRow) -> (GUID, Int) = {
            return ($0["child"] as! GUID, $0["idx"] as! Int)
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

    func isLocallyDeleted(_ guid: GUID) -> Bool? {
        let args: Args = [guid]
        let cursor = self.runQuery("SELECT is_deleted FROM bookmarksLocal WHERE guid = ?", args: args, factory: { $0.getBoolean("is_deleted") }).value.successValue!
        return cursor[0]
    }

    func isOverridden(_ guid: GUID) -> Bool? {
        let args: Args = [guid]
        let cursor = self.runQuery("SELECT is_overridden FROM bookmarksMirror WHERE guid = ?", args: args, factory: { $0.getBoolean("is_overridden") }).value.successValue!
        return cursor[0]
    }

    func getSyncStatusForGUID(_ guid: GUID) -> SyncStatus? {
        let args: Args = [guid]
        let cursor = self.runQuery("SELECT sync_status FROM bookmarksLocal WHERE guid = ?", args: args, factory: { $0[0] as! Int }).value.successValue!
        if let raw = cursor[0] {
            return SyncStatus(rawValue: raw)
        }
        return nil
    }

    func getRecordByURL(_ url: String, fromTable table: String) -> BookmarkMirrorItem {
        let args: Args = [url]
        return self.runQuery("SELECT * FROM \(table) WHERE bmkUri = ?", args: args, factory: BookmarkFactory.mirrorItemFactory).value.successValue![0]!
    }

    func getRecordByGUID(_ guid: GUID, fromTable table: String) -> BookmarkMirrorItem {
        let args: Args = [guid]
        return self.runQuery("SELECT * FROM \(table) WHERE guid = ?", args: args, factory: BookmarkFactory.mirrorItemFactory).value.successValue![0]!
    }

    func getChildrenOfFolder(_ folder: GUID) -> [GUID] {
        let args: Args = [folder]
        let sql = """
            SELECT child
            FROM view_bookmarksLocalStructure_on_mirror
            WHERE parent = ?
            ORDER BY idx ASC
            """

        return self.runQuery(sql, args: args, factory: { $0[0] as! GUID }).value.successValue!.asArray()
    }
}
