// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import X509
@testable import Client

final class CertificatesViewModelTests: XCTestCase {
    private var model: CertificatesModel!

    override func setUp() {
        super.setUp()
        model = CertificatesModel(topLevelDomain: "topLevelDomainTest.com",
                                  title: "TitleTest",
                                  URL: "https://google.com",
                                  certificates: [])
    }

    override func tearDown() {
        super.tearDown()
        model = nil
    }

    func testGetCertificateValues() {
        let data = "CN=www.google.com, O=Google Trust Services, C=US"
        let result = data.getDictionary()
        XCTAssertEqual(result["CN"], "www.google.com")
        XCTAssertEqual(result["O"], "Google Trust Services")
        XCTAssertEqual(result["C"], "US")
    }

    func testGetCertificateFromInvalidData() {
        let result = "".getDictionary()
        XCTAssertEqual(result, [:])
    }

    func testGetCertificateValuesWithMissingValue() {
        let data = "CN=www.google.com, O=, C=US"
        let result = data.getDictionary()
        XCTAssertEqual(result["CN"], "www.google.com")
        XCTAssertEqual(result["O"], "")
        XCTAssertEqual(result["C"], "US")
    }

    func testGetDNSNamesList() {
        let input = #"DNSName("www.google.com"), DNSName("*www.google.com")"#
        let result = model.getDNSNamesList(from: input)
        XCTAssertEqual(result, ["www.google.com", "*www.google.com"])
    }

    func testGetDNSNamesFromInvalidInput() {
        let result = model.getDNSNamesList(from: "")
        XCTAssertEqual(result, [])
    }
}
