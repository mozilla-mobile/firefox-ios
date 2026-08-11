// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

@available(iOS 16.0, *)
@MainActor
final class EcosiaAccountImpactViewUserAgentTests: XCTestCase {

    func testInit_storesProvidedWebViewUserAgent() {
        // Given
        let expectedUserAgent = "Mozilla/5.0 (Ecosia ios@test)"

        // When
        let view = EcosiaAccountImpactView(
            viewModel: EcosiaAccountImpactViewModel(onLogin: {}, onDismiss: {}),
            windowUUID: .XCTestDefaultUUID,
            webViewUserAgent: expectedUserAgent
        )

        // Then
        XCTAssertEqual(
            mirrorString(from: view, label: "webViewUserAgent"),
            expectedUserAgent
        )
    }

    private func mirrorString(from object: Any, label: String) -> String? {
        Mirror(reflecting: object).children.first { $0.label == label }?.value as? String
    }
}
