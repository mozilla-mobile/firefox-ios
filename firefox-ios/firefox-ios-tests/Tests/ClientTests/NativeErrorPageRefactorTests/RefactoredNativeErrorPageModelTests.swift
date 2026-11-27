// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

final class RefactoredNativeErrorPageModelTests: XCTestCase {
    private let originalURL = URL(string: "https://example.com")!

    func testNoInternet_showsNoInternetPage() throws {
        let subject = try createSubject(type: .noInternet)

        XCTAssertEqual(subject.title, .NativeErrorPage.NoInternet.TitleLabel)
        XCTAssertEqual(subject.primaryButton, .tryAgain)
        XCTAssertNil(subject.advanced)
    }

    func testNoResponse_showsNoResponsePage() throws {
        let subject = try createSubject(type: .noResponse)

        XCTAssertEqual(subject.title, .NativeErrorPage.NoResponse.TitleLabel)
        XCTAssertTrue(subject.description.contains("example.com"))
        XCTAssertEqual(subject.primaryButton, .tryAgain)
        XCTAssertNil(subject.advanced)
    }

    func testVPN_showsVPNPage() throws {
        let subject = try createSubject(type: .vpn)

        XCTAssertEqual(subject.title, .VPN.ErrorPage.Title)
        XCTAssertEqual(subject.primaryButton, .tryAgain)
        XCTAssertNil(subject.advanced)
    }

    func testGeneric_showsGenericPage() throws {
        let subject = try createSubject(type: .generic)

        XCTAssertEqual(subject.title, .NativeErrorPage.Generic.TitleLabel)
        XCTAssertTrue(subject.description.contains("example.com"))
        XCTAssertEqual(subject.primaryButton, .tryAgain)
        XCTAssertNil(subject.advanced)
    }

    func testWayback_showsGenericPage() throws {
        let subject = try createSubject(type: .wayback)

        XCTAssertEqual(subject.title, .NativeErrorPage.Generic.TitleLabel)
        XCTAssertNil(subject.advanced)
    }

    func testBadCert_showsSecurityPageWithAdvanced() throws {
        let subject = try createSubject(type: .badCert)

        XCTAssertEqual(subject.title, .NativeErrorPage.Security.TitleLabel)
        XCTAssertEqual(subject.primaryButton, .goBack)
        XCTAssertNotNil(subject.advanced)
    }

    func testBadCert_withoutCertificate_hasNoProceedButton() throws {
        let subject = try createSubject(type: .badCert)

        XCTAssertNil(subject.advanced?.proceedTitle)
    }

    func testBadCert_withCertificate_hasProceedButton() throws {
        let subject = try createSubject(type: .badCert, certificateData: Data("certificate".utf8))

        let proceedTitle = try XCTUnwrap(subject.advanced?.proceedTitle)
        XCTAssertTrue(proceedTitle.contains("example.com"))
    }

    func testErrorCode_isPassedThrough() throws {
        let subject = try createSubject(type: .generic, errorCode: NSURLErrorCannotFindHost)

        XCTAssertEqual(subject.errorCode, NSURLErrorCannotFindHost)
    }

    // MARK: - Helpers

    private func createSubject(
        type: NativeErrorPageType,
        errorCode: Int = -1,
        certificateData: Data? = nil
    ) throws -> RefactoredNativeErrorPageModel {
        let errorPage = try XCTUnwrap(NativeErrorPageURL.make(type: type,
                                                              originalURL: originalURL,
                                                              errorCode: errorCode,
                                                              certificateData: certificateData))
        return RefactoredNativeErrorPageModel(errorPage: errorPage)
    }
}
