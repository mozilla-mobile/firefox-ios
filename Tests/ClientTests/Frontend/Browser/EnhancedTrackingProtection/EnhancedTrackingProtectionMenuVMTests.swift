// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
@testable import Client

class EnhancedTrackingProtectionMenuVMTests: XCTestCase {
    func test_websiteTitle_whenURLHasBaseDomainDeliversCorrectTitle() {
        let sut = makeSUT(url: URL(string: "https://firefox.com")!)

        XCTAssertEqual(sut.websiteTitle, "firefox.com")
    }

    func test_websiteTitle_whenURLDoesNotHaveBaseDomainDeliversEmptyTitle() {
        let sut = makeSUT(url: URL(string: "https://192.168.0.1:8080/path/to/resource")!)

        XCTAssertEqual(sut.websiteTitle, "")
    }

    func test_connectionStatusString_whenConnectionIsSecureDeliversCorrectStatus() {
        let sut = makeSUT(connectionSecure: true)

        XCTAssertEqual(sut.connectionStatusString, .ProtectionStatusSecure)
    }

    func test_connectionStatusString_whenConnectionIsNotSecureDeliversCorrectStatus() {
        let sut = makeSUT(connectionSecure: false)

        XCTAssertEqual(sut.connectionStatusString, .ProtectionStatusNotSecure)
    }

    func test_isSiteETPEnabled_whenStatusIsNoBlockerURLsDeliversCorrectResult() {
        let sut = makeSUT(contentBlockerStatus: .noBlockedURLs)

        XCTAssertTrue(sut.isSiteETPEnabled)
    }

    func test_isSiteETPEnabled_whenStatusIsBlockingDeliversCorrectResult() {
        let sut = makeSUT(contentBlockerStatus: .blocking)

        XCTAssertTrue(sut.isSiteETPEnabled)
    }

    func test_isSiteETPEnabled_whenStatusIsDisabledDeliversCorrectResult() {
        let sut = makeSUT(contentBlockerStatus: .disabled)

        XCTAssertTrue(sut.isSiteETPEnabled)
    }

    func test_isSiteETPEnabled_whenStatusIsSafelistedDeliversCorrectResult() {
        let sut = makeSUT(contentBlockerStatus: .safelisted)

        XCTAssertFalse(sut.isSiteETPEnabled)
    }

    func test_getDetailsViewModel_deliversCorrectResult() {
        let sut = makeSUT(url: URL(string: "https://firefox.com")!,
                          displayTitle: "Firefox",
                          connectionSecure: true)

        let detailsVM = sut.getDetailsViewModel()

        XCTAssertEqual(detailsVM.topLevelDomain, "firefox.com")
        XCTAssertEqual(detailsVM.title, "Firefox")
        XCTAssertEqual(detailsVM.URL, "https://firefox.com")
        XCTAssertEqual(detailsVM.connectionStatusMessage, .ProtectionStatusSecure)
        XCTAssertTrue(detailsVM.connectionSecure)
    }

    // MARK: Helpers

    private func makeSUT(
        url: URL = URL(string: "https://any-url.com")!,
        displayTitle: String = "any",
        connectionSecure: Bool = true,
        globalETPIsEnabled: Bool = true,
        contentBlockerStatus: BlockerStatus = .blocking) -> EnhancedTrackingProtectionMenuVM {
        EnhancedTrackingProtectionMenuVM(
            url: url,
            displayTitle: displayTitle,
            connectionSecure: connectionSecure,
            globalETPIsEnabled: globalETPIsEnabled,
            contentBlockerStatus: contentBlockerStatus)
    }
}
