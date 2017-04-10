/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
@testable import Storage
import Deferred

import XCTest

class TestSQLiteMetadata: XCTestCase {
    let files = MockFiles()
    var db: BrowserDB!
    var metadata: SQLiteMetadata!

    override func setUp() {
        super.setUp()
        self.db = BrowserDB(filename: "foo.db", files: self.files)
        self.db.attachDB(filename: "metadata.db", as: AttachedDatabaseMetadata)
        XCTAssertTrue(db.createOrUpdate(BrowserTable()) == .success)

        self.metadata = SQLiteMetadata(db: db)
    }

    override func tearDown() {
        removeAllMetadata(self.db).succeeded()
        super.tearDown()
    }

    func testInsertMetadata() {
        let site = "http://test.com"

        let page = PageMetadata(id: nil, siteURL: site, mediaURL: "http://image.com",
                                title: "Test", description: "Test Description", type: nil, providerName: nil, mediaDataURI: nil, cacheImages: false)
        self.metadata.storeMetadata(page, forPageURL: site.asURL!, expireAt: Date.now() + 3000).succeeded()
        let results = metadataFromDB(self.db).value.successValue!
        XCTAssertEqual(results.count, 1)
        let metadata = results[0]!
        XCTAssertEqual(metadata.siteURL, site)
    }

    func testDuplicateCacheKeyInsert() {
        let siteA = "http://test.com/site/A"
        let siteB = "http://test.com/site/B"

        let metadataA1 = PageMetadata(id: nil, siteURL: siteA, mediaURL: nil,
                                      title: "First Visit", description: "", type: nil, providerName: nil, mediaDataURI: nil, cacheImages: false)
        let metadataB = PageMetadata(id: nil, siteURL: siteB, mediaURL: "http://image.com",
                                     title: "Test", description: "Test Description", type: nil, providerName: nil, mediaDataURI: nil, cacheImages: false)
        let metadataA2 = PageMetadata(id: nil, siteURL: siteA, mediaURL: "http://image.com",
                                      title: "Second Visit", description: "A new description", type: nil, providerName: nil, mediaDataURI: nil, cacheImages: false)

        self.metadata.storeMetadata(metadataA1, forPageURL: siteA.asURL!, expireAt: Date.now() + 3000).succeeded()

        let initialResults = metadataFromDB(self.db).value.successValue!
        XCTAssertEqual(initialResults.count, 1)

        let initialA = initialResults[0]!
        XCTAssertEqual(initialA.siteURL, siteA)
        XCTAssertEqual(initialA.title, "First Visit")
        XCTAssertEqual(initialA.description, "")
        XCTAssertNil(initialA.mediaURL)

        self.metadata.storeMetadata(metadataB, forPageURL: siteB.asURL!, expireAt: Date.now() + 3000).succeeded()
        self.metadata.storeMetadata(metadataA2, forPageURL: siteA.asURL!, expireAt: Date.now() + 3000).succeeded()

        let results = metadataFromDB(self.db).value.successValue!

        // Should only have 2 since we upsert
        XCTAssertEqual(results.count, 2)

        let resultA = results[1]!
        let resultB = results[0]!

        XCTAssertEqual(resultA.siteURL, siteA)
        XCTAssertEqual(resultB.siteURL, siteB)

        XCTAssertEqual(resultA.title, "Second Visit")
        XCTAssertEqual(resultA.description, "A new description")
        XCTAssertEqual(resultA.mediaURL!, "http://image.com")
    }

    func testExpirationPurging() {
        let baseTime = Date.now()
        let siteA = "http://test.com/site/A"
        let metadataA = PageMetadata(id: nil, siteURL: siteA, mediaURL: nil,
                                     title: "Test", description: "Test Description", type: nil, providerName: nil, mediaDataURI: nil, cacheImages: false)
        // Set expiration to base
        self.metadata.storeMetadata(metadataA, forPageURL: siteA.asURL!, expireAt: baseTime - 1000).succeeded()
        self.metadata.deleteExpiredMetadata().succeeded()

        let results = metadataFromDB(self.db).value.successValue!
        XCTAssertEqual(results.count, 0)
    }
}

private func metadataFromDB(_ db: BrowserDB) -> Deferred<Maybe<Cursor<PageMetadata>>> {
    let sql = "SELECT * FROM \(AttachedTablePageMetadata)"
    return db.runQuery(sql, args: nil, factory: pageMetadataFactory)
}

private func removeAllMetadata(_ db: BrowserDB) -> Success {
    return db.run("DELETE FROM \(AttachedTablePageMetadata)")
}

private func pageMetadataFactory(_ row: SDRow) -> PageMetadata {
    let id = row["id"] as! Int
    let siteURL = row["site_url"] as! String
    let mediaURL = row["media_url"] as? String
    let title = row["title"] as? String
    let description = row["description"] as? String
    let type = row["type"] as? String
    let providerName = row["provider_name"] as? String
    return PageMetadata(id: id, siteURL: siteURL, mediaURL: mediaURL, title: title,
                        description: description, type: type, providerName: providerName, mediaDataURI: nil, cacheImages: false)
}
