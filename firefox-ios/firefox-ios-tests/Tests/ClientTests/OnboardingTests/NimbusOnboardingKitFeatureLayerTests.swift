// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import XCTest
import OnboardingKit

@testable import Client

class NimbusOnboardingKitFeatureLayerTests: XCTestCase {
    typealias CardElementNames = NimbusOnboardingTestingConfigUtility.CardElementNames

    var configUtility: NimbusOnboardingTestingConfigUtility!
    var mockHelper: MockNimbusMessagingHelperUtility!

    override func setUp() {
        super.setUp()
        configUtility = NimbusOnboardingTestingConfigUtility()
        mockHelper = MockNimbusMessagingHelperUtility()
    }

    override func tearDown() {
        configUtility = nil
        mockHelper = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInit_withDefaultValues_setsCorrectDefaults() {
        let subject = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        XCTAssertEqual(subject.onboardingVariant, .modern)
    }

    func testInit_withCustomValues_setsCorrectValues() {
        let subject = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .japan,
            with: mockHelper,
            isDefaultBrowser: true,
            isIpad: true)

        XCTAssertEqual(subject.onboardingVariant, .japan)
    }

    // MARK: - OnboardingVariant Filtering Tests

    func testGetOnboardingModel_withModernVariant_returnsOnlyModernCards() {
        setupNimbusWithMixedVariants()
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        XCTAssertEqual(subject.cards.count, 2)
        XCTAssertTrue(subject.cards.allSatisfy { $0.name.contains("Modern") })
    }

    func testGetOnboardingModel_withJapanVariant_returnsOnlyJapanCards() {
        setupNimbusWithMixedVariants()
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .japan,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        XCTAssertEqual(subject.cards.count, 2)
        XCTAssertTrue(subject.cards.allSatisfy { $0.name.contains("Japan") })
    }

    func testGetOnboardingModel_withLegacyVariant_returnsOnlyLegacyCards() {
        setupNimbusWithMixedVariants()
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .legacy,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        XCTAssertEqual(subject.cards.count, 2)
        XCTAssertTrue(subject.cards.allSatisfy { $0.name.contains("Legacy") })
    }

    // MARK: - OnboardingType Filtering Tests

    func testGetOnboardingModel_freshInstall_returnsOnlyFreshInstallCards() {
        setupNimbusWithMixedOnboardingTypes()
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        XCTAssertEqual(subject.cards.count, 2)
        XCTAssertTrue(subject.cards.allSatisfy { $0.onboardingType == .freshInstall })
    }

    func testGetOnboardingModel_upgrade_returnsOnlyUpgradeCards() {
        setupNimbusWithMixedOnboardingTypes()
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .upgrade)

