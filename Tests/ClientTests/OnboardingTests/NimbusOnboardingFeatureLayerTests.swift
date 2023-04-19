// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaRustComponents
import XCTest
@testable import Client

class NimbusOnboardingFeatureLayerTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testLayer_dismissable_isTrue() {
        setupNimbusWith(cards: nil, cardOrdering: nil, dismissable: true)
        let subject = NimbusOnboardingFeatureLayer()

        XCTAssertTrue(subject.dismissable)
    }

//    func testGetNimbusCards() {
//        let subject = NimbusOnboardingFeatureLayer(nimbus: nimbus)
//        let cards = subject.getNimbusCards()
//        XCTAssertEqual(cards.count, 0)
//    }

    // MARK: - Helpers
    private func setupNimbusWith(
        cards: String?,
        cardOrdering: String?,
        dismissable: Bool?
    ) {
        guard let dismissable = dismissable else { return }

        let features = HardcodedNimbusFeatures(with: [
            "onboarding-framework-feature": """
              {
                "dismissable": \(dismissable),
              }
            """
        ])

        features.connect(with: FxNimbus.shared)
    }
}
