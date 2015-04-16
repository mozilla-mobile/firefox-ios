/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest


private let TestServiceURLString = "https://readinglist.dev.mozaws.net"
private let TestAccountUsername = "ReadingListClientTestCase"
private let TestAccountPassword = "ReadingListClientTestCase"


class ReadingListClientTestCase: XCTestCase {

    var authenticator: ReadingListAuthenticator!
    var client: ReadingListClient!

    override func setUp() {
        super.setUp()
        if let serviceURL = NSURL(string: TestServiceURLString) {
            var accountName = TestAccountUsername + "-" + randomStringWithLength(16)
            authenticator = ReadingListBasicAuthAuthenticator(username: accountName, password: TestAccountPassword)
            self.client = ReadingListClient(serviceURL: serviceURL, authenticator: authenticator)
            XCTAssertNotNil(self.client)
            createTestRecords()
        } else {
            XCTFail("Cannot parse service url")
        }
    }

    func testAddRecord() {
        let addFirstExpectation = expectationWithDescription("addFirst")

        let randomIdentifier = randomStringWithLength(16)

        let row: [String:AnyObject] = [
            "client_id": 1234,
            "client_last_modified": NSNumber(longLong: ReadingListNow()),
            "url": "http://localhost/article/\(randomIdentifier)",
            "title": "Article \(randomIdentifier)",
            "added_by": "testAddRecord",
            "unread": true,
            "archived": false,
            "favorite": true
        ]

        let record: ReadingListClientRecord! = ReadingListClientRecord(row: row)
        XCTAssert(record != nil)

        //let record = ReadingListClientRecord(url: "http://localhost/article/\(randomIdentifier)", title: "Article \(randomIdentifier)", addedBy: "ReadingListClientTestCase")

        var recordId: String?
        var recordLastModified: ReadingListTimestamp?

        client.addRecord(record, completion: { (result) -> Void in
            addFirstExpectation.fulfill()
            switch result {
                case ReadingListAddRecordResult.Success(let response):
                    XCTAssertEqual(response.response.statusCode, 201)
                    if let record = response.record {
                        XCTAssert(record.serverMetadata != nil)
                        recordId = record.serverMetadata!.guid

                        XCTAssertNotNil(record.url)
                        XCTAssertEqual(record.url, "http://localhost/article/\(randomIdentifier)")
                        XCTAssertNotNil(record.title)
                        XCTAssertEqual(record.title, "Article \(randomIdentifier)")
                        XCTAssertNotNil(record.addedBy)
                        XCTAssertEqual(record.addedBy, "testAddRecord")
                    } else {
                        XCTFail("response.record is nil")
                    }
                default:
                    XCTFail("Expected a ReadingListGetRecordResult.Success")
            }
        })

        waitForExpectationsWithTimeout(5.0, handler: { error in
            XCTAssertNil(error, "Error")
        })

        //

        let addSecondExpectation = expectationWithDescription("addSecond")

        client.addRecord(record, completion: { (result) -> Void in
            addSecondExpectation.fulfill()
            switch result {
                case ReadingListAddRecordResult.Success(let response):
                    XCTAssertEqual(response.response.statusCode, 200)
                    if let record = response.record {
                        XCTAssert(record.serverMetadata != nil)
                        XCTAssertNotNil(record.url)
                        XCTAssertEqual(record.url, "http://localhost/article/\(randomIdentifier)")
                        XCTAssertNotNil(record.title)
                        XCTAssertEqual(record.title, "Article \(randomIdentifier)")
                        XCTAssertNotNil(record.addedBy)
                        XCTAssertEqual(record.addedBy, "testAddRecord")
                        if let serverMetadata = record.serverMetadata {
                            recordLastModified = serverMetadata.lastModified
                        } else {
                            XCTFail("serverMetadata is nil")
                        }
                    } else {
                        XCTFail("response.record is nil")
                    }
                default:
                    XCTFail("Expected a ReadingListGetRecordResult.Success")
            }
        })

        waitForExpectationsWithTimeout(5.0, handler: { error in
            XCTAssertNil(error, "Error")
        })

        // Get the record with a last modified set, which should result in a NotModified result

        let getExpectation = expectationWithDescription("get")

        client.getRecordWithGuid(recordId!, ifModifiedSince: recordLastModified) { (result) -> Void in
            getExpectation.fulfill()
            switch result {
                case ReadingListGetRecordResult.NotModified(let response):
                    break
                default:
                    XCTFail("Expected a ReadingListGetRecordResult.NotModified")
            }
        }

        waitForExpectationsWithTimeout(5.0, handler: { error in
            XCTAssertNil(error, "Error")
        })
    }

