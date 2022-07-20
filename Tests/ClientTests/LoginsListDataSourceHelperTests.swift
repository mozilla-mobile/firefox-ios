// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

@testable import Client
import Storage
import Shared
import XCTest

class LoginListDataSourceHelperTests: XCTestCase {

    func testSetDomainLookup() {
        let sut = LoginListDataSourceHelper()
        let login = LoginRecord(fromJSONDict: [
            "hostname": "https://example.com/",
            "id": "example"
        ])
        sut.setDomainLookup([login])
        XCTAssertNotNil(sut.domainLookup[login.id])
        XCTAssertEqual(sut.domainLookup[login.id]?.baseDomain, login.hostname.asURL?.baseDomain)
        XCTAssertEqual(sut.domainLookup[login.id]?.host, login.hostname.asURL?.host)
        XCTAssertEqual(sut.domainLookup[login.id]?.hostname, login.hostname)
    }

    func testTitleForLogin() {
        let sut = LoginListDataSourceHelper()
        let login = LoginRecord(fromJSONDict: [
            "hostname": "https://example.com/",
            "id": "example"
        ])
        sut.setDomainLookup([login])
        XCTAssertEqual(sut.titleForLogin(login), Character("E"))
    }

    func testSortByDomain() {
        let sut = LoginListDataSourceHelper()
        let apple = LoginRecord(fromJSONDict: [
            "hostname": "https://apple.com/",
            "id": "apple"
        ])
        let zebra = LoginRecord(fromJSONDict: [
            "hostname": "https://zebra.com/",
            "id": "zebra"
        ])
        XCTAssertFalse(sut.sortByDomain(apple, loginB: zebra))

        sut.setDomainLookup([apple, zebra])
        XCTAssertTrue(sut.sortByDomain(apple, loginB: zebra))
        XCTAssertFalse(sut.sortByDomain(zebra, loginB: apple))
    }

    func testComputeSectionsFromLogins() {
        let sut = LoginListDataSourceHelper()
        let apple = LoginRecord(fromJSONDict: [
            "hostname": "https://apple.com/",
            "id": "apple"
        ])
        let appleMusic = LoginRecord(fromJSONDict: [
            "hostname": "https://apple.com/music",
            "id": "appleMusic"
        ])
        let zebra = LoginRecord(fromJSONDict: [
            "hostname": "https://zebra.com/",
            "id": "zebra"
        ])

        let sortedTitles = [Character("A"), Character("Z")]
        var expected = [Character: [LoginRecord]]()
        expected[Character("A")] = [apple, appleMusic]
        expected[Character("Z")] = [zebra]

        let logins = [apple, appleMusic, zebra]
        sut.setDomainLookup(logins)
        let expectation = expectation(description: "Compute sections from login done")
        sut.computeSectionsFromLogins(logins).upon { (formattedLoginsMaybe) in
            XCTAssertTrue(formattedLoginsMaybe.isSuccess)
            XCTAssertNotNil(formattedLoginsMaybe.successValue)
            let formattedLogins = formattedLoginsMaybe.successValue
            XCTAssertEqual(formattedLogins?.0, sortedTitles)
            XCTAssertEqual(formattedLogins?.1, expected)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }
}
