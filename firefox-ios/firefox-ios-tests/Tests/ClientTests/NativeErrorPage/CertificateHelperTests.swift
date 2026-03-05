// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import XCTest

@testable import Client

final class CertificateHelperTests: XCTestCase {
    // MARK: - certificateDataFromErrorURL

    func testCertificateDataFromErrorURL_withValidBadCertParam_returnsData() {
        let base64Cert = Data([0x01, 0x02, 0x03]).base64EncodedString()
        let url = URL(string: "\(InternalURL.baseUrl)/\(InternalURL.Path.errorpage.rawValue)?badcert=\(base64Cert)")!
        let result = CertificateHelper.certificateDataFromErrorURL(url)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, Data([0x01, 0x02, 0x03]))
    }

    func testCertificateDataFromErrorURL_withNoBadCertParam_returnsNil() {
        let url = URL(string: "\(InternalURL.baseUrl)/\(InternalURL.Path.errorpage.rawValue)?url=https%3A%2F%2Fexample.com")!
        XCTAssertNil(CertificateHelper.certificateDataFromErrorURL(url))
    }

    func testCertificateDataFromErrorURL_withInvalidBase64_returnsNil() {
        let url = URL(string: "\(InternalURL.baseUrl)/\(InternalURL.Path.errorpage.rawValue)?badcert=!!!invalid!!!")!
        XCTAssertNil(CertificateHelper.certificateDataFromErrorURL(url))
    }

    func testCertificateDataFromErrorURL_withNestedErrorURL_returnsData() {
        let base64Cert = Data([0x01, 0x02, 0x03]).base64EncodedString()
        let inner = "\(InternalURL.baseUrl)/\(InternalURL.Path.errorpage.rawValue)?badcert=\(base64Cert)"
        let encoded = inner.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? inner
        let url = URL(string: "\(InternalURL.baseUrl)/sessionrestore?url=\(encoded)")!
        let result = CertificateHelper.certificateDataFromErrorURL(url)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, Data([0x01, 0x02, 0x03]))
    }

    // MARK: - secCertificateFromErrorURL

    func testSecCertificateFromErrorURL_withNoCertData_returnsNil() {
        let url = URL(string: "\(InternalURL.baseUrl)/\(InternalURL.Path.errorpage.rawValue)?url=https%3A%2F%2Fexample.com")!
        XCTAssertNil(CertificateHelper.secCertificateFromErrorURL(url))
    }

    func testSecCertificateFromErrorURL_withInvalidCertData_returnsNil() {
        let base64 = Data([0x01, 0x02, 0x03]).base64EncodedString()
        let url = URL(string: "\(InternalURL.baseUrl)/\(InternalURL.Path.errorpage.rawValue)?badcert=\(base64)")!
        XCTAssertNil(CertificateHelper.secCertificateFromErrorURL(url))
    }

    // MARK: - certificatesFromErrorURL

    func testCertificatesFromErrorURL_withNoCertData_returnsEmptyArray() {
        let url = URL(string: "\(InternalURL.baseUrl)/\(InternalURL.Path.errorpage.rawValue)?url=https%3A%2F%2Fexample.com")!
        XCTAssertTrue(CertificateHelper.certificatesFromErrorURL(url, logger: MockLogger()).isEmpty)
    }

    func testCertificatesFromErrorURL_withInvalidDER_returnsEmptyArrayAndLogs() {
        let logger = MockLogger()
        let base64 = Data([0x01, 0x02, 0x03]).base64EncodedString()
        let url = URL(string: "\(InternalURL.baseUrl)/\(InternalURL.Path.errorpage.rawValue)?badcert=\(base64)")!
        let result = CertificateHelper.certificatesFromErrorURL(url, logger: logger)
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(logger.savedMessage, "CertificateHelper: Failed to parse certificate from error URL")
    }

    // MARK: - isBadCertDomainErrorPage

    func testIsBadCertDomainErrorPage_withCertErrorParamMatching_returnsTrue() {
        let url = URL(string: "\(InternalURL.baseUrl)/\(InternalURL.Path.errorpage.rawValue)?certerror=\(CertificateHelper.badCertDomainErrorName)")!
        XCTAssertTrue(CertificateHelper.isBadCertDomainErrorPage(url: url))
    }

    func testIsBadCertDomainErrorPage_withNoCertErrorParam_returnsFalse() {
        let url = URL(string: "\(InternalURL.baseUrl)/\(InternalURL.Path.errorpage.rawValue)?url=https%3A%2F%2Fexample.com")!
        XCTAssertFalse(CertificateHelper.isBadCertDomainErrorPage(url: url))
    }

    func testIsBadCertDomainErrorPage_withOtherCertError_returnsFalse() {
        let url = URL(string: "\(InternalURL.baseUrl)/\(InternalURL.Path.errorpage.rawValue)?certerror=SSL_ERROR_EXPIRED_CERTIFICATE")!
        XCTAssertFalse(CertificateHelper.isBadCertDomainErrorPage(url: url))
    }

    func testIsBadCertDomainErrorPage_withNestedSessionRestoreURL_returnsTrue() {
        let inner = "\(InternalURL.baseUrl)/\(InternalURL.Path.errorpage.rawValue)?certerror=\(CertificateHelper.badCertDomainErrorName)"
        let encoded = inner.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? inner
        let url = URL(string: "\(InternalURL.baseUrl)/sessionrestore?url=\(encoded)")!
        XCTAssertTrue(CertificateHelper.isBadCertDomainErrorPage(url: url))
    }

    func testIsBadCertDomainErrorPage_withNonInternalURL_returnsFalse() {
        let url = URL(string: "https://example.com")!
        XCTAssertFalse(CertificateHelper.isBadCertDomainErrorPage(url: url))
    }
}