    func testBatchAddRecords() {
        let row1: [String:AnyObject] = [
            "client_id": 100,
            "client_last_modified": NSNumber(longLong: ReadingListNow()),
            "url": "http://localhost/article/100",
            "title": "Article 100",
            "added_by": "Stefan's iPhone",
            "unread": true,
            "archived": false,
            "favorite": true
        ]

        let row2: [String:AnyObject] = [
            "client_id": 200,
            "client_last_modified": NSNumber(longLong: ReadingListNow()),
            "url": "http://localhost/article/200",
            "title": "Article 200",
            "added_by": "Stefan's iPhone",
            "unread": true,
            "archived": false,
            "favorite": true
        ]

        let row3: [String:AnyObject] = [
            "client_id": 300,
            "client_last_modified": NSNumber(longLong: ReadingListNow()),
            "url": "http://localhost/article/300",
            "title": "Article 300",
            "added_by": "Stefan's iPhone",
            "unread": true,
            "archived": false,
            "favorite": true
        ]

        let row4: [String:AnyObject] = [
            "client_id": 11,
            "client_last_modified": NSNumber(longLong: ReadingListNow()),
            "url": "http://localhost/article/11",
            "title": "Article 11",
            "added_by": "Stefan's iPhone",
            "unread": true,
            "archived": false,
            "favorite": true
        ]

        // Three new records and one with a URL that we already have
        let records = [
            ReadingListClientRecord(row: row1)!,
            ReadingListClientRecord(row: row2)!,
            ReadingListClientRecord(row: row3)!,
            ReadingListClientRecord(row: row4)!,
        ]

        let expectation = expectationWithDescription("add")

        client.batchAddRecords(records, completion: { (result) -> Void in
            expectation.fulfill()
            switch result {
            case ReadingListBatchAddRecordsResult.Success(let response):
                // TODO Look at the individual responses
                break
            default:
                XCTFail("Expected a ReadingListBatchAddRecordsResult.Success")
            }
        })

        waitForExpectationsWithTimeout(5.0, handler: { error in
            XCTAssertNil(error, "Error")
        })

        // Get the records, there should be three new ones

        let getAllExpectation = expectationWithDescription("getAll")

        let fetchSpec = ReadingListFetchSpec.Builder().build()
        client.getAllRecordsWithFetchSpec(fetchSpec, completion: { (result: ReadingListGetAllRecordsResult) -> Void in
            getAllExpectation.fulfill()
            switch result {
            case ReadingListGetAllRecordsResult.Success(let response):
                if let records = response.records {
                    XCTAssertEqual(records.count, 11) // 8 test records, 2 we just added
                } else {
                    XCTFail("Expected response.records")
                }
            default:
                XCTFail("Expected a ReadingListGetAllRecordsResult.Success")
            }
        })

        waitForExpectationsWithTimeout(5.0, handler: { error in
            XCTAssertNil(error, "Error")
        })
    }

