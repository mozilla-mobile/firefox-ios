// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import SwiftUI
import Common
@testable import Client
@testable import Ecosia

final class FeedbackThemeTests: XCTestCase {

    // MARK: - Integration Tests

    func testIntegrationWithFeedbackView() {
        // Given
        let windowUUID: WindowUUID = .XCTestDefaultUUID
        let feedbackView = FeedbackView(windowUUID: windowUUID)

        // When/Then
        let viewMirror = Mirror(reflecting: feedbackView)
        XCTAssertNotNil(viewMirror.descendant("_theme"))

        // Also verify that the body contains our ThemeModifier (the Ecosia one we made)
        let bodyMirror = Mirror(reflecting: feedbackView.body)
        XCTAssertTrue(bodyMirror.description.contains("ThemeModifier"))
    }
}
