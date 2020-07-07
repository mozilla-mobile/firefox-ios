/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Client
import Storage
import Shared
import XCTest

class LoginsListViewModelHelperTests: XCTestCase {
    var helper: LoginListViewModelHelper!
    override func setUp() {
        helper = LoginListViewModelHelper()
    }

    func testSetDomainLookup() {
        let login = LoginRecord(fromJSONDict: [
            "hostname": "https://example.com/",
            "id": "example"
        ])
        self.helper.setDomainLookup([login])
        XCTAssertNotNil(self.helper.domainLookup[login.id])
        XCTAssertEqual(self.helper.domainLookup[login.id]?.baseDomain, login.hostname.asURL?.baseDomain)
        XCTAssertEqual(self.helper.domainLookup[login.id]?.host, login.hostname.asURL?.host)
        XCTAssertEqual(self.helper.domainLookup[login.id]?.hostname, login.hostname)
    }

    func testTitleForLogin() {
        let login = LoginRecord(fromJSONDict: [
            "hostname": "https://example.com/",
            "id": "example"
        ])
        self.helper.setDomainLookup([login])
        XCTAssertEqual(self.helper.titleForLogin(login), Character("E"))
    }

    func testSortByDomain() {
        let apple = LoginRecord(fromJSONDict: [
            "hostname": "https://apple.com/",
            "id": "apple"
        ])
        let zebra = LoginRecord(fromJSONDict: [
            "hostname": "https://zebra.com/",
            "id": "zebra"
        ])
        XCTAssertFalse(self.helper.sortByDomain(apple, loginB: zebra))

        self.helper.setDomainLookup([apple, zebra])
        XCTAssertTrue(self.helper.sortByDomain(apple, loginB: zebra))
        XCTAssertFalse(self.helper.sortByDomain(zebra, loginB: apple))
    }

    func testComputeSectionsFromLogins() { // TODO

    }
}
