// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MozillaAppServices
import Shared
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
        let layer = NimbusOnboardingFeatureLayer()
        let subject = layer.getOnboardingModel()

        XCTAssertTrue(subject.dismissable)
    }

    // MARK: - Helpers
    private func setupNimbusWith(
        cards: String?,
        cardOrdering: String?,
        dismissable: Bool?
    ) {
        guard let dismissable = dismissable else { return }

        let f = HardcodedNimbusFeatures(with: ["":""])
//        let features = HardcodedNimbusFeatures(with: [
//            "onboarding-framework-feature": """
//              {
//                "dismissable": \(dismissable),
//              }
//            """
//        ])

//        features.connect(with: FxNimbus.shared)
    }
}
