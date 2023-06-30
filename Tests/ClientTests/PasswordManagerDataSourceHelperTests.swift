// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import Storage
import Shared
import XCTest

class PasswordManagerDataSourceHelperTests: XCTestCase {
    func testSetDomainLookup() {
        let subject = PasswordManagerDataSourceHelper()
        let login = LoginRecord(fromJSONDict: [
            "hostname": "https://example.com/",
            "id": "example"
        ])
        subject.setDomainLookup([login])
        XCTAssertNotNil(subject.domainLookup[login.id])
        XCTAssertEqual(subject.domainLookup[login.id]?.baseDomain, login.hostname.asURL?.baseDomain)
        XCTAssertEqual(subject.domainLookup[login.id]?.host, login.hostname.asURL?.host)
        XCTAssertEqual(subject.domainLookup[login.id]?.hostname, login.hostname)
    }

    func testTitleForLogin() {
        let subject = PasswordManagerDataSourceHelper()
        let login = LoginRecord(fromJSONDict: [
            "hostname": "https://example.com/",
            "id": "example"
        ])
        subject.setDomainLookup([login])
        XCTAssertEqual(subject.titleForLogin(login), Character("E"))
    }

    func testSortByDomain() {
        let subject = PasswordManagerDataSourceHelper()
        let apple = LoginRecord(fromJSONDict: [
            "hostname": "https://apple.com/",
            "id": "apple"
        ])
        let zebra = LoginRecord(fromJSONDict: [
            "hostname": "https://zebra.com/",
            "id": "zebra"
        ])
        XCTAssertFalse(subject.sortByDomain(apple, loginB: zebra))

        subject.setDomainLookup([apple, zebra])
        XCTAssertTrue(subject.sortByDomain(apple, loginB: zebra))
        XCTAssertFalse(subject.sortByDomain(zebra, loginB: apple))
    }

    func testComputeSectionsFromLogins() {
        let subject = PasswordManagerDataSourceHelper()
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
        subject.setDomainLookup(logins)
        let expectation = expectation(description: "Compute sections from login done")
        subject.computeSectionsFromLogins(logins) { formattedLogins in
            XCTAssertTrue(!formattedLogins.0.isEmpty)
            XCTAssertTrue(!formattedLogins.1.isEmpty)
            XCTAssertEqual(formattedLogins.0, sortedTitles)
            XCTAssertEqual(formattedLogins.1, expected)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }
}
