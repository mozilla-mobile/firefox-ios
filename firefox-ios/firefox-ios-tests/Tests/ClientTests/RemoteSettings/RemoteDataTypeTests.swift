// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import XCTest
import WebKit
import Shared
import Common
import Storage

class RemoteDataTypeTests: XCTestCase {
    // MARK: PasswordRuleRecord Tests

    func testLoadPasswordRuleRecords() async throws {
        do {
            let _: [PasswordRuleRecord] = try await loadAndTestRecords(for: .passwordRules)
        } catch {
            XCTFail("testLoadPasswordRuleRecords failed: \(error)")
        }
    }

    func testLoadPasswordRuleRecordsAndValidateContents() async throws {
        do {
            let records: [PasswordRuleRecord] = try await loadAndTestRecords(for: .passwordRules)

            let expectedRecord1 = PasswordRuleRecord(
                domain: "ccs-grp.com",
                passwordRules:
                """
                minlength: 8; maxlength: 16; required: digit; required: upper,lower; allowed: [-!#$%&'+./=?\\^_`{|}~];
                """,
                id: "6b15622b-1ce7-4141-89f1-c93e97aaaf88",
                lastModified: 1659924409785
            )

            let containsExpectedRecord1 = records.contains { $0 == expectedRecord1 }

            XCTAssertTrue(containsExpectedRecord1, "Expected record 1 is not found in the loaded records")
        } catch {
            XCTFail("testLoadPasswordRuleRecordsAndValidateContents failed: \(error)")
        }
    }

    func testRecordsInJSONFileNotEmpty() async throws {
        do {
            let records: [PasswordRuleRecord] = try await loadAndTestRecords(for: .passwordRules)
            XCTAssertGreaterThan(records.count, 0, "Expected more than 0 records, but found none")
        } catch {
            XCTFail("testNoRecordsInJSONFile failed: \(error)")
        }
    }

    // MARK: ContentBlockingListRecord Tests

    func testLoadContentBlockingListRecords() async throws {
        // Note: currently ContentBlockingListRecord is a placeholder model.
        do {
            let _: [ContentBlockingListRecord] = try await loadAndTestRecords(for: .contentBlockingLists)
        } catch {
            XCTFail("testLoadContentBlockingListRecords failed: \(error)")
        }
    }

    func testRecordsInContentBlockingJSONFileNotEmpty() async throws {
        // Note: currently ContentBlockingListRecord is a placeholder model.
        do {
            let records: [ContentBlockingListRecord] = try await loadAndTestRecords(for: .contentBlockingLists)
            XCTAssertGreaterThan(records.count, 0, "Expected more than 0 records, but found none")
        } catch {
            XCTFail("testRecordsInContentBlockingJSONFileNotEmpty failed: \(error)")
        }
    }

    func testLoadContentBlockListJSONFiles() {
        let lists = RemoteDataType.contentBlockingLists
        lists.fileNames.forEach {
            do {
                let data = try lists.loadLocalSettingsFileAsJSON(fileName: $0)
                XCTAssertNotNil(data, "Received nil data for content blocking JSON data. File: \($0).")
            } catch {
                XCTFail("Error while attempting to decode content blocking list \($0): \(error)")
            }
        }
    }

    // MARK: Helper

    // Indirectly tests `loadLocalSettingsFromJSON` by calling it within this function.
    // Any failure in loading or decoding will propagate here and fail the test.
    func loadAndTestRecords<T: RemoteDataTypeRecord>(for remoteDataType: RemoteDataType) async throws -> [T] {
        guard let fileName = remoteDataType.fileNames.first else {
            XCTFail("\(String(describing: remoteDataType)) fileNames list is unexpectedly empty.")
            return []
        }
        guard Bundle(for: type(of: self)).path(forResource: fileName, ofType: "json") != nil else {
            XCTFail("\(fileName).json not found in test bundle")
            return []
        }

        do {
            let records: [T] = try await remoteDataType.loadLocalSettingsFromJSON()
            XCTAssertGreaterThan(records.count, 0, "Expected more than 0 records")
            return records
        } catch {
            XCTFail("Failed to load and decode records from \(fileName).json: \(error)")
            throw error
        }
    }
}
