// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MozillaAppServices
import Shared
import Storage
import XCTest

@testable import Client

class PasswordManagerViewModelTests: XCTestCase {
    var viewModel: PasswordManagerViewModel!
    var dataSource: LoginDataSource!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        let mockProfile = MockProfile()
        let searchController = UISearchController()
        self.viewModel = PasswordManagerViewModel(
            profile: mockProfile,
            searchController: searchController,
            theme: LightTheme()
        )
        self.dataSource = LoginDataSource(viewModel: self.viewModel)
        self.viewModel.setBreachAlertsManager(MockBreachAlertsClient())
        self.addLogins()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
        viewModel = nil
        dataSource = nil
    }

    private func addLogins() {
        _ = self.viewModel.profile.logins.wipeLocalEngine()

        for i in (0..<10) {
            let login = LoginEntry(fromJSONDict: [
                "hostname": "https://example\(i).com",
                "formSubmitUrl": "https://example.com",
                "username": "username\(i)",
                "password": "password\(i)"
            ])
            let addExp = expectation(description: "\(#function)\(#line)")
            self.viewModel.profile.logins.addLogin(login: login).upon { addResult in
                XCTAssertTrue(addResult.isSuccess)
                XCTAssertNotNil(addResult.successValue)
                addExp.fulfill()
            }
        }

        let logins = self.viewModel.profile.logins.listLogins().value
        XCTAssertTrue(logins.isSuccess)
        XCTAssertNotNil(logins.successValue)

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testQueryLoginsWithEmptyString() {
        let expectation = XCTestExpectation(description: "Waiting for login query to complete")
        viewModel.queryLogins("") { emptyQueryResult in
            XCTAssertEqual(emptyQueryResult.count, 10)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testQueryLoginsWithExampleString() {
        let expectation = XCTestExpectation("Waiting for login query to complete")
        viewModel.queryLogins("example") { exampleQueryResult in
            XCTAssertEqual(exampleQueryResult.count, 10)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testQueryLoginsWithNumericString() {
        let expectation = XCTestExpectation("Waiting for login query to complete")
        viewModel.queryLogins("3") { threeQueryResult in
            XCTAssertEqual(threeQueryResult.count, 1)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testQueryLoginsWithNoResults() {
        let expectation = XCTestExpectation("Waiting for login query to complete")
        viewModel.queryLogins("yxz") { zQueryResult in
            XCTAssertEqual(zQueryResult.count, 0)
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
