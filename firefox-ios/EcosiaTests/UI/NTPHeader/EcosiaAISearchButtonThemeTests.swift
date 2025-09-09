// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import SwiftUI
import Common
@testable import Client
@testable import Ecosia

final class EcosiaAISearchButtonThemeTests: XCTestCase {

    // MARK: - Integration Tests

    @available(iOS 16.0, *)
    func testIntegrationWithButton() {
        // Given
        let windowUUID: WindowUUID = .XCTestDefaultUUID
        let button = EcosiaAISearchButton(windowUUID: windowUUID, onTap: {})

        // When/Then
        let buttonMirror = Mirror(reflecting: button)
        XCTAssertNotNil(buttonMirror.descendant("_theme"))

        // Also verify that the body contains our ThemeModifier (the Ecosia one we made)
        let bodyMirror = Mirror(reflecting: button.body)
        XCTAssertTrue(bodyMirror.description.contains("ThemeModifier"))
    }
}
