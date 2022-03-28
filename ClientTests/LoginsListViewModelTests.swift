// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

@testable import Client
import Storage
import Shared
import XCTest



class LoginsListViewModelTests: XCTestCase {
    var viewModel: LoginListViewModel!
    var dataSource: LoginDataSource!

    override func setUp() {
        let mockProfile = MockProfile()
        let searchController = UISearchController()
        self.viewModel = LoginListViewModel(profile: mockProfile, searchController: searchController)
        self.dataSource = LoginDataSource(viewModel: self.viewModel)
        self.viewModel.setBreachAlertsManager(MockBreachAlertsClient())
        self.addLogins()
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
            let addResult = self.viewModel.profile.logins.addLogin(login: login)
            XCTAssertTrue(addResult.value.isSuccess)
            XCTAssertNotNil(addResult.value.successValue)
        }

        let logins = self.viewModel.profile.logins.listLogins().value
        XCTAssertTrue(logins.isSuccess)
        XCTAssertNotNil(logins.successValue)
    }

    func testQueryLogins() {
        let emptyQueryResult = self.viewModel.queryLogins("")
        XCTAssertTrue(emptyQueryResult.value.isSuccess)
        XCTAssertEqual(emptyQueryResult.value.successValue?.count, 10)

        let exampleQueryResult = self.viewModel.queryLogins("example")
        XCTAssertTrue(exampleQueryResult.value.isSuccess)
        XCTAssertEqual(exampleQueryResult.value.successValue?.count, 10)

        let threeQueryResult = self.viewModel.queryLogins("3")
        XCTAssertTrue(threeQueryResult.value.isSuccess)
        XCTAssertEqual(threeQueryResult.value.successValue?.count, 1)

        let zQueryResult = self.viewModel.queryLogins("yxz")
        XCTAssertTrue(zQueryResult.value.isSuccess)
        XCTAssertEqual(zQueryResult.value.successValue?.count, 0)
    }

    func testIsDuringSearchControllerDismiss() {
        XCTAssertFalse(self.viewModel.isDuringSearchControllerDismiss)

        self.viewModel.setIsDuringSearchControllerDismiss(to: true)
        XCTAssertTrue(self.viewModel.isDuringSearchControllerDismiss)

        self.viewModel.setIsDuringSearchControllerDismiss(to: false)
        XCTAssertFalse(self.viewModel.isDuringSearchControllerDismiss)
    }
}
