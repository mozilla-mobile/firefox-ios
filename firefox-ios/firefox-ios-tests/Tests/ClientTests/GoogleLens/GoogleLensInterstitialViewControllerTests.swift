// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import XCTest

@testable import Client

@MainActor
final class GoogleLensInterstitialViewControllerTests: XCTestCase {
    func testApplyTheme_resolvesCurrentWindowTheme() {
        let themeManager = MockThemeManager()
        let subject = createSubject(themeManager: themeManager)

        subject.loadViewIfNeeded()

        let previousCallCount = themeManager.getCurrentThemeCallCount
        themeManager.setManualTheme(to: .dark)

        subject.applyTheme()

        XCTAssertEqual(themeManager.getCurrentThemeCallCount, previousCallCount + 1)
    }

    private func createSubject(themeManager: MockThemeManager = MockThemeManager(),
                               file: StaticString = #filePath,
                               line: UInt = #line) -> GoogleLensInterstitialViewController {
        let subject = GoogleLensInterstitialViewController(windowUUID: .XCTestDefaultUUID,
                                                           themeManager: themeManager)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
