/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Client
import Storage
import Shared
import XCTest


class LoginsListViewModelTests: XCTest {
    var viewModel: LoginListViewModel!
    var dataSource: LoginDataSource!

    override func setUp() {
        let mockProfile = MockProfile()
        let searchController = UISearchController()
        self.viewModel = LoginListViewModel(profile: mockProfile, searchController: searchController)
        self.dataSource = LoginDataSource(viewModel: self.viewModel)
    }

    func testLoadLogins() {
        // start with loading empty DB
        XCTAssertNil(self.viewModel.activeLoginQuery)
        self.viewModel.loadLogins(loginDataSource: self.dataSource)
        XCTAssertNotNil(self.viewModel.activeLoginQuery)
        if let activeLoginQuery = self.viewModel.activeLoginQuery {
            XCTAssertTrue(activeLoginQuery.isFilled)
            XCTAssertTrue(activeLoginQuery.value.isSuccess)
            XCTAssertEqual(activeLoginQuery.value.successValue?.count, 0)
        }

        // add logins to DB
        var deferred: Deferred<Maybe<String>>
        for i in (0...10) {
            let login = LoginRecord(fromJSONDict: [
                "hostname": "https://example.com/\(i)",
                "formSubmitURL": "https://example.com",
                "username": "username\(i)",
                "password": "password\(i)"
            ])
            login.httpRealm = nil
            deferred = self.viewModel.profile.logins.add(login: login)
            XCTAssertEqual(true, deferred.value.isSuccess, "Login added: \(login)")
        }

        self.viewModel.loadLogins(loginDataSource: self.dataSource)
        XCTAssertNotNil(self.viewModel.activeLoginQuery)
        if let activeLoginQuery = self.viewModel.activeLoginQuery {
            XCTAssertTrue(activeLoginQuery.isFilled)
            XCTAssertTrue(activeLoginQuery.value.isSuccess)
            XCTAssertEqual(activeLoginQuery.value.successValue?.count, 10)
        }
    }
    
    func testQueryLogins() {
        self.viewModel.queryLogins("").upon { (emptyQueryResult) in
            XCTAssertTrue(emptyQueryResult.isSuccess)
            XCTAssertEqual(emptyQueryResult.successValue?.count, 0)
        }

        self.viewModel.queryLogins("example").upon { (exampleQueryResult) in
            XCTAssertTrue(exampleQueryResult.isSuccess)
            XCTAssertEqual(exampleQueryResult.successValue?.count, 10)
        }

        self.viewModel.queryLogins("3").upon { (threeQueryResult) in
            XCTAssertTrue(threeQueryResult.isSuccess)
            XCTAssertEqual(threeQueryResult.successValue?.count, 1)
        }

        self.viewModel.queryLogins("username").upon { (usernameQueryResult) in
            XCTAssertTrue(usernameQueryResult.isSuccess)
            XCTAssertEqual(usernameQueryResult.successValue?.count, 10)
        }
    }

    func testIsDuringSearchControllerDismiss() {
        
    }

    func testLoginAtIndexPath() {
        
    }

    func testLoginsForSection() {

    }

    func testSetLogins() {
        
    }
}
