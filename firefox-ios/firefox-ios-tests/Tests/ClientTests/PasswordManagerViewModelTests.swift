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
    var mockDelegate: MockLoginViewModelDelegate!

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
        self.mockDelegate = MockLoginViewModelDelegate()
        self.viewModel.delegate = mockDelegate
        self.viewModel.setBreachAlertsManager(MockBreachAlertsClient())
    }

    override func tearDown() {
        viewModel = nil
        DependencyHelperMock().reset()
        super.tearDown()
    }

    private func setupLogins() {
        _ = self.viewModel.profile.logins.wipeLocalEngine()

        var expectations: [XCTestExpectation] = []
        for i in (0..<10) {
            let addExp = XCTestExpectation(description: "Adding login \(i) \(#function)\(#line)")
            expectations.append(addExp)

            let login = LoginEntry(fromJSONDict: [
                "hostname": "https://example\(i).com",
                "formSubmitUrl": "https://example.com",
                "username": "username\(i)",
                "password": "password\(i)"
            ])
            self.viewModel.profile.logins.addLogin(login: login) { result in
                switch result {
                case .success(let logins):
                    XCTAssertEqual(logins?.fields.origin, "https://example\(i).com")
                    addExp.fulfill()
                case .failure:
                    XCTFail("Should not have failed")
                }
            }
        }
        wait(for: expectations, timeout: 10.0)
        self.viewModel.profile.logins.listLogins(completionHandler: { result in
            switch result {
            case .success(let logins):
                XCTAssertEqual(logins.count, 10)
            case .failure:
                XCTFail("Should not have failed")
            }
        })
    }

    func testQueryLoginsWithEmptyString() {
        setupLogins()
        let expectation = XCTestExpectation(description: "Waiting for login query to complete")
        viewModel.queryLogins("") { emptyQueryResult in
            XCTAssertEqual(emptyQueryResult.count, 10)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testQueryLoginsWithExampleString() {
        setupLogins()
        let expectation = XCTestExpectation(description: "Waiting for login query to complete")
        viewModel.queryLogins("example") { exampleQueryResult in
            XCTAssertEqual(self.mockDelegate.loginSectionsDidUpdateCalledCount, 0)
            XCTAssertEqual(exampleQueryResult.compactMap { $0.fields.origin }, [
                "https://example0.com",
                "https://example1.com",
                "https://example2.com",
                "https://example3.com",
                "https://example4.com",
                "https://example5.com",
                "https://example6.com",
                "https://example7.com",
                "https://example8.com",
                "https://example9.com"])
            XCTAssertEqual(exampleQueryResult.count, 10)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testQueryLoginsWithNumericString() {
        setupLogins()
        let expectation = XCTestExpectation(description: "Waiting for login query to complete")
        viewModel.queryLogins("3") { threeQueryResult in
            XCTAssertEqual(self.mockDelegate.loginSectionsDidUpdateCalledCount, 0)
            XCTAssertEqual(threeQueryResult.first?.fields.origin, "https://example3.com")
            XCTAssertEqual(threeQueryResult.count, 1)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testQueryLoginsWithNoResults() {
        setupLogins()
        let expectation = XCTestExpectation(description: "Waiting for login query to complete")
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
