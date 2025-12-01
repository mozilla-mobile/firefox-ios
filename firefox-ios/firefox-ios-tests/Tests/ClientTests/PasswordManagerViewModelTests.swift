// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MozillaAppServices
import Storage
import XCTest
import Glean

@testable import Client

@MainActor
class PasswordManagerViewModelTests: XCTestCase {
    var viewModel: PasswordManagerViewModel!
    var dataSource: LoginDataSource!
    var mockDelegate: MockLoginViewModelDelegate!
    var mockLoginProvider: MockLoginProvider!

    override func setUp() async throws {
        try await super.setUp()
        let mockProfile = MockProfile()
        Self.setupTelemetry(with: mockProfile)
        self.mockLoginProvider = MockLoginProvider()
        let searchController = UISearchController()
        self.viewModel = PasswordManagerViewModel(
            profile: mockProfile,
            searchController: searchController,
            theme: LightTheme(),
            loginProvider: mockLoginProvider
        )
        self.mockDelegate = MockLoginViewModelDelegate()
        self.viewModel.delegate = mockDelegate
        self.viewModel.setBreachAlertsManager(MockBreachAlertsClient())
    }

    override func tearDown() async throws {
        Self.tearDownTelemetry()
        viewModel = nil
        mockLoginProvider = nil
        mockDelegate = nil
        try await super.tearDown()
    }

    @MainActor
    func testAddLoginWithEmptyString() async {
        let login = LoginEntry(fromJSONDict: [
                        "hostname": "https://example.com",
                        "formSubmitUrl": "https://example.com",
                        "username": "username",
                        "password": "password"
                    ])
        let expectation = XCTestExpectation(description: "Waiting for login query to complete")
        viewModel.save(loginRecord: login) { exampleQueryResult in
            XCTAssertEqual(self.mockLoginProvider.addLoginCalledCount, 1)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1)
        testCounterMetricRecordingSuccess(metric: GleanMetrics.Logins.saved)
    }

    @MainActor
    func testAddLoginWithString() async {
        let login = LoginEntry(fromJSONDict: [
                        "hostname": "https://example.com",
                        "formSubmitUrl": "https://example.com",
                        "username": "username",
                        "password": "password"
                    ])
        let expectation = XCTestExpectation(description: "Waiting for login query to complete")
        viewModel.save(loginRecord: login) { exampleQueryResult in
            XCTAssertEqual(self.mockLoginProvider.addLoginCalledCount, 1)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1)
        testCounterMetricRecordingSuccess(metric: GleanMetrics.Logins.saved)
    }

    func testQueryLoginsWithEmptyString() {
        let expectation = XCTestExpectation(description: "Waiting for login query to complete")
        viewModel.queryLogins("") { emptyQueryResult in
            XCTAssertEqual(self.mockDelegate.loginSectionsDidUpdateCalledCount, 0)
            XCTAssertEqual(self.mockLoginProvider.searchLoginsWithQueryCalledCount, 1)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testQueryLoginsWithExampleString() {
        let expectation = XCTestExpectation(description: "Waiting for login query to complete")
        viewModel.queryLogins("example") { exampleQueryResult in
            XCTAssertEqual(self.mockDelegate.loginSectionsDidUpdateCalledCount, 0)
            XCTAssertEqual(self.mockLoginProvider.searchLoginsWithQueryCalledCount, 1)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testIsDuringSearchControllerDismiss() {
        XCTAssertFalse(self.viewModel.isDuringSearchControllerDismiss)

        self.viewModel.setIsDuringSearchControllerDismiss(to: true)
        XCTAssertTrue(self.viewModel.isDuringSearchControllerDismiss)

        self.viewModel.setIsDuringSearchControllerDismiss(to: false)
        XCTAssertFalse(self.viewModel.isDuringSearchControllerDismiss)
    }
}
