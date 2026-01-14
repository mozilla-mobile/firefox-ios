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
    
    // MARK: - Legacy Mode Tests (Empty Flows)
    
    func testNormalize_withEmptyFlows_returnsCardsUnchanged() {
        // Given: Legacy mode configuration (empty flows)
        let cards = createTestCards()
        let flows: [String: NimbusOnboardingFlow] = [:]
        let conditions = createTestConditions()
        
        // When: Normalizing
        let result = normalizer.normalize(
            cards: cards,
            flows: flows,
            conditions: conditions,
            onboardingVariant: .modern,
            onboardingType: .freshInstall
        )
        
        // Then: Cards passed through unchanged
        XCTAssertEqual(result.count, cards.count)
        XCTAssertEqual(Set(result.keys), Set(cards.keys))
        // Verify each card's properties are preserved
        for (key, originalCard) in cards {
            guard let resultCard = result[key] else {
                XCTFail("Card '\(key)' missing in result")
                continue
            }
            XCTAssertEqual(resultCard.title, originalCard.title)
            XCTAssertEqual(resultCard.body, originalCard.body)
            XCTAssertEqual(resultCard.order, originalCard.order)
            XCTAssertEqual(resultCard.onboardingType, originalCard.onboardingType)
        }
        XCTAssertTrue(normalizer.stepOrderOverrides.isEmpty)
    }
    
    func testNormalize_withEmptyFlows_preservesAllCardProperties() {
        // Given: Cards with various properties
        let cards = [
            "welcome": createCard(
                name: "welcome",
                order: 1,
                title: "Welcome Title",
                body: "Welcome Body",
                variant: .modern
            ),
            "sync": createCard(
                name: "sync",
                order: 2,
                title: "Sync Title",
                body: "Sync Body",
                variant: nil
            )
        ]
        let flows: [String: NimbusOnboardingFlow] = [:]
        
        // When: Normalizing
        let result = normalizer.normalize(
            cards: cards,
            flows: flows,
            conditions: [:],
            onboardingVariant: .modern,
            onboardingType: .freshInstall
        )
        
        // Then: All properties preserved
        XCTAssertEqual(result["welcome"]?.title, "Welcome Title")
        XCTAssertEqual(result["welcome"]?.body, "Welcome Body")
        XCTAssertEqual(result["welcome"]?.order, 1)
        XCTAssertEqual(result["sync"]?.title, "Sync Title")
    }
    
    // MARK: - Flow Mode Tests
    
    func testNormalize_withFlows_expandsFlowsToCards() {
        // Given: Flow-based configuration
        let cards = createTestCards()
        let flows: [String: NimbusOnboardingFlow] = [
            "test-flow": NimbusOnboardingFlow(
                dismissable: false,
                flowName: "test-flow",
                onboardingType: .freshInstall,
                prerequisites: [],
                steps: [
                    NimbusOnboardingFlowStep(
                        cardReference: "welcome",
                        order: 1,
                        prerequisites: []
                    ),
                    NimbusOnboardingFlowStep(
                        cardReference: "sync",
                        order: 2,
                        prerequisites: []
                    )
                ],
                uiVariant: nil
            )
        ]
        
        // When: Normalizing
        let result = normalizer.normalize(
            cards: cards,
            flows: flows,
            conditions: [:],
            onboardingVariant: .modern,
            onboardingType: .freshInstall
        )
        
        // Then: Flow expanded to cards
        XCTAssertEqual(result.count, 2)
        XCTAssertNotNil(result["test-flow-step-0"])
        XCTAssertNotNil(result["test-flow-step-1"])
        XCTAssertEqual(normalizer.stepOrderOverrides["test-flow-step-0"], 1)
        XCTAssertEqual(normalizer.stepOrderOverrides["test-flow-step-1"], 2)
    }
    
    func testNormalize_withFlows_filtersByOnboardingType() {
        // Given: Flows with different onboarding types
        let cards = createTestCards()
        let flows: [String: NimbusOnboardingFlow] = [
            "fresh-flow": NimbusOnboardingFlow(
                dismissable: false,
                flowName: "fresh-flow",
                onboardingType: .freshInstall,
                prerequisites: [],
                steps: [
                    NimbusOnboardingFlowStep(cardReference: "welcome", order: 1, prerequisites: [])
                ],
                uiVariant: nil
            ),
            "upgrade-flow": NimbusOnboardingFlow(
                dismissable: false,
                flowName: "upgrade-flow",
                onboardingType: .upgrade,
                prerequisites: [],
                steps: [
                    NimbusOnboardingFlowStep(cardReference: "sync", order: 1, prerequisites: [])
                ],
                uiVariant: nil
            )
        ]
        
        // When: Normalizing for fresh install
        let result = normalizer.normalize(
            cards: cards,
            flows: flows,
            conditions: [:],
            onboardingVariant: .modern,
            onboardingType: .freshInstall
        )
        
        // Then: Only fresh install flow included
        XCTAssertEqual(result.count, 1)
        XCTAssertNotNil(result["fresh-flow-step-0"])
        XCTAssertNil(result["upgrade-flow-step-0"])
    }
    
    func testNormalize_withFlows_filtersByUIVariant() {
        // Given: Flows with different UI variants
        let cards = createTestCards()
        let flows: [String: NimbusOnboardingFlow] = [
            "modern-flow": NimbusOnboardingFlow(
                dismissable: false,
                flowName: "modern-flow",
                onboardingType: .freshInstall,
                prerequisites: [],
                steps: [
                    NimbusOnboardingFlowStep(cardReference: "welcome", order: 1, prerequisites: [])
                ],
                uiVariant: .some(.modern)
            ),
            "japan-flow": NimbusOnboardingFlow(
                dismissable: false,
                flowName: "japan-flow",
                onboardingType: .freshInstall,
                prerequisites: [],
                steps: [
                    NimbusOnboardingFlowStep(cardReference: "sync", order: 1, prerequisites: [])
                ],
                uiVariant: .some(.japan)
            )
        ]
        
        // When: Normalizing for modern variant
        let result = normalizer.normalize(
            cards: cards,
            flows: flows,
            conditions: [:],
            onboardingVariant: .modern,
            onboardingType: .freshInstall
        )
        
        // Then: Only modern flow included
        XCTAssertEqual(result.count, 1)
        XCTAssertNotNil(result["modern-flow-step-0"])
        XCTAssertNil(result["japan-flow-step-0"])
    }
    
    func testNormalize_withFlows_nilUIVariant_appliesToAllVariants() {
        // Given: Flow with nil UI variant
        let cards = createTestCards()
        let flows: [String: NimbusOnboardingFlow] = [
            "universal-flow": NimbusOnboardingFlow(
                dismissable: false,
                flowName: "universal-flow",
                onboardingType: .freshInstall,
                prerequisites: [],
                steps: [
                    NimbusOnboardingFlowStep(cardReference: "welcome", order: 1, prerequisites: [])
                ],
                uiVariant: nil
            )
        ]
        
        // When: Normalizing for different variants
        let modernResult = normalizer.normalize(
            cards: cards,
            flows: flows,
            conditions: [:],
            onboardingVariant: .modern,
            onboardingType: .freshInstall
        )
        
        let japanResult = normalizer.normalize(
            cards: cards,
            flows: flows,
            conditions: [:],
            onboardingVariant: .japan,
            onboardingType: .freshInstall
        )
        
        // Then: Flow applies to all variants
        XCTAssertEqual(modernResult.count, 1)
        XCTAssertEqual(japanResult.count, 1)
    }
    
    func testNormalize_withFlows_skipsMissingCardReferences() {
        // Given: Flow with invalid card reference
        let cards = createTestCards()
        let flows: [String: NimbusOnboardingFlow] = [
            "test-flow": NimbusOnboardingFlow(
                dismissable: false,
                flowName: "test-flow",
                onboardingType: .freshInstall,
                prerequisites: [],
                steps: [
                    NimbusOnboardingFlowStep(cardReference: "welcome", order: 1, prerequisites: []),
                    NimbusOnboardingFlowStep(cardReference: "nonexistent", order: 2, prerequisites: []),
                    NimbusOnboardingFlowStep(cardReference: "sync", order: 3, prerequisites: [])
                ]
            )
        ]
        
        // When: Normalizing
        let result = normalizer.normalize(
            cards: cards,
            flows: flows,
            conditions: [:],
            onboardingVariant: .modern,
            onboardingType: .freshInstall
        )
        
        // Then: Missing card skipped, others included
        XCTAssertEqual(result.count, 2)
        XCTAssertNotNil(result["test-flow-step-0"])
        XCTAssertNil(result["test-flow-step-1"])
        XCTAssertNotNil(result["test-flow-step-2"])
    }
    
    func testNormalize_withFlows_evaluatesFlowPrerequisites() {
        // Given: Flow with prerequisites
        let cards = createTestCards()
        let flows: [String: NimbusOnboardingFlow] = [
            "conditional-flow": NimbusOnboardingFlow(
                dismissable: false,
                flowName: "conditional-flow",
                onboardingType: .freshInstall,
                prerequisites: ["ALWAYS"],
                steps: [
                    NimbusOnboardingFlowStep(cardReference: "welcome", order: 1, prerequisites: [])
                ],
                uiVariant: nil
            ),
            "blocked-flow": NimbusOnboardingFlow(
                dismissable: false,
                flowName: "blocked-flow",
                onboardingType: .freshInstall,
                prerequisites: ["NEVER"],
                steps: [
                    NimbusOnboardingFlowStep(cardReference: "sync", order: 1, prerequisites: [])
                ],
                uiVariant: nil
            )
        ]
        let conditions = createTestConditions()
        
        // When: Normalizing
        let result = normalizer.normalize(
            cards: cards,
            flows: flows,
            conditions: conditions,
            onboardingVariant: .modern,
            onboardingType: .freshInstall
        )
        
        // Then: Only flow with met prerequisites included
        XCTAssertEqual(result.count, 1)
        XCTAssertNotNil(result["conditional-flow-step-0"])
        XCTAssertNil(result["blocked-flow-step-0"])
    }
    
    func testNormalize_withFlows_evaluatesStepPrerequisites() {
        // Given: Flow with step-level prerequisites
        let cards = createTestCards()
        let flows: [String: NimbusOnboardingFlow] = [
            "test-flow": NimbusOnboardingFlow(
                dismissable: false,
                flowName: "test-flow",
                onboardingType: .freshInstall,
                prerequisites: [],
                steps: [
                    NimbusOnboardingFlowStep(cardReference: "welcome", order: 1, prerequisites: ["ALWAYS"]),
                    NimbusOnboardingFlowStep(cardReference: "sync", order: 2, prerequisites: ["NEVER"]),
                    NimbusOnboardingFlowStep(cardReference: "welcome", order: 3, prerequisites: ["ALWAYS"])
                ]
            )
        ]
        let conditions = createTestConditions()
        
        // When: Normalizing
        let result = normalizer.normalize(
            cards: cards,
            flows: flows,
            conditions: conditions,
            onboardingVariant: .modern,
            onboardingType: .freshInstall
        )
        
        // Then: Only steps with met prerequisites included
        XCTAssertEqual(result.count, 2)
        XCTAssertNotNil(result["test-flow-step-0"])
        XCTAssertNil(result["test-flow-step-1"])
        XCTAssertNotNil(result["test-flow-step-2"])
    }
    
    func testNormalize_withFlows_appliesStepOrderOverrides() {
        // Given: Flow with custom step orders
        let cards = createTestCards()
        let flows: [String: NimbusOnboardingFlow] = [
            "test-flow": NimbusOnboardingFlow(
                dismissable: false,
                flowName: "test-flow",
                onboardingType: .freshInstall,
                prerequisites: [],
                steps: [
                    NimbusOnboardingFlowStep(cardReference: "welcome", order: 10, prerequisites: []),
                    NimbusOnboardingFlowStep(cardReference: "sync", order: 5, prerequisites: []),
                    NimbusOnboardingFlowStep(cardReference: "welcome", order: 1, prerequisites: [])
                ]
            )
        ]
        
        // When: Normalizing
        _ = normalizer.normalize(
            cards: cards,
            flows: flows,
            conditions: [:],
            onboardingVariant: .modern,
            onboardingType: .freshInstall
        )
        
        // Then: Step order overrides stored
        XCTAssertEqual(normalizer.stepOrderOverrides["test-flow-step-0"], 10)
        XCTAssertEqual(normalizer.stepOrderOverrides["test-flow-step-1"], 5)
        XCTAssertEqual(normalizer.stepOrderOverrides["test-flow-step-2"], 1)
    }
    
    func testNormalize_withFlows_handlesEmptyFlowName() {
        // Given: Flow with empty name
        let cards = createTestCards()
        let flows: [String: NimbusOnboardingFlow] = [
            "": NimbusOnboardingFlow(
                dismissable: false,
                flowName: "",
                onboardingType: .freshInstall,
                prerequisites: [],
                steps: [
                    NimbusOnboardingFlowStep(cardReference: "welcome", order: 1, prerequisites: [])
                ],
                uiVariant: nil
            )
        ]
        
        // When: Normalizing
        let result = normalizer.normalize(
            cards: cards,
            flows: flows,
            conditions: [:],
            onboardingVariant: .modern,
            onboardingType: .freshInstall
        )
        
        // Then: Uses default flow name
        XCTAssertEqual(result.count, 1)
        XCTAssertNotNil(result["flow-step-0"])
    }
    
    func testNormalize_withFlows_handlesMultipleFlows() {
        // Given: Multiple applicable flows
        let cards = createTestCards()
        let flows: [String: NimbusOnboardingFlow] = [
            "flow1": NimbusOnboardingFlow(
                dismissable: false,
                flowName: "flow1",
                onboardingType: .freshInstall,
                prerequisites: [],
                steps: [
                    NimbusOnboardingFlowStep(cardReference: "welcome", order: 1, prerequisites: [])
                ],
                uiVariant: nil
            ),
            "flow2": NimbusOnboardingFlow(
                dismissable: false,
                flowName: "flow2",
                onboardingType: .freshInstall,
                prerequisites: [],
                steps: [
                    NimbusOnboardingFlowStep(cardReference: "sync", order: 1, prerequisites: [])
                ],
                uiVariant: nil
            )
        ]
        
        // When: Normalizing
        let result = normalizer.normalize(
            cards: cards,
            flows: flows,
            conditions: [:],
            onboardingVariant: .modern,
            onboardingType: .freshInstall
        )
        
        // Then: Both flows expanded
        XCTAssertEqual(result.count, 2)
        XCTAssertNotNil(result["flow1-step-0"])
        XCTAssertNotNil(result["flow2-step-0"])
    }
    
    // MARK: - Edge Cases
    
    func testNormalize_withEmptyCards_returnsEmptyDictionary() {
        // Given: Empty cards
        let cards: [String: NimbusOnboardingCardData] = [:]
        let flows: [String: NimbusOnboardingFlow] = [:]
        
        // When: Normalizing
        let result = normalizer.normalize(
            cards: cards,
            flows: flows,
            conditions: [:],
            onboardingVariant: .modern,
            onboardingType: .freshInstall
        )
        
        // Then: Returns empty dictionary
        XCTAssertTrue(result.isEmpty)
    }
    
    func testNormalize_clearsStepOrderOverridesOnEachCall() {
        // Given: Cards for normalization
        let cards = createTestCards()
        
        // When: Normalizing multiple times
        let result1 = normalizer.normalize(
            cards: cards,
            flows: [:],
            conditions: [:],
            onboardingVariant: .modern,
            onboardingType: .freshInstall
        )
        
        let result2 = normalizer.normalize(
            cards: cards,
            flows: [:],
            conditions: [:],
            onboardingVariant: .modern,
            onboardingType: .freshInstall
        )
        
        // Then: Step order overrides cleared between calls
        XCTAssertTrue(normalizer.stepOrderOverrides.isEmpty)
        // Verify both results have same keys and properties
        XCTAssertEqual(result1.count, result2.count)
        XCTAssertEqual(Set(result1.keys), Set(result2.keys))
        for key in result1.keys {
            guard let card1 = result1[key], let card2 = result2[key] else {
                XCTFail("Card '\(key)' missing in one of the results")
                continue
            }
            XCTAssertEqual(card1.title, card2.title)
            XCTAssertEqual(card1.body, card2.body)
            XCTAssertEqual(card1.order, card2.order)
        }
    }
    
    func testNormalize_withHelperCreationFailure_fallsBackToLegacyMode() {
        // Given: Mock helper that fails to create helper
        let failingHelper = FailingNimbusMessagingHelperUtility()
        let normalizerWithFailingHelper = OnboardingConfigurationNormalizer(helperUtility: failingHelper)
        let cards = createTestCards()
        
        // When: Normalizing
        let result = normalizerWithFailingHelper.normalize(
            cards: cards,
            flows: [:], // Empty flows = legacy mode anyway
            conditions: [:],
            onboardingVariant: OnboardingVariant.modern,
            onboardingType: OnboardingType.freshInstall
        )
        
        // Then: Falls back gracefully
        XCTAssertEqual(result.count, cards.count)
    }
    
    // MARK: - Integration Tests: Brand Refresh Flow
    
    func testNormalize_withBrandRefreshFlow_expandsToFourCards() {
        // Given: Brand Refresh flow with 4 steps
        let cards = createBrandRefreshCards()
        let flows: [String: NimbusOnboardingFlow] = [
            "brand-refresh-flow": NimbusOnboardingFlow(
                dismissable: true,
                flowName: "brand-refresh-flow",
                onboardingType: .freshInstall,
                prerequisites: [],
                steps: [
                    NimbusOnboardingFlowStep(cardReference: "welcome-brand-refresh", order: 1, prerequisites: []),
                    NimbusOnboardingFlowStep(cardReference: "customization-toolbar-brand-refresh", order: 2, prerequisites: []),
                    NimbusOnboardingFlowStep(cardReference: "customization-theme-brand-refresh", order: 3, prerequisites: []),
                    NimbusOnboardingFlowStep(cardReference: "sign-to-sync-brand-refresh", order: 4, prerequisites: [])
                ],
                uiVariant: .some(.brandRefresh)
            )
        ]
        
        // When: Normalizing for brand refresh variant
        let result = normalizer.normalize(
            cards: cards,
            flows: flows,
            conditions: createTestConditions(),
            onboardingVariant: .brandRefresh,
            onboardingType: .freshInstall
        )
        
        // Then: Flow expanded to 4 cards
        XCTAssertEqual(result.count, 4)
        XCTAssertNotNil(result["brand-refresh-flow-step-0"])
        XCTAssertNotNil(result["brand-refresh-flow-step-1"])
        XCTAssertNotNil(result["brand-refresh-flow-step-2"])
        XCTAssertNotNil(result["brand-refresh-flow-step-3"])
        
        // Verify step order overrides
        XCTAssertEqual(normalizer.stepOrderOverrides["brand-refresh-flow-step-0"], 1)
        XCTAssertEqual(normalizer.stepOrderOverrides["brand-refresh-flow-step-1"], 2)
        XCTAssertEqual(normalizer.stepOrderOverrides["brand-refresh-flow-step-2"], 3)
        XCTAssertEqual(normalizer.stepOrderOverrides["brand-refresh-flow-step-3"], 4)
    }
    
    func testNormalize_withBrandRefreshFlow_onlyAppliesToBrandRefreshVariant() {
        // Given: Brand Refresh flow
        let cards = createBrandRefreshCards()
        let flows: [String: NimbusOnboardingFlow] = [
            "brand-refresh-flow": NimbusOnboardingFlow(
                dismissable: true,
                flowName: "Brand Refresh Onboarding",
                onboardingType: .freshInstall,
                prerequisites: [],
                steps: [
                    NimbusOnboardingFlowStep(cardReference: "welcome-brand-refresh", order: 1, prerequisites: [])
                ],
                uiVariant: .some(.brandRefresh)
            )
        ]
        
        // When: Normalizing for different variants
        let brandRefreshResult = normalizer.normalize(
            cards: cards,
            flows: flows,
            conditions: createTestConditions(),
            onboardingVariant: .brandRefresh,
            onboardingType: .freshInstall
        )
        
        let modernResult = normalizer.normalize(
            cards: cards,
            flows: flows,
            conditions: createTestConditions(),
            onboardingVariant: .modern,
            onboardingType: .freshInstall
        )
        
        // Then: Flow only applies to brand refresh variant
        XCTAssertEqual(brandRefreshResult.count, 1)
        XCTAssertEqual(modernResult.count, 0)
    }
    
    // MARK: - Variable-Length Flow Tests
    
    func testNormalize_withVariableLengthFlow_conditionallyIncludesSteps() {
        // Given: Flow with conditional steps (4-6 cards based on prerequisites)
        let cards = createTestCards()
        let flows: [String: NimbusOnboardingFlow] = [
            "variable-flow": NimbusOnboardingFlow(
                dismissable: false,
                flowName: "variable-flow",
                onboardingType: .freshInstall,
                prerequisites: [],
                steps: [
                    NimbusOnboardingFlowStep(cardReference: "welcome", order: 1, prerequisites: ["ALWAYS"]),
                    NimbusOnboardingFlowStep(cardReference: "sync", order: 2, prerequisites: ["ALWAYS"]),
                    NimbusOnboardingFlowStep(cardReference: "notifications", order: 3, prerequisites: ["ALWAYS"]),
                    NimbusOnboardingFlowStep(cardReference: "welcome", order: 4, prerequisites: ["CONDITIONAL"]),
                    NimbusOnboardingFlowStep(cardReference: "sync", order: 5, prerequisites: ["CONDITIONAL"]),
                    NimbusOnboardingFlowStep(cardReference: "welcome", order: 6, prerequisites: ["ALWAYS"])
                ],
                uiVariant: nil
            )
        ]
        var conditions = createTestConditions()
        conditions["CONDITIONAL"] = "true"
        
        // When: Normalizing with conditional prerequisites met
        let resultWithConditional = normalizer.normalize(
            cards: cards,
            flows: flows,
            conditions: conditions,
            onboardingVariant: .modern,
            onboardingType: .freshInstall
        )
        
        // Then: All 6 steps included
        XCTAssertEqual(resultWithConditional.count, 6)
        
        // When: Normalizing with conditional prerequisites not met
        conditions["CONDITIONAL"] = "false"
        let resultWithoutConditional = normalizer.normalize(
            cards: cards,
            flows: flows,
            conditions: conditions,
            onboardingVariant: .modern,
            onboardingType: .freshInstall
        )
        
        // Then: Only 4 steps included (conditional steps skipped)
        XCTAssertEqual(resultWithoutConditional.count, 4)
        XCTAssertNotNil(resultWithoutConditional["variable-flow-step-0"])
        XCTAssertNotNil(resultWithoutConditional["variable-flow-step-1"])
        XCTAssertNotNil(resultWithoutConditional["variable-flow-step-2"])
        XCTAssertNil(resultWithoutConditional["variable-flow-step-3"])
        XCTAssertNil(resultWithoutConditional["variable-flow-step-4"])
        XCTAssertNotNil(resultWithoutConditional["variable-flow-step-5"])
    }
    
    func testNormalize_withVariableLengthFlow_differentLengthsForDifferentConditions() {
        // Given: Flow with multiple conditional paths
        let cards = createTestCards()
        let flows: [String: NimbusOnboardingFlow] = [
            "adaptive-flow": NimbusOnboardingFlow(
                dismissable: false,
                flowName: "adaptive-flow",
                onboardingType: .freshInstall,
                prerequisites: [],
                steps: [
                    NimbusOnboardingFlowStep(cardReference: "welcome", order: 1, prerequisites: ["ALWAYS"]),
                    NimbusOnboardingFlowStep(cardReference: "sync", order: 2, prerequisites: ["SHOW_SYNC"]),
                    NimbusOnboardingFlowStep(cardReference: "notifications", order: 3, prerequisites: ["SHOW_NOTIFICATIONS"]),
                    NimbusOnboardingFlowStep(cardReference: "welcome", order: 4, prerequisites: ["ALWAYS"])
                ],
                uiVariant: nil
            )
        ]
        
        // When: Both conditions met (4 cards)
        var conditions = createTestConditions()
        conditions["SHOW_SYNC"] = "true"
        conditions["SHOW_NOTIFICATIONS"] = "true"
        let resultAll = normalizer.normalize(
            cards: cards,
            flows: flows,
            conditions: conditions,
            onboardingVariant: .modern,
            onboardingType: .freshInstall
        )
        XCTAssertEqual(resultAll.count, 4)
        
        // When: Only sync condition met (3 cards)
        conditions["SHOW_NOTIFICATIONS"] = "false"
        let resultSyncOnly = normalizer.normalize(
            cards: cards,
            flows: flows,
            conditions: conditions,
            onboardingVariant: .modern,
            onboardingType: .freshInstall
        )
        XCTAssertEqual(resultSyncOnly.count, 3)
        XCTAssertNotNil(resultSyncOnly["adaptive-flow-step-0"])
        XCTAssertNotNil(resultSyncOnly["adaptive-flow-step-1"])
        XCTAssertNil(resultSyncOnly["adaptive-flow-step-2"])
        XCTAssertNotNil(resultSyncOnly["adaptive-flow-step-3"])
        
        // When: Neither condition met (2 cards)
        conditions["SHOW_SYNC"] = "false"
        let resultMinimal = normalizer.normalize(
            cards: cards,
            flows: flows,
            conditions: conditions,
            onboardingVariant: .modern,
            onboardingType: .freshInstall
        )
        XCTAssertEqual(resultMinimal.count, 2)
        XCTAssertNotNil(resultMinimal["adaptive-flow-step-0"])
        XCTAssertNil(resultMinimal["adaptive-flow-step-1"])
        XCTAssertNil(resultMinimal["adaptive-flow-step-2"])
        XCTAssertNotNil(resultMinimal["adaptive-flow-step-3"])
    }
    
    // MARK: - Helper Methods
    
    private func createTestCards() -> [String: NimbusOnboardingCardData] {
        return [
            "welcome": createCard(
                name: "welcome",
                order: 1,
                title: "Welcome",
                body: "Welcome to Firefox",
                variant: .modern
            ),
            "sync": createCard(
                name: "sync",
                order: 2,
                title: "Sync",
                body: "Sync your data",
                variant: nil
            ),
            "notifications": createCard(
                name: "notifications",
                order: 3,
                title: "Notifications",
                body: "Enable notifications",
                variant: .modern
            )
        ]
    }
    
    private func createCard(
        name: String,
        order: Int,
        title: String,
        body: String,
        variant: OnboardingVariant?
    ) -> NimbusOnboardingCardData {
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
            uiVariant: variant
        )
    }
    
    private func createTestConditions() -> [String: String] {
        return [
            "ALWAYS": "true",
            "NEVER": "false"
        ]
    }
    
    private func createBrandRefreshCards() -> [String: NimbusOnboardingCardData] {
        return [
            "welcome-brand-refresh": createCard(
                name: "welcome-brand-refresh",
                order: 10,
                title: "Welcome Brand Refresh",
                body: "Welcome to Firefox Brand Refresh",
                variant: .brandRefresh
            ),
            "customization-toolbar-brand-refresh": createCard(
                name: "customization-toolbar-brand-refresh",
                order: 20,
                title: "Customize Toolbar",
                body: "Customize your toolbar",
                variant: .brandRefresh
            ),
            "customization-theme-brand-refresh": createCard(
                name: "customization-theme-brand-refresh",
                order: 25,
                title: "Choose Theme",
                body: "Choose your theme",
                variant: .brandRefresh
            ),
            "sign-to-sync-brand-refresh": createCard(
                name: "sign-to-sync-brand-refresh",
                order: 30,
                title: "Sign In to Sync",
                body: "Sync your data",
                variant: .brandRefresh
            )
        ]
    }
}

// MARK: - Mock Helper for Testing Helper Creation Failure

private class FailingNimbusMessagingHelperUtility: NimbusMessagingHelperUtilityProtocol, @unchecked Sendable {
    required init(logger: Logger = DefaultLogger.shared) { }
    
    func createNimbusMessagingHelper() -> NimbusMessagingHelperProtocol? {
        return nil
    }
}
