// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import XCTest
import Shared
import MozillaAppServices

class RemoteSettingsUtilTests: XCTestCase {
    var remoteSettingsUtil: RemoteSettingsUtil?
    var defaultCollection: RemoteCollection = .searchTelemetry
    var mockRemoteSettings: MockRemoteSettings?
    let keyForRecord = "testKey"

    override func setUp() {
        super.setUp()
        mockRemoteSettings = MockRemoteSettings(records: [])
        remoteSettingsUtil = RemoteSettingsUtil(bucket: .defaultBucket,
                                                collection: self.defaultCollection,
                                                remoteSettings: mockRemoteSettings)
        remoteSettingsUtil?.clearLocalRecords(forKey: keyForRecord)
    }
    
    override func tearDown() {
        remoteSettingsUtil = nil
        mockRemoteSettings = nil
        remoteSettingsUtil?.clearLocalRecords(forKey: keyForRecord)
        super.tearDown()
    }
    
    func testFetchLocalRecords() {
        guard let remoteSettingsUtil = remoteSettingsUtil else {
            XCTFail("RemoteSettingsUtil is nil")
            return
        }
        
        let testRecord = RemoteSettingsRecord(id: "1",
                                              lastModified: 123456,
                                              deleted: false,
                                              attachment: nil,
                                              fields: "{}")
        remoteSettingsUtil.saveRemoteSettingsRecord([testRecord],
                                                    forKey: keyForRecord)
        
        let records = remoteSettingsUtil.fetchLocalRecords(forKey: keyForRecord)
        
        XCTAssertNotNil(records)
        XCTAssertEqual(records?.count, 1)
        XCTAssertEqual(records?.first?.id, "1")
    }
    
    func testFetchLocalRecordsNoRecords() {
        guard let remoteSettingsUtil = remoteSettingsUtil else {
            XCTFail("RemoteSettingsUtil is nil")
            return
        }
        
        let records = remoteSettingsUtil.fetchLocalRecords(forKey: keyForRecord)
        XCTAssertNil(records)
    }
    
    func testSaveRemoteSettingsRecord() {
        guard let remoteSettingsUtil = remoteSettingsUtil else {
            XCTFail("RemoteSettingsUtil is nil")
            return
        }
        
        let testRecord = RemoteSettingsRecord(id: "1",
                                              lastModified: 123456,
                                              deleted: false,
                                              attachment: nil,
                                              fields: "{}")
        remoteSettingsUtil.saveRemoteSettingsRecord([testRecord], forKey: keyForRecord)
        
        let savedData = UserDefaults.standard.data(forKey: keyForRecord)
        XCTAssertNotNil(savedData)
    }

    func testUpdateAndFetchRecordsSuccess() {
        guard var remoteSettingsUtil = remoteSettingsUtil else {
            XCTFail("RemoteSettingsUtil is nil")
            return
        }

        let localRecord = RemoteSettingsRecord(id: "1",
                                               lastModified: 123456,
                                               deleted: false,
                                               attachment: nil,
                                               fields: "{}")
        remoteSettingsUtil.saveRemoteSettingsRecord([localRecord], forKey: keyForRecord)

        // mock remote records
        let providedRemoteRecord = RemoteSettingsRecord(id: "1",
                                                        lastModified: 123457,
                                                        deleted: false,
                                                        attachment: nil,
                                                        fields: "{}")

        let expectation = self.expectation(description: "UpdateAndFetchRecords")

        // bypassing fetch
        remoteSettingsUtil.updateAndFetchRecords(for: defaultCollection,
                                                 with: keyForRecord,
                                                 and: [providedRemoteRecord]) { result in
            switch result {
            case .success(let records):
                XCTAssertEqual(records.count, 1)
                XCTAssertEqual(records.first?.id, "1")
                XCTAssertEqual(records.first?.lastModified, 123457)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success, but got failure")
            }
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testDownloadAttachmentToPathSuccess() {
        guard let mockRemoteSettings = mockRemoteSettings else {
            XCTFail("MockRemoteSettings is nil")
            return
        }
        
        let attachmentId = "testAttachmentId"
        let path = NSTemporaryDirectory() + "testAttachment.txt"
        let expectation = self.expectation(description: "DownloadAttachment")
        
        do {
            try mockRemoteSettings.downloadAttachmentToPath(attachmentId: attachmentId,
                                                            path: path)
            let fileContent = try String(contentsOfFile: path, encoding: .utf8)
            XCTAssertEqual(fileContent, "Mock attachment content for \(attachmentId)")
            expectation.fulfill()
        } catch {
            XCTFail("Expected success, but got failure")
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
}

// MARK: Mock

class MockRemoteSettings: RemoteSettingsProtocol {
    var records: [RemoteSettingsRecord]
    var shouldThrowError: Bool

    init(records: [RemoteSettingsRecord], shouldThrowError: Bool = false) {
        self.records = records
        self.shouldThrowError = shouldThrowError
    }

    func downloadAttachmentToPath(attachmentId: String, path: String) throws {
        if shouldThrowError {
            throw RemoteSettingsUtilError.fetchError(NSError(domain: "Test", code: 1, userInfo: nil))
        }

        let dummyContent = "Mock attachment content for \(attachmentId)"
        try dummyContent.write(toFile: path, atomically: true, encoding: .utf8)
    }

    func getRecords() throws -> RemoteSettingsResponse {
        if shouldThrowError {
            throw RemoteSettingsUtilError.fetchError(NSError(domain: "Test", code: 1, userInfo: nil))
        }
        return RemoteSettingsResponse(records: records, lastModified: records.last?.lastModified ?? 0)
    }

    func getRecordsSince(timestamp: UInt64) throws -> RemoteSettingsResponse {
        if shouldThrowError {
            throw RemoteSettingsUtilError.fetchError(NSError(domain: "Test", code: 1, userInfo: nil))
        }
        let filteredRecords = records.filter { $0.lastModified > timestamp }
        return RemoteSettingsResponse(records: filteredRecords, lastModified: filteredRecords.last?.lastModified ?? 0)
    }
}


