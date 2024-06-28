// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices
import Storage
import XCTest

@testable import Client

class LoginListViewModelTests: XCTestCase {
    @MainActor
    func testInitialization() {
        let viewModel = LoginListViewModel(
            tabURL: URL(string: "https://example.com")!,
            field: FocusFieldType.password,
            loginStorage: MockLoginStorage(),
            logger: MockLogger(),
            onLoginCellTap: { _ in },
            manageLoginInfoAction: { }
        )

        XCTAssertNotNil(viewModel)
        XCTAssertTrue(viewModel.logins.isEmpty)
    }

    @MainActor
    func testFetchLoginsSuccess() async {
        let mockLoginStorage = MockLoginStorage()

        let viewModel = LoginListViewModel(
            tabURL: URL(string: "https://test.com")!,
            field: FocusFieldType.password,
            loginStorage: mockLoginStorage,
            logger: MockLogger(),
            onLoginCellTap: { _ in },
            manageLoginInfoAction: { }
        )

        await viewModel.fetchLogins()

        XCTAssertEqual(viewModel.logins.count, 2)
    }

    @MainActor
    func testFetchLoginsFailure() async {
        let mockLoginStorage = MockLoginStorage()
        // Configure mock to throw an error
        mockLoginStorage.shouldThrowError = true

        let mockLogger = MockLogger()

        let viewModel = LoginListViewModel(
            tabURL: URL(string: "https://example.com")!,
            field: FocusFieldType.password,
            loginStorage: mockLoginStorage,
            logger: mockLogger,
            onLoginCellTap: { _ in },
            manageLoginInfoAction: { }
        )

        await viewModel.fetchLogins()

        XCTAssertNotNil(mockLogger.savedMessage)
        XCTAssertEqual(mockLogger.savedLevel, .warning)
        XCTAssertEqual(mockLogger.savedCategory, .autofill)
    }

    @MainActor
    func testOnLoginCellTap() {
        var didTapLogin = false

        let viewModel = LoginListViewModel(
            tabURL: URL(string: "https://example.com")!,
            field: FocusFieldType.password,
            loginStorage: MockLoginStorage(),
            logger: MockLogger(),
            onLoginCellTap: { _ in didTapLogin = true },
            manageLoginInfoAction: { }
        )

        // Simulate tapping a login cell
        viewModel.onLoginCellTap(EncryptedLogin(
            credentials: URLCredential(
                user: "test",
                password: "doubletest",
                persistence: .permanent
            ),
            protectionSpace: URLProtectionSpace.fromOrigin("https://test.com")
        ))

        XCTAssertTrue(didTapLogin)
    }

    @MainActor
    func testManageLoginInfoAction() {
        var didTapManageInfo = false

        let viewModel = LoginListViewModel(
            tabURL: URL(string: "https://example.com")!,
            field: FocusFieldType.password,
            loginStorage: MockLoginStorage(),
            logger: MockLogger(),
            onLoginCellTap: { _ in },
            manageLoginInfoAction: { didTapManageInfo = true }
        )

        // Simulate tapping manage login info
        viewModel.manageLoginInfoAction()

        XCTAssertTrue(didTapManageInfo)
    }
}
