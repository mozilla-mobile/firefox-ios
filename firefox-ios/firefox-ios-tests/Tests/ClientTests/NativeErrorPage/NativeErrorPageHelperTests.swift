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

    // MARK: - buildErrorPageQueryItems

    func testBuildErrorPageQueryItems_nonCertError_returnsURLAndCodeOnly() {
        let url = URL(string: "https://example.com")!
        let noInternetCode = Int(CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue)
        let error = NSError(domain: NSURLErrorDomain, code: noInternetCode, userInfo: [:])

        let items = NativeErrorPageHelper.buildErrorPageQueryItems(for: error, url: url)

        XCTAssertEqual(items.count, 2)
        XCTAssertTrue(items.contains(where: { $0.name == "url" && $0.value == url.absoluteString }))
        XCTAssertTrue(items.contains(where: { $0.name == "code" && $0.value == String(noInternetCode) }))
    }

    func testBuildErrorPageQueryItems_certErrorWithCFStreamCode_includesCertErrorQueryItem() {
        let url = URL(string: "https://example.com")!
        let error = makeBadCertDomainError()

        let items = NativeErrorPageHelper.buildErrorPageQueryItems(for: error, url: url)

        XCTAssertTrue(items.contains(where: { $0.name == "certerror" && $0.value == "SSL_ERROR_BAD_CERT_DOMAIN" }))
        XCTAssertTrue(items.contains(where: { $0.name == "code" }))
    }

    func testBuildErrorPageQueryItems_certErrorWithoutCFStreamCode_doesNotIncludeCertErrorItem() {
        let url = URL(string: "https://example.com")!
        let error = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorServerCertificateUntrusted,
            userInfo: [:]
        )

        let items = NativeErrorPageHelper.buildErrorPageQueryItems(for: error, url: url)

        XCTAssertFalse(items.contains(where: { $0.name == "certerror" }))
    }

    // MARK: - parseErrorDetails

    func testParseErrorDetails_noInternetError_withURL_returnsNoInternetModel() {
        let url = URL(string: "https://example.com")!
        let noInternetCode = Int(CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue)
        let error = NSError(domain: NSURLErrorDomain, code: noInternetCode, userInfo: [
            NSURLErrorFailingURLErrorKey: url
        ])
        let helper = NativeErrorPageHelper(error: error)

        let model = helper.parseErrorDetails()

        XCTAssertEqual(model.foxImageName, ImageIdentifiers.NativeErrorPage.noInternetConnection)
        XCTAssertNil(model.url)
    }

    func testParseErrorDetails_noFailingURL_returnsNoInternetModel() {
        let noInternetCode = Int(CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue)
        let error = NSError(domain: NSURLErrorDomain, code: noInternetCode, userInfo: [:])
        let helper = NativeErrorPageHelper(error: error)

        let model = helper.parseErrorDetails()

        XCTAssertEqual(model.foxImageName, ImageIdentifiers.NativeErrorPage.noInternetConnection)
        XCTAssertNil(model.url)
    }

    func testParseErrorDetails_certError_withURL_returnsSecurityModel() {
        let url = URL(string: "https://example.com")!
        let error = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorServerCertificateUntrusted,
            userInfo: [NSURLErrorFailingURLErrorKey: url]
        )
        let helper = NativeErrorPageHelper(error: error)

        let model = helper.parseErrorDetails()

        XCTAssertEqual(model.foxImageName, ImageIdentifiers.NativeErrorPage.securityError)
    }

    func testParseErrorDetails_certErrorBadCertDomain_returnsAdvancedSection() {
        let url = URL(string: "https://example.com")!
        let error = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorServerCertificateUntrusted,
            userInfo: [
                NSURLErrorFailingURLErrorKey: url,
                NSUnderlyingErrorKey: NSError(
                    domain: "NSURLErrorDomain",
                    code: NSURLErrorServerCertificateUntrusted,
                    userInfo: ["_kCFStreamErrorCodeKey": -9843]
                )
            ]
        )
        let helper = NativeErrorPageHelper(error: error)

        let model = helper.parseErrorDetails()

        XCTAssertNotNil(model.advancedSection)
        XCTAssertTrue(model.showGoBackButton)
    }

    func testParseErrorDetails_genericError_withURL_returnsGenericModel() {
        let url = URL(string: "https://example.com")!
        let error = NSError(domain: NSURLErrorDomain, code: -1, userInfo: [
            NSURLErrorFailingURLErrorKey: url
        ])
        let helper = NativeErrorPageHelper(error: error)

        let model = helper.parseErrorDetails()

        XCTAssertEqual(model.foxImageName, ImageIdentifiers.NativeErrorPage.securityError)
        XCTAssertNil(model.advancedSection)
    }

    // MARK: - getCertDetails

    func testGetCertDetails_missingFailingURL_returnsNil() {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorServerCertificateUntrusted, userInfo: [:])
        let helper = NativeErrorPageHelper(error: error)

        XCTAssertNil(helper.getCertDetails())
    }

    func testGetCertDetails_missingCertChain_returnsNil() {
        let url = URL(string: "https://example.com")!
        let error = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorServerCertificateUntrusted,
            userInfo: [NSURLErrorFailingURLErrorKey: url]
        )
        let helper = NativeErrorPageHelper(error: error)

        XCTAssertNil(helper.getCertDetails())
    }

    func testParseErrorDetails_certCodeWithNonURLErrorDomain_returnsGenericModel() {
        let url = URL(string: "https://example.com")!
        let error = NSError(
            domain: "SomeOtherDomain",
            code: NSURLErrorServerCertificateUntrusted,
            userInfo: [NSURLErrorFailingURLErrorKey: url]
        )
        let helper = NativeErrorPageHelper(error: error)

        let model = helper.parseErrorDetails()

        XCTAssertEqual(model.foxImageName, ImageIdentifiers.NativeErrorPage.securityError)
        XCTAssertNil(model.advancedSection)
    }
}
