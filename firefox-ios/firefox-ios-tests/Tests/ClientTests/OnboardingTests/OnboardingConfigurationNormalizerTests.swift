// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MozillaAppServices
import Common

@testable import Client

/// Tests for OnboardingConfigurationNormalizer
final class OnboardingConfigurationNormalizerTests: XCTestCase {
    var mockHelper: MockNimbusMessagingHelperUtility!
    var normalizer: OnboardingConfigurationNormalizer!

    override func setUp() {
        super.setUp()
        mockHelper = MockNimbusMessagingHelperUtility()
        normalizer = OnboardingConfigurationNormalizer(helperUtility: mockHelper)
    }

    override func tearDown() {
        normalizer = nil
        mockHelper = nil
        super.tearDown()
    }

    func testResolveActiveFlow_missingKey_returnsNil() {
        let flows = createTestFlows()
        let result = normalizer.resolveActiveFlow(
            activeFlowKey: nil,
            flows: flows,
            conditions: createTestConditions(),
            onboardingType: .freshInstall
        )
        XCTAssertNil(result)
    }

    func testResolveActiveFlow_invalidKey_returnsNil() {
        let flows = createTestFlows()
        let result = normalizer.resolveActiveFlow(
            activeFlowKey: "missing-flow",
            flows: flows,
            conditions: createTestConditions(),
            onboardingType: .freshInstall
        )
        XCTAssertNil(result)
    }

    func testResolveActiveFlow_onboardingTypeMismatch_returnsNil() {
        let flows = createTestFlows()
        let result = normalizer.resolveActiveFlow(
            activeFlowKey: "fresh-flow",
            flows: flows,
            conditions: createTestConditions(),
            onboardingType: .upgrade
        )
        XCTAssertNil(result)
    }

    func testResolveActiveFlow_prerequisitesFail_returnsNil() {
        let flow = createFlow(
            flowName: "blocked-flow",
            onboardingType: .freshInstall,
            prerequisites: ["NEVER"],
            cards: createTestCards()
        )
        let flows = ["blocked-flow": flow]

        let result = normalizer.resolveActiveFlow(
            activeFlowKey: "blocked-flow",
            flows: flows,
            conditions: createTestConditions(),
            onboardingType: .freshInstall
        )
        XCTAssertNil(result)
    }

    func testResolveActiveFlow_validFlow_returnsFlow() {
        let flows = createTestFlows()
        let result = normalizer.resolveActiveFlow(
            activeFlowKey: "fresh-flow",
            flows: flows,
            conditions: createTestConditions(),
            onboardingType: .freshInstall
        )
        XCTAssertEqual(result?.flowName, "fresh-flow")
        XCTAssertEqual(result?.cards.count, 2)
    }

    // MARK: - Helper Methods

    private func createTestFlows() -> [String: NimbusOnboardingFlow] {
        let flow = createFlow(
            flowName: "fresh-flow",
            onboardingType: .freshInstall,
            prerequisites: ["ALWAYS"],
            cards: createTestCards()
        )
        return ["fresh-flow": flow]
    }

    private func createFlow(
        flowName: String,
        onboardingType: OnboardingType,
        prerequisites: [String],
        cards: [NimbusOnboardingCardData],
        dismissable: Bool = false
    ) -> NimbusOnboardingFlow {
        return NimbusOnboardingFlow(
            flowName: flowName,
            onboardingType: onboardingType,
            prerequisites: prerequisites,
            dismissable: dismissable,
            cards: cards
        )
    }

    private func createTestCards() -> [NimbusOnboardingCardData] {
        return [
            createCard(order: 1, title: "Welcome", body: "Welcome to Firefox"),
            createCard(order: 2, title: "Sync", body: "Sync your data")
        ]
    }

    private func createCard(order: Int, title: String, body: String) -> NimbusOnboardingCardData {
        return NimbusOnboardingCardData(
            body: body,
            buttons: NimbusOnboardingButtons(
                primary: NimbusOnboardingButton(
                    action: .forwardOneCard,
                    title: "Continue"
                )
            ),
            cardType: .basic,
            disqualifiers: ["NEVER"],
            image: .welcomeGlobe,
            instructionsPopup: nil,
            link: nil,
            onboardingType: .freshInstall,
            order: order,
            prerequisites: ["ALWAYS"],
            title: title,
            uiVariant: nil
        )
    }

    private func createTestConditions() -> [String: String] {
        return [
            "ALWAYS": "true",
            "NEVER": "false"
        ]
    }
}
