// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import XCTest

@testable import Client

@MainActor
final class GoogleLensInterstitialViewControllerTests: XCTestCase {
    func testInitialization_configuresFullScreenBackdropForWindow() {
        let subject = GoogleLensInterstitialViewController(windowUUID: .XCTestDefaultUUID,
                                                           themeManager: MockThemeManager())
        subject.loadViewIfNeeded()

        XCTAssertEqual(subject.modalPresentationStyle, .overFullScreen)
        XCTAssertTrue(subject.isModalInPresentation)
        XCTAssertTrue(subject.view is GoogleLensInterstitialView)
        XCTAssertEqual(subject.currentWindowUUID, .XCTestDefaultUUID)
        XCTAssertNotNil(subject.themeListenerCancellable)
    }

    func testApplyTheme_resolvesCurrentWindowTheme() {
        let themeManager = MockThemeManager()
        let subject = GoogleLensInterstitialViewController(windowUUID: .XCTestDefaultUUID,
                                                           themeManager: themeManager)
        subject.loadViewIfNeeded()
        let previousCallCount = themeManager.getCurrentThemeCallCount
        themeManager.setManualTheme(to: .dark)

        subject.applyTheme()

        XCTAssertEqual(themeManager.getCurrentThemeCallCount, previousCallCount + 1)
    }
}