    func testGetRecord() {
        let addExpectation = expectationWithDescription("add")

        let row: [String:AnyObject] = [
            "client_id": 100,
            "client_last_modified": NSNumber(longLong: ReadingListNow()),
            "url": "http://localhost/article/1234",
            "title": "Article 1234",
            "added_by": "testGetRecord",
            "unread": true,
            "archived": false,
            "favorite": true
        ]
        let record = ReadingListClientRecord(row: row)
        XCTAssert(record != nil)

        var recordId: String?

        client.addRecord(record!, completion: { (result) -> Void in
            addExpectation.fulfill()
            switch result {
            case ReadingListAddRecordResult.Success(let response):
                let record = response.record
                XCTAssert(record != nil)
                XCTAssert(record!.serverMetadata != nil)
                recordId = record!.serverMetadata!.guid
                break
            default:
                XCTFail("Expected a ReadingListGetRecordResult.Success")
                break
            }
        })

        waitForExpectationsWithTimeout(5.0, handler: { error in
            XCTAssertNil(error, "Error")
        })

        //

        let getExpectation = expectationWithDescription("get")

        client.getRecordWithGuid(recordId!) { (result) -> Void in
            getExpectation.fulfill()
            switch result {
                case ReadingListGetRecordResult.Success(let response):
                    // Check if lastModified is present in ReadingListResponse
                    XCTAssertTrue(response.lastModified != nil)
                    XCTAssertTrue(response.lastModified > 0)
                    // Check if record is present in ReadingListRecordResponse
                    let record = response.record
                    XCTAssert(record != nil)
                    XCTAssert(record!.serverMetadata != nil)
                    XCTAssertEqual(record!.serverMetadata!.guid, recordId!)
                    XCTAssertNotNil(record!.url)
                    XCTAssertEqual(record!.url, "http://localhost/article/1234")
                    XCTAssertNotNil(record!.title)
                    XCTAssertEqual(record!.title, "Article 1234")
                    XCTAssertNotNil(record!.addedBy)
                    XCTAssertEqual(record!.addedBy, "testGetRecord")
                default:
                    XCTFail("Expected a ReadingListGetRecordResult.Success")
            }
        }

        waitForExpectationsWithTimeout(5.0, handler: { error in
            XCTAssertNil(error, "Error")
        })
    }

    func testGetMissingRecord() {
        let readyExpectation = expectationWithDescription("ready")

        client.getRecordWithGuid("0DA1642B-9B12-4BA9-8C60-C198D0290DD8") { (result) -> Void in
            readyExpectation.fulfill()
            switch result {
                case ReadingListGetRecordResult.NotFound(let response):
                    break
                default:
                    XCTFail("Expected a ReadingListDeleteResult.MissingRecordFailure")
            }
        }

        waitForExpectationsWithTimeout(5.0, handler: { error in
            XCTAssertNil(error, "Error")
        })
    }

    func testGetAllRecords() {
        let readyExpectation = expectationWithDescription("ready")

        let fetchSpec = ReadingListFetchSpec.Builder().build()
        client.getAllRecordsWithFetchSpec(fetchSpec, completion: { (result: ReadingListGetAllRecordsResult) -> Void in
            readyExpectation.fulfill()
            switch result {
                case ReadingListGetAllRecordsResult.Success(let response):
                    if let records = response.records {
                        XCTAssertEqual(records.count, 8)
                    } else {
                        XCTFail("Expected response.record")
                    }
                default:
                    XCTFail("Expected a ReadingListGetAllRecordsResult.Success")
            }
        })

        waitForExpectationsWithTimeout(5.0, handler: { error in
            XCTAssertNil(error, "Error")
        })
    }

    func testGetAllUnreadRecords() {
        let readyExpectation = expectationWithDescription("ready")

        let fetchSpec = ReadingListFetchSpec.Builder().setUnread(true).build()
        client.getAllRecordsWithFetchSpec(fetchSpec, completion: { (result: ReadingListGetAllRecordsResult) -> Void in
            readyExpectation.fulfill()
            switch result {
            case ReadingListGetAllRecordsResult.Success(let response):
                if let records = response.records {
                    XCTAssertEqual(records.count, 3)
                    for record in records {
                        XCTAssertEqual(record.addedBy, "Stefan's iPhone")
                    }
                } else {
                    XCTFail("Expected response.record")
                }
            default:
                XCTFail("Expected a ReadingListGetAllRecordsResult.Success")
            }
        })

        waitForExpectationsWithTimeout(5.0, handler: { error in
            XCTAssertNil(error, "Error")
        })
    }

    func testGetAllReadRecords() {
        let readyExpectation = expectationWithDescription("ready")

        let fetchSpec = ReadingListFetchSpec.Builder().setUnread(false).build()
        client.getAllRecordsWithFetchSpec(fetchSpec, completion: { (result: ReadingListGetAllRecordsResult) -> Void in
            readyExpectation.fulfill()
            switch result {
            case ReadingListGetAllRecordsResult.Success(let response):
                if let records = response.records {
                    XCTAssertEqual(records.count, 5)
                    for record in records {
                        XCTAssertEqual(record.addedBy, "Stefan's iPad")
                    }
                } else {
                    XCTFail("Expected response.record")
                }
            default:
                XCTFail("Expected a ReadingListGetAllRecordsResult.Success")
            }
        })

        waitForExpectationsWithTimeout(5.0, handler: { error in
            XCTAssertNil(error, "Error")
        })
    }