        XCTAssertEqual(subject.cards.count, 2)
        XCTAssertTrue(subject.cards.allSatisfy { $0.onboardingType == .upgrade })
    }

    // MARK: - iPad-Specific Filtering Tests

    func testGetOnboardingModel_onIPad_filtersOutToolbarTopCards() {
        setupNimbusWithToolbarCards()
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper,
            isDefaultBrowser: false,
            isIpad: true)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        XCTAssertFalse(subject.cards.contains { card in
            card.multipleChoiceButtons.contains { $0.action == .toolbarTop }
        })
    }

    func testGetOnboardingModel_onIPad_filtersOutToolbarBottomCards() {
        setupNimbusWithToolbarCards()
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper,
            isDefaultBrowser: false,
            isIpad: true)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        XCTAssertFalse(subject.cards.contains { card in
            card.multipleChoiceButtons.contains { $0.action == .toolbarBottom }
        })
    }

    func testGetOnboardingModel_onIPhone_includesToolbarCards() {
        setupNimbusWithToolbarCards()
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper,
            isDefaultBrowser: false,
            isIpad: false)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        XCTAssertTrue(subject.cards.contains { card in
            card.multipleChoiceButtons.contains { $0.action == .toolbarTop || $0.action == .toolbarBottom }
        })
    }

    func testGetOnboardingModel_onIPad_keepsNonToolbarCards() {
        setupNimbusWithMixedCards()
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper,
            isDefaultBrowser: false,
            isIpad: true)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        XCTAssertGreaterThan(subject.cards.count, 0)
    }

    // MARK: - Default Browser Filtering Tests

    func testGetOnboardingModel_isDefaultBrowser_filtersOutCardsWithOpenIosFxSettingsPopup() {
        setupNimbusWithOpenIosFxSettingsPopupCards()
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper,
            isDefaultBrowser: true,
            isIpad: false)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        XCTAssertFalse(subject.cards.contains { $0.instructionsPopup?.buttonAction == .openIosFxSettings })
    }

    func testGetOnboardingModel_isNotDefaultBrowser_includesCardsWithOpenIosFxSettingsPopup() {
        setupNimbusWithOpenIosFxSettingsPopupCards()
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper,
            isDefaultBrowser: false,
            isIpad: false)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        XCTAssertTrue(subject.cards.contains { $0.instructionsPopup?.buttonAction == .openIosFxSettings })
    }

    func testGetOnboardingModel_isDefaultBrowser_keepsCardsWithoutOpenIosFxSettingsPopup() {
        setupNimbusWithOpenIosFxSettingsPopupCards()
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper,
            isDefaultBrowser: true,
            isIpad: false)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        XCTAssertGreaterThan(subject.cards.count, 0)
        XCTAssertTrue(subject.cards.allSatisfy { $0.instructionsPopup?.buttonAction != .openIosFxSettings })
    }

    func testGetOnboardingModel_isDefaultBrowser_filtersMultipleCardsWithOpenIosFxSettingsPopup() {
        setupNimbusWithMultipleOpenIosFxSettingsCards()
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper,
            isDefaultBrowser: true,
            isIpad: false)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        XCTAssertEqual(subject.cards.count, 1)
        XCTAssertFalse(subject.cards.contains { $0.instructionsPopup?.buttonAction == .openIosFxSettings })
    }

    // MARK: - Combined Filtering Tests

    func testGetOnboardingModel_iPadAndDefaultBrowser_appliesBothFilters() {
        setupNimbusWithComplexScenario()
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper,
            isDefaultBrowser: true,
            isIpad: true)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        XCTAssertFalse(subject.cards.contains { $0.instructionsPopup?.buttonAction == .openIosFxSettings })
        XCTAssertFalse(subject.cards.contains { card in
            card.multipleChoiceButtons.contains { $0.action == .toolbarTop || $0.action == .toolbarBottom }
        })
    }

    // MARK: - Card Ordering Tests

    func testGetOnboardingModel_cardsReturnedInCorrectOrder() {
        setupNimbusWithMultipleCardsInOrder()
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        for (index, card) in subject.cards.enumerated() {
            XCTAssertEqual(card.order, index + 1)
        }
    }

    func testGetOnboardingModel_afterFiltering_maintainsOrder() {
        setupNimbusWithCardsToFilter()
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper,
            isDefaultBrowser: true,
            isIpad: false)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        var previousOrder = 0
        for card in subject.cards {
            XCTAssertGreaterThan(card.order, previousOrder)
            previousOrder = card.order
        }
    }

    func testGetOnboardingModel_withGapsInOrdering_sortsCorrectly() {
        setupNimbusWithGappedOrdering()
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        XCTAssertEqual(subject.cards[0].order, 1)
        XCTAssertEqual(subject.cards[1].order, 5)
        XCTAssertEqual(subject.cards[2].order, 10)
    }

    // MARK: - A11y ID Root Tests

    func testGetOnboardingModel_freshInstall_hasCorrectA11yIdRoot() {
        setupNimbusWithVariousWelcomeCards(onboardingType: .freshInstall)
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        guard let card = subject.cards.first else {
            XCTFail("Expected a card")
            return
        }
        XCTAssertTrue(card.a11yIdRoot.hasPrefix("onboarding."))
    }

    func testGetOnboardingModel_upgrade_hasCorrectA11yIdRoot() {
        setupNimbusWithVariousWelcomeCards(onboardingType: .upgrade)
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .upgrade)

        guard let card = subject.cards.first else {
            XCTFail("Expected a card")
            return
        }
        XCTAssertTrue(card.a11yIdRoot.hasPrefix("upgrade."))
    }

    func testGetOnboardingModel_a11yIdRoot_updatesWithIndexAfterFiltering() {
        setupNimbusWithCardsToFilter()
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper,
            isDefaultBrowser: true,
            isIpad: false)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        for (index, card) in subject.cards.enumerated() {
            XCTAssertTrue(card.a11yIdRoot.hasSuffix("\(index)"))
        }
    }

    func testGetOnboardingModel_multipleCards_hasSequentialA11yIndices() {
        setupNimbusCardsFromActions([.forwardOneCard, .syncSignIn, .requestNotifications], variant: .modern)
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        XCTAssertEqual(subject.cards.count, 3)
        XCTAssertTrue(subject.cards[0].a11yIdRoot.hasSuffix("0"))
        XCTAssertTrue(subject.cards[1].a11yIdRoot.hasSuffix("1"))
        XCTAssertTrue(subject.cards[2].a11yIdRoot.hasSuffix("2"))
    }

    // MARK: - Button Mapping Tests

    func testGetOnboardingCardButtons_withPrimaryButton_mapsCorrectly() {
        configUtility.setupNimbusWith(withSecondaryButton: false, uiVariant: .modern)
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        guard let card = subject.cards.first else {
            XCTFail("Expected a card")
            return
        }
        XCTAssertEqual(card.buttons.primary.title, CardElementNames.primaryButtonTitle)
        XCTAssertEqual(card.buttons.primary.action, .forwardOneCard)
    }

    func testGetOnboardingCardButtons_withSecondaryButton_mapsCorrectly() {
        configUtility.setupNimbusWith(withSecondaryButton: true, uiVariant: .modern)
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        guard let card = subject.cards.first else {
            XCTFail("Expected a card")
            return
        }
        XCTAssertNotNil(card.buttons.secondary)
        XCTAssertEqual(card.buttons.secondary?.title, CardElementNames.secondaryButtonTitle)
    }

    func testGetOnboardingCardButtons_withoutSecondaryButton_hasNil() {
        configUtility.setupNimbusWith(withSecondaryButton: false, uiVariant: .modern)
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        guard let card = subject.cards.first else {
            XCTFail("Expected a card")
            return
        }
        XCTAssertNil(card.buttons.secondary)
    }

    func testGetOnboardingCardButtons_titleFormatting_replacesAppNamePlaceholder() {
        setupNimbusWithPlaceholderText()
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        guard let card = subject.cards.first else {
            XCTFail("Expected a card")
            return
        }
        XCTAssertTrue(card.buttons.primary.title.contains("Firefox"))
    }

    // MARK: - Multiple Choice Button Tests

    func testGetOnboardingMultipleChoiceButtons_empty_returnsEmptyArray() {
        configUtility.setupNimbusWith(uiVariant: .modern)
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        guard let card = subject.cards.first else {
            XCTFail("Expected a card")
            return
        }
        XCTAssertTrue(card.multipleChoiceButtons.isEmpty)
    }

    func testGetOnboardingMultipleChoiceButtons_withButtons_mapsCorrectly() {
        setupNimbusWithMultipleChoiceButtons()
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        guard let card = subject.cards.first else {
            XCTFail("Expected a card")
            return
        }
        XCTAssertEqual(card.multipleChoiceButtons.count, 2)
    }

    func testGetOnboardingMultipleChoiceButtons_imageIDMapping_isCorrect() {
        setupNimbusWithMultipleChoiceButtons()
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        guard let card = subject.cards.first else {
            XCTFail("Expected a card")
            return
        }
        XCTAssertFalse(card.multipleChoiceButtons.first?.imageID.isEmpty ?? true)
    }

    // MARK: - Link Tests

    func testGetOnboardingLink_withValidLink_createsLinkModel() {
        configUtility.setupNimbusWith(shouldAddLink: true, uiVariant: .modern)
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        guard let card = subject.cards.first else {
            XCTFail("Expected a card")
            return
        }
        XCTAssertNotNil(card.link)
        XCTAssertEqual(card.link?.title, CardElementNames.linkTitle)
        XCTAssertEqual(card.link?.url.absoluteString, CardElementNames.linkURL)
    }

    func testGetOnboardingLink_withNilLink_returnsNil() {
        configUtility.setupNimbusWith(shouldAddLink: false, uiVariant: .modern)
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        guard let card = subject.cards.first else {
            XCTFail("Expected a card")
            return
        }
        XCTAssertNil(card.link)
    }

    func testGetOnboardingLink_withInvalidURL_returnsNil() {
        setupNimbusWithInvalidURL()
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        guard let card = subject.cards.first else {
            XCTFail("Expected a card")
            return
        }
        XCTAssertNil(card.link)
    }

    // MARK: - Popup Info Model Tests

    func testGetPopupInfoModel_withValidData_createsModel() {
        configUtility.setupNimbusWith(uiVariant: .modern)
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        guard let card = subject.cards.first else {
            XCTFail("Expected a card")
            return
        }
        XCTAssertNotNil(card.instructionsPopup)
        XCTAssertEqual(card.instructionsPopup?.title, CardElementNames.popupTitle)
    }

    func testGetPopupInfoModel_instructionsFormatting_replacesAppNamePlaceholder() {
        setupNimbusWithPopupPlaceholders()
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        guard let card = subject.cards.first,
              let popup = card.instructionsPopup else {
            XCTFail("Expected a card with popup")
            return
        }
        XCTAssertTrue(popup.instructionSteps.allSatisfy { $0.contains("Firefox") })
    }

    // MARK: - Condition Evaluation Tests

    func testGetOnboardingCards_prerequisiteAlways_includesCard() {
        configUtility.setupNimbusWith(prerequisites: ["ALWAYS"], uiVariant: .modern)
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        XCTAssertEqual(subject.cards.count, 1)
    }

    func testGetOnboardingCards_prerequisiteNever_excludesCard() {
        configUtility.setupNimbusWith(prerequisites: ["NEVER"])
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .legacy,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        XCTAssertEqual(subject.cards.count, 0)
    }

    func testGetOnboardingCards_disqualifierAlways_excludesCard() {
        configUtility.setupNimbusWith(disqualifiers: ["ALWAYS"])
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        XCTAssertEqual(subject.cards.count, 0)
    }

    func testGetOnboardingCards_disqualifierNever_includesCard() {
        configUtility.setupNimbusWith(disqualifiers: ["NEVER"], uiVariant: .modern)
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        XCTAssertEqual(subject.cards.count, 1)
    }

    func testGetOnboardingCards_prerequisiteAndDisqualifier_evaluatesBoth() {
        configUtility.setupNimbusWith(
            prerequisites: ["ALWAYS"],
            disqualifiers: ["NEVER"],
            uiVariant: .modern
        )
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        XCTAssertEqual(subject.cards.count, 1)
    }

    // MARK: - String Formatting Tests

    func testStringFormatting_title_replacesAppNamePlaceholder() {
        setupNimbusWithTitlePlaceholder()
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        guard let card = subject.cards.first else {
            XCTFail("Expected a card")
            return
        }
        XCTAssertTrue(card.title.contains("Firefox"))
        XCTAssertFalse(card.title.contains("%@"))
    }

    func testStringFormatting_body_replacesMultiplePlaceholders() {
        setupNimbusWithBodyPlaceholders()
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        guard let card = subject.cards.first else {
            XCTFail("Expected a card")
            return
        }
        XCTAssertTrue(card.body.contains("Firefox"))
        XCTAssertFalse(card.body.contains("%@"))
    }

    // MARK: - ViewModel Construction Tests

    func testGetOnboardingModel_returnsCorrectViewModel() {
        configUtility.setupNimbusWith(uiVariant: .modern)
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        XCTAssertNotNil(subject)
        XCTAssertGreaterThan(subject.cards.count, 0)
    }

    func testGetOnboardingModel_dismissable_setsCorrectly() {
        configUtility.setupNimbusWith(
            dismissable: true,
            uiVariant: .modern
        )
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .legacy,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        XCTAssertTrue(subject.isDismissible)
    }

    func testGetOnboardingModel_cards_mapsAllProperties() {
        configUtility.setupNimbusWith(
            shouldAddLink: true,
            withSecondaryButton: true,
            uiVariant: .modern
        )
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        guard let card = subject.cards.first else {
            XCTFail("Expected a card")
            return
        }
        XCTAssertFalse(card.name.isEmpty)
        XCTAssertFalse(card.title.isEmpty)
        XCTAssertFalse(card.body.isEmpty)
        XCTAssertNotNil(card.link)
        XCTAssertNotNil(card.buttons.secondary)
        XCTAssertFalse(card.imageID.isEmpty)
    }

    // MARK: - Edge Cases

    func testGetOnboardingModel_noMatchingCards_returnsEmptyArray() {
        setupNimbusWithOnlyUpgradeCards()
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        XCTAssertEqual(subject.cards.count, 0)
    }

    func testGetOnboardingModel_emptyCardData_handlesGracefully() {
        setupNimbusWithEmptyCards()
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: .modern,
            with: mockHelper)

        let subject = layer.getOnboardingModel(for: .freshInstall)

        XCTAssertEqual(subject.cards.count, 0)
    }

    // MARK: - Helper Methods for Setup

    private func setupNimbusWithMixedVariants() {
        let cards: [String: NimbusOnboardingCardData] = [
            "Modern Card 1": createCard(variant: .modern, order: 1),
            "Modern Card 2": createCard(variant: .modern, order: 2),
            "Japan Card 1": createCard(variant: .japan, order: 3),
            "Japan Card 2": createCard(variant: .japan, order: 4),
            "Legacy Card 1": createCard(variant: .legacy, order: 5),
            "Legacy Card 2": createCard(variant: .legacy, order: 6)
        ]
        setupNimbus(with: cards)
    }

    private func setupNimbusWithMixedOnboardingTypes() {
        let cards: [String: NimbusOnboardingCardData] = [
            "Fresh Install 1": createCard(variant: .modern, order: 1, onboardingType: .freshInstall),
            "Fresh Install 2": createCard(variant: .modern, order: 2, onboardingType: .freshInstall),
            "Upgrade 1": createCard(variant: .modern, order: 3, onboardingType: .upgrade),
            "Upgrade 2": createCard(variant: .modern, order: 4, onboardingType: .upgrade)
        ]
        setupNimbus(with: cards)
    }

    private func setupNimbusWithToolbarCards() {
        let cards: [String: NimbusOnboardingCardData] = [
            "Toolbar Card": createCard(
                variant: .modern,
                order: 1,
                multipleChoiceButtons: [
                    createMultipleChoiceButton(action: .toolbarTop),
                    createMultipleChoiceButton(action: .toolbarBottom)
                ])
        ]
        setupNimbus(with: cards)
    }

    private func setupNimbusWithMixedCards() {
        let cards: [String: NimbusOnboardingCardData] = [
            "Regular Card": createCard(variant: .modern, order: 1),
            "Toolbar Card": createCard(
                variant: .modern,
                order: 2,
                multipleChoiceButtons: [createMultipleChoiceButton(action: .toolbarTop)])
        ]
        setupNimbus(with: cards)
    }

    private func setupNimbusWithOpenIosFxSettingsPopupCards() {
        let popupWithOpenSettings = NimbusOnboardingInstructionPopup(
            buttonAction: .openIosFxSettings,
            buttonTitle: "Open Settings",
            instructions: ["Step 1", "Step 2"],
            title: "Set Firefox as Default"
        )
        let cards: [String: NimbusOnboardingCardData] = [
            "Welcome Card": createCard(variant: .modern, order: 1, instructionsPopup: popupWithOpenSettings),
            "Sync Card": createCard(variant: .modern, order: 2)
        ]
        setupNimbus(with: cards)
    }

    private func setupNimbusWithMultipleOpenIosFxSettingsCards() {
        let popupWithOpenSettings = NimbusOnboardingInstructionPopup(
            buttonAction: .openIosFxSettings,
            buttonTitle: "Open Settings",
            instructions: ["Step 1", "Step 2"],
            title: "Set Firefox as Default"
        )
        let cards: [String: NimbusOnboardingCardData] = [
            "Welcome Card 1": createCard(variant: .modern, order: 1, instructionsPopup: popupWithOpenSettings),
            "Welcome Card 2": createCard(variant: .modern, order: 2, instructionsPopup: popupWithOpenSettings),
            "Sync Card": createCard(variant: .modern, order: 3)
        ]
        setupNimbus(with: cards)
    }

    private func setupNimbusWithVariousWelcomeCards(onboardingType: Client.OnboardingType = .freshInstall) {
        let cards: [String: NimbusOnboardingCardData] = [
            "Welcome Card": createCard(variant: .modern, order: 1, onboardingType: onboardingType),
            "WELCOME Card": createCard(variant: .modern, order: 2, onboardingType: onboardingType),
            "welcome Card": createCard(variant: .modern, order: 3, onboardingType: onboardingType),
            "Sync Card": createCard(variant: .modern, order: 4, onboardingType: onboardingType)
        ]
        setupNimbus(with: cards)
    }

    private func setupNimbusWithComplexScenario() {
        let popupWithOpenSettings = NimbusOnboardingInstructionPopup(
            buttonAction: .openIosFxSettings,
            buttonTitle: "Open Settings",
            instructions: ["Step 1", "Step 2"],
            title: "Set Firefox as Default"
        )
        let cards: [String: NimbusOnboardingCardData] = [
            "Welcome Card": createCard(variant: .modern, order: 1, instructionsPopup: popupWithOpenSettings),
            "Toolbar Card": createCard(
                variant: .modern,
                order: 2,
                multipleChoiceButtons: [createMultipleChoiceButton(action: .toolbarTop)]),
            "Sync Card": createCard(variant: .modern, order: 3)
        ]
        setupNimbus(with: cards)
    }

    private func setupNimbusWithMultipleCardsInOrder() {
        let cards: [String: NimbusOnboardingCardData] = [
            "Card 1": createCard(variant: .modern, order: 1),
            "Card 2": createCard(variant: .modern, order: 2),
            "Card 3": createCard(variant: .modern, order: 3)
        ]
        setupNimbus(with: cards)
    }

    private func setupNimbusWithCardsToFilter() {
        let cards: [String: NimbusOnboardingCardData] = [
            "Welcome Card": createCard(variant: .modern, order: 2),
            "Card 2": createCard(variant: .modern, order: 5),
            "Card 3": createCard(variant: .modern, order: 7)
        ]
        setupNimbus(with: cards)
    }

    private func setupNimbusWithGappedOrdering() {
        let cards: [String: NimbusOnboardingCardData] = [
            "Card 1": createCard(variant: .modern, order: 1),
            "Card 2": createCard(variant: .modern, order: 5),
            "Card 3": createCard(variant: .modern, order: 10)
        ]
        setupNimbus(with: cards)
    }

    private func setupNimbusWithPlaceholderText() {
        let cards: [String: NimbusOnboardingCardData] = [
            "Card": createCard(variant: .modern, order: 1, buttonTitle: "Welcome to %@")
        ]
        setupNimbus(with: cards)
    }

    private func setupNimbusWithMultipleChoiceButtons() {
        let cards: [String: NimbusOnboardingCardData] = [
            "Card": createCard(
                variant: .modern,
                order: 1,
                multipleChoiceButtons: [
                    createMultipleChoiceButton(action: .themeLight),
                    createMultipleChoiceButton(action: .themeDark)
                ])
        ]
        setupNimbus(with: cards)
    }

    private func setupNimbusWithInvalidURL() {
        let cards: [String: NimbusOnboardingCardData] = [
            "Card": createCard(variant: .modern, order: 1, linkURL: "not a valid url")
        ]
        setupNimbus(with: cards)
    }

    private func setupNimbusWithPopupPlaceholders() {
        let popup = NimbusOnboardingInstructionPopup(
            buttonAction: .dismiss,
            buttonTitle: "OK",
            instructions: ["Step 1: Open %@", "Step 2: Use %@"],
            title: "Instructions"
        )
        let cards: [String: NimbusOnboardingCardData] = [
            "Card": createCard(variant: .modern, order: 1, instructionsPopup: popup)
        ]
        setupNimbus(with: cards)
    }

    private func setupNimbusWithTitlePlaceholder() {
        let cards: [String: NimbusOnboardingCardData] = [
            "Card": createCard(variant: .modern, order: 1, title: "Welcome to %@")
        ]
        setupNimbus(with: cards)
    }

    private func setupNimbusWithBodyPlaceholders() {
        let cards: [String: NimbusOnboardingCardData] = [
            "Card": createCard(variant: .modern, order: 1, body: "%@ is great. Use %@ daily.")
        ]
        setupNimbus(with: cards)
    }

    private func setupNimbusWithOnlyUpgradeCards() {
        let cards: [String: NimbusOnboardingCardData] = [
            "Upgrade Card": createCard(variant: .modern, order: 1, onboardingType: .upgrade)
        ]
        setupNimbus(with: cards)
    }

    private func setupNimbusWithEmptyCards() {
        setupNimbus(with: [:])
    }

    private func setupNimbus(with cards: [String: NimbusOnboardingCardData]) {
        FxNimbus.shared.features.onboardingFrameworkFeature.with(initializer: { _, _ in
            OnboardingFrameworkFeature(cards: cards, dismissable: true)
        })
    }

    private func setupNimbusCardsFromActions(
        _ actions: [OnboardingActions],
        variant: OnboardingVariant,
        onboardingType: Client.OnboardingType = .freshInstall,
        multipleChoiceButtons: [NimbusOnboardingMultipleChoiceButton] = [],
        instructionsPopup: NimbusOnboardingInstructionPopup? = nil
    ) {
        var cards: [String: NimbusOnboardingCardData] = [:]

        for (index, action) in actions.enumerated() {
            let cardName = "Card \(index + 1)"
            let link: NimbusOnboardingLink? = nil

            cards[cardName] = NimbusOnboardingCardData(
                body: "Test Body \(index + 1)",
                buttons: NimbusOnboardingButtons(
                    primary: NimbusOnboardingButton(action: action, title: "Button \(index + 1)")
                ),
                cardType: .basic,
                disqualifiers: ["NEVER"],
                image: .welcomeGlobe,
                instructionsPopup: instructionsPopup,
                link: link,
                multipleChoiceButtons: multipleChoiceButtons,
                onboardingType: onboardingType,
                order: index + 1,
                prerequisites: ["ALWAYS"],
                title: "Test Title \(index + 1)",
                uiVariant: variant
            )
        }

        setupNimbus(with: cards)
    }

    private func createCard(
        variant: OnboardingVariant,
        order: Int,
        onboardingType: Client.OnboardingType = .freshInstall,
        title: String = "Test Title",
        body: String = "Test Body",
        buttonTitle: String = "Continue",
        linkURL: String? = nil,
        multipleChoiceButtons: [NimbusOnboardingMultipleChoiceButton] = [],
        instructionsPopup: NimbusOnboardingInstructionPopup? = nil
    ) -> NimbusOnboardingCardData {
        let link = linkURL.map { NimbusOnboardingLink(title: "Link", url: $0) }
        return NimbusOnboardingCardData(
            body: body,
            buttons: NimbusOnboardingButtons(
                primary: NimbusOnboardingButton(action: .forwardOneCard, title: buttonTitle)
            ),
            cardType: .basic,
            disqualifiers: ["NEVER"],
            image: .welcomeGlobe,
            instructionsPopup: instructionsPopup,
            link: link,
            multipleChoiceButtons: multipleChoiceButtons,
            onboardingType: onboardingType,
            order: order,
            prerequisites: ["ALWAYS"],
            title: title,
            uiVariant: variant
        )
    }

    private func createMultipleChoiceButton(
        action: Client.OnboardingMultipleChoiceAction
    ) -> NimbusOnboardingMultipleChoiceButton {
        return NimbusOnboardingMultipleChoiceButton(
            action: action,
            image: .themeLight,
            title: "Choice"
        )
    }
}
