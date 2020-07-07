/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

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
    }
    private func addLogins() {
        // make sure local db is empty
        _ = self.viewModel.profile.logins.wipeLocal()

        // add logins to DB - tested in RustLoginsTests
        for i in (0..<10) {
            let login = LoginRecord(fromJSONDict: [
                "hostname": "https://example\(i).com/",
                "formSubmitURL": "https://example.com",
                "username": "username\(i)",
                "password": "password\(i)"
            ])
            login.httpRealm = nil
            let addResult = self.viewModel.profile.logins.add(login: login)
            XCTAssertTrue(addResult.value.isSuccess)
            XCTAssertNotNil(addResult.value.successValue)
        }

        // make sure db is populated
        let logins = self.viewModel.profile.logins.list().value
        XCTAssertTrue(logins.isSuccess)
        XCTAssertNotNil(logins.successValue)
    }

    func testLoadLogins() { // TODO
        // start with loading empty DB
        XCTAssertNil(self.viewModel.activeLoginQuery)
        self.viewModel.loadLogins(loginDataSource: self.dataSource)
        XCTAssertEqual(self.viewModel.count, 0)
        XCTAssertEqual(self.viewModel.titles, [])

        // populate db
        self.addLogins()

        // load from populated db
        let expectation = XCTestExpectation(description: "logins loaded")
        self.viewModel.loadLogins(loginDataSource: self.dataSource)
//        XCTAssertEqual(self.viewModel.count, 10)
//        XCTAssertEqual(self.viewModel.titles[0], "https://example.com/22")

    }
    
    func testQueryLogins() {
        // populate db
        self.addLogins()

        let emptyQueryResult = self.viewModel.queryLogins("")
        XCTAssertTrue(emptyQueryResult.value.isSuccess)
        XCTAssertEqual(emptyQueryResult.value.successValue?.count, 10)

        let exampleQueryResult = self.viewModel.queryLogins("example")
        XCTAssertTrue(exampleQueryResult.value.isSuccess)
        XCTAssertEqual(exampleQueryResult.value.successValue?.count, 10)

        let threeQueryResult = self.viewModel.queryLogins("3")
        XCTAssertTrue(threeQueryResult.value.isSuccess)
        XCTAssertEqual(threeQueryResult.value.successValue?.count, 1)

        let usernameQueryResult = self.viewModel.queryLogins("username")
        XCTAssertTrue(usernameQueryResult.value.isSuccess)
        XCTAssertEqual(usernameQueryResult.value.successValue?.count, 10)
    }

    func testIsDuringSearchControllerDismiss() {
        XCTAssertFalse(self.viewModel.isDuringSearchControllerDismiss)

        self.viewModel.setIsDuringSearchControllerDismiss(to: true)
        XCTAssertTrue(self.viewModel.isDuringSearchControllerDismiss)

        self.viewModel.setIsDuringSearchControllerDismiss(to: false)
        XCTAssertFalse(self.viewModel.isDuringSearchControllerDismiss)
    }

    func testLoginAtIndexPath() { // TODO
//        let firstItem = self.viewModel.loginAtIndexPath(IndexPath(row: 1, section: 1))
//        XCTAssertNotNil(firstItem)
//        XCTAssertEqual(firstItem?.hostname, "https://example1.com/")
    }

    func testLoginsForSection() { // TODO

    }

    func testSetLogins() { // TODO
        
    }
}
