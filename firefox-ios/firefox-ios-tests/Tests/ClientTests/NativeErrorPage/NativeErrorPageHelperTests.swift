// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

final class NativeErrorPageHelperTests: XCTestCase {
    // MARK: - Helpers

    private func makeBadCertDomainError(
        code: Int = NSURLErrorServerCertificateUntrusted
    ) -> NSError {
        let underlying = NSError(
            domain: "NSURLErrorDomain",
            code: code,
            userInfo: ["_kCFStreamErrorCodeKey": -9843]
        )
        return NSError(
            domain: NSURLErrorDomain,
            code: code,
            userInfo: [NSUnderlyingErrorKey: underlying]
        )
    }

    private func makeOtherCertError(
        code: Int = NSURLErrorServerCertificateUntrusted,
        cfStreamCode: Int = -9813
    ) -> NSError {
        let underlying = NSError(
            domain: "NSURLErrorDomain",
            code: code,
            userInfo: ["_kCFStreamErrorCodeKey": cfStreamCode]
        )
        return NSError(
            domain: NSURLErrorDomain,
            code: code,
            userInfo: [NSUnderlyingErrorKey: underlying]
        )
    }

    // MARK: - isCertificateErrorCode

    func testIsCertificateErrorCode_returnsTrueForAllKnownCertCodes() {
        let certCodes = [
            NSURLErrorServerCertificateUntrusted,
            NSURLErrorServerCertificateHasBadDate,
            NSURLErrorServerCertificateHasUnknownRoot,
            NSURLErrorServerCertificateNotYetValid
        ]
        for code in certCodes {
            XCTAssertTrue(
                NativeErrorPageHelper.isCertificateErrorCode(code),
                "Expected cert code \(code) to return true"
            )
        }
    }

    func testIsCertificateErrorCode_returnsFalseForNoInternetError() {
        let noInternetCode = Int(CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue)
        XCTAssertFalse(NativeErrorPageHelper.isCertificateErrorCode(noInternetCode))
    }

    func testIsCertificateErrorCode_returnsFalseForArbitraryCode() {
        XCTAssertFalse(NativeErrorPageHelper.isCertificateErrorCode(0))
        XCTAssertFalse(NativeErrorPageHelper.isCertificateErrorCode(42))
    }

    // MARK: - isBadCertDomainError

    func testIsBadCertDomainError_returnsTrueWhenStreamCodeIs9843() {
        let error = makeBadCertDomainError()
        XCTAssertTrue(NativeErrorPageHelper.isBadCertDomainError(error))
    }

    func testIsBadCertDomainError_returnsFalseForOtherCertErrors() {
        let error = makeOtherCertError()
        XCTAssertFalse(NativeErrorPageHelper.isBadCertDomainError(error))
    }

    func testIsBadCertDomainError_returnsFalseWhenUnderlyingErrorIsMissing() {
        let error = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorServerCertificateUntrusted,
            userInfo: [:]
        )
        XCTAssertFalse(NativeErrorPageHelper.isBadCertDomainError(error))
    }

    func testIsBadCertDomainError_returnsFalseWhenStreamErrorKeyIsMissing() {
        let underlying = NSError(
            domain: "NSURLErrorDomain",
            code: NSURLErrorServerCertificateUntrusted,
            userInfo: [:]
        )
        let error = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorServerCertificateUntrusted,
            userInfo: [NSUnderlyingErrorKey: underlying]
        )
        XCTAssertFalse(NativeErrorPageHelper.isBadCertDomainError(error))
    }

    func testIsBadCertDomainError_returnsFalseForNonCertTopLevelCode() {
        let noInternetCode = Int(CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue)
        let underlying = NSError(
            domain: "NSURLErrorDomain",
            code: noInternetCode,
            userInfo: ["_kCFStreamErrorCodeKey": -9843]
        )
        let error = NSError(
            domain: NSURLErrorDomain,
            code: noInternetCode,
            userInfo: [NSUnderlyingErrorKey: underlying]
        )
        XCTAssertFalse(NativeErrorPageHelper.isBadCertDomainError(error))
    }

    // MARK: - shouldShowNativeBadCertDomainErrorPage

    func testShouldShowNativeBadCertDomainErrorPage_returnsTrueWhenFlagEnabledAndBadCertDomain() {
        let error = makeBadCertDomainError()
        XCTAssertTrue(
            NativeErrorPageHelper.shouldShowNativeBadCertDomainErrorPage(
                for: error,
                isOtherErrorPagesEnabled: true
            )
        )
    }

    func testShouldShowNativeBadCertDomainErrorPage_returnsFalseWhenFlagDisabled() {
        let error = makeBadCertDomainError()
        XCTAssertFalse(
            NativeErrorPageHelper.shouldShowNativeBadCertDomainErrorPage(
                for: error,
                isOtherErrorPagesEnabled: false
            )
        )
    }

    func testShouldShowNativeBadCertDomainErrorPage_returnsFalseForOtherCertError() {
        let error = makeOtherCertError()
        XCTAssertFalse(
            NativeErrorPageHelper.shouldShowNativeBadCertDomainErrorPage(
                for: error,
                isOtherErrorPagesEnabled: true
            )
        )
    }

    func testShouldShowNativeBadCertDomainErrorPage_returnsFalseForNoInternetError() {
        let noInternetCode = Int(CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue)
        let error = NSError(domain: NSURLErrorDomain, code: noInternetCode, userInfo: [:])
        XCTAssertFalse(
            NativeErrorPageHelper.shouldShowNativeBadCertDomainErrorPage(
                for: error,
                isOtherErrorPagesEnabled: true
            )
        )
    }

    // MARK: - isBadCertDomainErrorURL

    func testIsBadCertDomainErrorURL_returnsTrueForBadCertDomainCertCode() {
        let url = URL(string: "http://example.com/errorpage?code=\(NSURLErrorServerCertificateUntrusted)&certerror=SSL_ERROR_BAD_CERT_DOMAIN")!
        XCTAssertTrue(NativeErrorPageHelper.isBadCertDomainErrorURL(url))
    }

    func testIsBadCertDomainErrorURL_returnsFalseForNonBadCertDomainCertError() {
        let url = URL(string: "http://example.com/errorpage?code=\(NSURLErrorServerCertificateUntrusted)&certerror=SEC_ERROR_UNKNOWN_ISSUER")!
        XCTAssertFalse(NativeErrorPageHelper.isBadCertDomainErrorURL(url))
    }

    func testIsBadCertDomainErrorURL_returnsFalseForNonCertErrorCodeEvenIfParamMatches() {
        let url = URL(string: "http://example.com/errorpage?code=\(Int(CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue))&certerror=SSL_ERROR_BAD_CERT_DOMAIN")!
        XCTAssertFalse(NativeErrorPageHelper.isBadCertDomainErrorURL(url))
    }

    func testIsBadCertDomainErrorURL_returnsFalseWhenCertErrorParamMissing() {
        let url = URL(string: "http://example.com/errorpage?code=\(NSURLErrorServerCertificateUntrusted)")!
        XCTAssertFalse(NativeErrorPageHelper.isBadCertDomainErrorURL(url))
    }

    func testIsBadCertDomainErrorURL_returnsFalseWhenCodeParamMissing() {
        let url = URL(string: "http://example.com/errorpage?certerror=SSL_ERROR_BAD_CERT_DOMAIN")!
        XCTAssertFalse(NativeErrorPageHelper.isBadCertDomainErrorURL(url))
    }
}
