// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import BrowserKit
import XCTest
@testable import WebDataTransfer

final class BrowserDataImporterMappingTests: XCTestCase {
    func testItem_plainRecord_isUnsupportedAndKeepsSourceName() throws {
        guard #available(iOS 26.4, *) else { throw XCTSkip("Requires iOS 26.4") }
        let record = BEBrowserData(
            sourceApplicationBundleIdentifier: "com.apple.mobilesafari",
            sourceApplicationLocalizedName: "Safari"
        )

        let item = BrowserDataImporter.item(for: record)

        guard case .unsupported = item.payload else { return XCTFail("Expected unsupported") }
        XCTAssertEqual(item.sourceBrowserName, "Safari")
    }

    func testItem_extension_isSkipped() throws {
        guard #available(iOS 26.4, *) else { throw XCTSkip("Requires iOS 26.4") }
        let record = BEBrowserDataExtension(
            displayName: "Blocker", developerName: "Dev", identifier: "x", storeIdentifier: "1"
        )

        guard case .unsupported = BrowserDataImporter.item(for: record).payload else {
            return XCTFail("Expected unsupported")
        }
    }

    @MainActor
    func testToken_validUUID_isReturned() throws {
        guard #available(iOS 26.4, *) else { throw XCTSkip("Requires iOS 26.4") }
        let token = UUID()

        let result = BrowserDataImporter.token(from: [BEBrowserDataImportManager.importTokenUserInfoKey: token])

        XCTAssertEqual(result, token)
    }

    @MainActor
    func testToken_missingOrWrongType_isNil() throws {
        guard #available(iOS 26.4, *) else { throw XCTSkip("Requires iOS 26.4") }
        let key = BEBrowserDataImportManager.importTokenUserInfoKey

        XCTAssertNil(BrowserDataImporter.token(from: nil))
        XCTAssertNil(BrowserDataImporter.token(from: [:]))
        XCTAssertNil(BrowserDataImporter.token(from: [key: UUID().uuidString]))
    }

    @MainActor
    func testImportData_recordStream_completesWithSourceName() async throws {
        guard #available(iOS 26.4, *) else { throw XCTSkip("Requires iOS 26.4") }
        let records = AsyncThrowingStream<BEBrowserData, Error> { continuation in
            continuation.yield(BEBrowserData(
                sourceApplicationBundleIdentifier: "com.apple.mobilesafari",
                sourceApplicationLocalizedName: "Safari"
            ))
            continuation.yield(BEBrowserDataExtension(
                displayName: "Blocker", developerName: "Dev", identifier: "x", storeIdentifier: "1"
            ))
            continuation.finish()
        }

        let imported = await BrowserDataImporter.importData(from: records, onAPICompletion: {})
        let result = try XCTUnwrap(imported)

        XCTAssertTrue(result.apiCompleted)
        XCTAssertEqual(result.outcome, .success)
        XCTAssertEqual(result.recordCount, 0)
        XCTAssertEqual(result.sourceBrowserName, "Safari")
    }
}
