// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import StoreKit
import StoreKitTest
import XCTest

@testable import Client

@MainActor
final class AppAcquisitionProviderTests: XCTestCase {
    func testFetchReturnsVerifiedAppInformation() async throws {
        guard #available(iOS 16.0, *) else {
            throw XCTSkip("App transactions require iOS 16 or later")
        }
        let session = try makeSession()
        defer { session.resetToDefaultState() }

        let verification = try await AppTransaction.refresh()
        guard case .verified(let transaction) = verification else {
            XCTFail("Expected a verified local test transaction")
            return
        }
        XCTAssertEqual(transaction.environment, .xcode)

        let result = await StoreKitAppAcquisitionProvider().fetch()

        XCTAssertEqual(result, .available(AppAcquisition(
            originalPurchaseDate: transaction.originalPurchaseDate,
            originalAppVersion: transaction.originalAppVersion
        )))
    }

    func testFetchHandlesStoreKitFailure() async throws {
        guard #available(iOS 17.0, *) else {
            throw XCTSkip("StoreKit error simulation requires iOS 17 or later")
        }
        let session = try makeSession()
        defer { session.resetToDefaultState() }
        try await session.setSimulatedError(.generic(.unknown), forAPI: .appTransaction)
        _ = try? await AppTransaction.refresh()

        let result = await StoreKitAppAcquisitionProvider().fetch()

        XCTAssertEqual(result, .unavailable(.storeKitFailure))

        try await session.setSimulatedError(nil, forAPI: .appTransaction)
        _ = try await AppTransaction.refresh()
    }

    private func makeSession() throws -> SKTestSession {
        let configuration = try XCTUnwrap(
            Bundle(for: AppAcquisitionProviderTests.self).url(forResource: "AppAcquisition", withExtension: "storekit")
        )
        let session = try SKTestSession(contentsOf: configuration)
        session.resetToDefaultState()
        session.disableDialogs = true
        return session
    }
}