    func testDeleteRecord() {
        let addExpectation = expectationWithDescription("add")

        let row: [String:AnyObject] = [
            "client_id": 100,
            "client_last_modified": NSNumber(longLong: ReadingListNow()),
            "url": "http://localhost/article/100",
            "title": "Article 100",
            "added_by": "Stefan's iPhone",
            "unread": true,
            "archived": false,
            "favorite": true
        ]
        let record = ReadingListClientRecord(row: row)
        XCTAssert(record != nil)

        var recordId: String?

        client.addRecord(record!, completion: { (result) -> Void in
            addExpectation.fulfill()
            switch result {
                case ReadingListAddRecordResult.Success(let response):
                    let record = response.record
                    XCTAssert(record != nil)
                    XCTAssert(record!.serverMetadata != nil)
                    recordId = record!.serverMetadata!.guid
                    break
                default:
                    XCTFail("Expected a ReadingListGetRecordResult.Success")
                    break
            }
        })

        waitForExpectationsWithTimeout(5.0, handler: { error in
            XCTAssertNil(error, "Error")
        })

        //

        let deleteExpectation = expectationWithDescription("delete")

        client.deleteRecordWithGuid(recordId!) { (result) -> Void in
            deleteExpectation.fulfill()
            switch result {
                case ReadingListDeleteRecordResult.Success(let response):
                    break
                default:
                    XCTFail("Expected a ReadingListDeleteResult.MissingRecordFailure")
                    break
            }
        }

        waitForExpectationsWithTimeout(5.0, handler: { error in
            XCTAssertNil(error, "Error")
        })

        //

        let getExpectation = expectationWithDescription("get")

        client.getRecordWithGuid(recordId!) { (result) -> Void in
            getExpectation.fulfill()
            switch result {
            case ReadingListGetRecordResult.NotFound(let response):
                break
            default:
                XCTFail("Expected a ReadingListDeleteResult.MissingRecordFailure")
                break
            }
        }

        waitForExpectationsWithTimeout(5.0, handler: { error in
            XCTAssertNil(error, "Error")
        })
    }

    func testDeleteMissingRecord() {
        let readyExpectation = expectationWithDescription("ready")

        client.deleteRecordWithGuid("0DA1642B-9B12-4BA9-8C60-C198D0290DD8") { (result) -> Void in
            readyExpectation.fulfill()
            switch result {
                case ReadingListDeleteRecordResult.NotFound(let response):
                    break
                default:
                    XCTFail("Expected a ReadingListDeleteResult.MissingRecordFailure")
                    break
            }
        }

        waitForExpectationsWithTimeout(5.0, handler: { error in
            XCTAssertNil(error, "Error")
        })
    }

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

    private func createTestRecords() {
        if let path = NSBundle(forClass: self.dynamicType).pathForResource("ReadingListClientTestCase", ofType: "json") {
            if let body = NSData(contentsOfFile: path) {
                let request = NSMutableURLRequest(URL: NSURL(string: "\(TestServiceURLString)/v1/batch")!)
                request.HTTPMethod = "POST"
                request.HTTPBody = body
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                for (headerField, value) in authenticator.headers {
                    request.setValue(value, forHTTPHeaderField: headerField)
                }

                let readyExpectation = expectationWithDescription("batch")
                let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
                    readyExpectation.fulfill()
                    if let response = response as? NSHTTPURLResponse {
                        if response.statusCode != 200 {
                            XCTFail("Cannot POST /v1/batch test data \(response.statusCode): \(NSString(data: data, encoding: NSUTF8StringEncoding))")
                        }
                    }
                })
                task.resume()
                waitForExpectationsWithTimeout(5.0, handler: { error in
                    XCTAssertNil(error, "Error")
                })
            }
        }
    }
}
