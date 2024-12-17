// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MozillaAppServices
import Shared
import Storage
import XCTest
import Glean

@testable import Client

class PasswordManagerViewModelTests: XCTestCase {
    var viewModel: PasswordManagerViewModel!
    var dataSource: LoginDataSource!
    var mockDelegate: MockLoginViewModelDelegate!
    var mockLoginProvider: MockLoginProvider!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        let mockProfile = MockProfile()
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
        // Due to changes allow certain custom pings to implement their own opt-out
        // independent of Glean, custom pings may need to be registered manually in
        // tests in order to puth them in a state in which they can collect data.
        Glean.shared.registerPings(GleanMetrics.Pings.shared)
        Glean.shared.resetGlean(clearStores: true)
    }

    override func tearDown() {
        viewModel = nil
        mockLoginProvider = nil
        mockDelegate = nil
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testaddLoginWithEmptyString() {
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
        wait(for: [expectation], timeout: 1)
        testCounterMetricRecordingSuccess(metric: GleanMetrics.Logins.saved)
    }

    func testaddLoginWithString() {
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
        wait(for: [expectation], timeout: 1)
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
