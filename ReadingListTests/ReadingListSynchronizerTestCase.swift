/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

// TODO Copied from ReadingListClientTestCase - Move to ReadingListTestUtils
private let TestServiceURLString = "https://readinglist.dev.mozaws.net"
private let TestAccountUsername = "ReadingListClientTestCase"
private let TestAccountPassword = "ReadingListClientTestCase"

class ReadingListSynchronizerTestCase: XCTestCase {
    var accountName: String!
    var authenticator: ReadingListAuthenticator!
    var client: ReadingListClient!
    var storage: ReadingListStorage!
    var synchronizer: ReadingListSynchronizer!

    override func setUp() {
        super.setUp()
        accountName = TestAccountUsername + "-" + randomStringWithLength(16)
        if let serviceURL = NSURL(string: TestServiceURLString) {
            let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first as! String
            if NSFileManager.defaultManager().fileExistsAtPath("\(path)/ReadingList.db") {
                if !NSFileManager.defaultManager().removeItemAtPath("\(path)/ReadingList.db", error: nil) {
                    XCTFail("Cannot remove old \(path)/ReadingList.db")
                }
            }

            self.authenticator = ReadingListBasicAuthAuthenticator(username: accountName, password: TestAccountPassword)
            self.client = ReadingListClient(serviceURL: serviceURL, authenticator: authenticator)
            self.storage = ReadingListSQLStorage(path: "\(path)/ReadingList.db")
            self.synchronizer = ReadingListSynchronizer(storage: storage, client: client)
        } else {
            XCTFail("Cannot parse service url")
        }
    }

    func testSynchronizeUploadOnly() {
//        let readyExpectation = expectationWithDescription("ready")
//
//        // Preconditions, there should be 3 new (unsynced) items in the store
//
//        var records = [ReadingListClientRecord](storage.getNewRecords())
//        XCTAssertEqual(records.count, 3)
//
//        // Synchronize the store, Upload only
//
//        synchronizer.synchronize(type: ReadingListSyncType.UploadOnly) { (result) -> Void in
//            readyExpectation.fulfill()
//            switch result {
//            case ReadingListSynchronizerResult.Success:
//                break
//            case ReadingListSynchronizerResult.Failure:
//                XCTFail("Received ReadingListSynchronizerResult.Failure instead of .Success")
//            case ReadingListSynchronizerResult.Error(let error):
//                XCTFail("Received ReadingListSynchronizerResult.Failure(\(error)) instead of .Success")
//            }
//        }
//
//        waitForExpectationsWithTimeout(5.0, { error in
//            XCTAssertNil(error, "Error")
//        })
//
//        // Postcondition, there should be no new records in the store. All records should have server meta.
//
//        records = [ReadingListClientRecord](storage.getNewRecords())
//        XCTAssertEqual(records.count, 0)
//
//        for record in records {
//            XCTAssert(record.serverMetadata != nil)
//        }
    }

    // TODO Copied from ReadingListClientTestCase - Move to ReadingListTestUtils
    private func randomStringWithLength(len : Int) -> String {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var randomString : NSMutableString = NSMutableString(capacity: len)
        for (var i=0; i < len; i++){
            var length = UInt32 (letters.length)
            var rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
        }
        return randomString as String
    }
}
