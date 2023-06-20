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
