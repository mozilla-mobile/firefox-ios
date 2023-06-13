// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MozillaAppServices
import Shared
import XCTest

@testable import Client

class NimbusOnboardingFeatureLayerTests: XCTestCase {
    struct CardElementNames {
        static let name = "Name"
        static let title = "Title"
        static let body = "Body"
        static let a11yIDOnboarding = "onboarding."
        static let a11yIDUpgrade = "upgrade."
        static let linkTitle = "MacRumors"
        static let linkURL = "https://macrumors.com"
        static let primaryButtonTitle = "Primary Button"
        static let secondaryButtonTitle = "Secondary Button"
        static let placeholderString = "A string inside %@ with a placeholder"
        static let noPlaceholderString = "On Wednesday's, we wear pink"
    }

    override func setUp() {
        super.setUp()
        let features = HardcodedNimbusFeatures(with: ["onboarding-framework-feature": ""])
        features.connect(with: FxNimbus.shared)
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Test placeholder methods
    func testLayer_placeholderNamingMethod_returnsExpectedStrigs() {
        setupNimbusForStringTesting()
        let expectedPlaceholderString = "A string inside Firefox with a placeholder"
        let expectedNoPlaceholderString = "On Wednesday's, we wear pink"
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.title, expectedPlaceholderString)
        XCTAssertEqual(subject.body, expectedNoPlaceholderString)
    }

    // MARK: - Test Dismissable
    func testLayer_dismissable_isTrue() {
        setupNimbusWith(dismissable: true)
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())
        let subject = layer.getOnboardingModel(for: .freshInstall)

        XCTAssertTrue(subject.isDismissable)
    }

    func testLayer_dismissable_isFalse() {
        setupNimbusWith(dismissable: false)
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())
        let subject = layer.getOnboardingModel(for: .freshInstall)

        XCTAssertFalse(subject.isDismissable)
    }

    // MARK: - Test A11yRoot
    func testLayer_a11yroot_isOnboarding() {
        setupNimbusWith(cards: 2)
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual(subject[0].a11yIdRoot, "\(CardElementNames.a11yIDOnboarding)0")
        XCTAssertEqual(subject[1].a11yIdRoot, "\(CardElementNames.a11yIDOnboarding)1")
    }

    func testLayer_a11yroot_isUpgrade() {
        setupNimbusWith(
            cards: 2,
            type: .upgrade)
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        let subject = layer.getOnboardingModel(for: .upgrade).cards

        XCTAssertEqual(subject[0].a11yIdRoot, "\(CardElementNames.a11yIDUpgrade)0")
        XCTAssertEqual(subject[1].a11yIdRoot, "\(CardElementNames.a11yIDUpgrade)1")
    }

    // MARK: - Test card(s) being returned
    func testLayer_cardIsReturned_OneCard() {
        setupNimbusWith(
            shouldAddLink: true,
            withSecondaryButton: true
        )
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        let expectedCard = OnboardingCardInfoModel(
            name: CardElementNames.name + " 1",
            order: 10,
            title: CardElementNames.title + " 1",
            body: CardElementNames.body + " 1",
            link: OnboardingLinkInfoModel(title: CardElementNames.linkTitle,
                                          url: URL(string: CardElementNames.linkURL)!),
            buttons: OnboardingButtons(
                primary: OnboardingButtonInfoModel(
                    title: CardElementNames.primaryButtonTitle,
                    action: .nextCard),
                secondary: OnboardingButtonInfoModel(
                    title: CardElementNames.secondaryButtonTitle,
                    action: .nextCard)),
            type: .freshInstall,
            a11yIdRoot: CardElementNames.a11yIDOnboarding,
            imageID: ImageIdentifiers.onboardingWelcomev106)

        XCTAssertEqual(subject.name, expectedCard.name)
        XCTAssertEqual(subject.title, expectedCard.title)
        XCTAssertEqual(subject.body, expectedCard.body)
        XCTAssertEqual(subject.type, expectedCard.type)
        XCTAssertEqual(subject.image, UIImage(named: ImageIdentifiers.onboardingWelcomev106))
        XCTAssertEqual(subject.link?.title, expectedCard.link?.title)
        XCTAssertEqual(subject.link?.url, expectedCard.link?.url)
        XCTAssertEqual(subject.buttons.primary.title, expectedCard.buttons.primary.title)
        XCTAssertEqual(subject.buttons.primary.action, expectedCard.buttons.primary.action)
        XCTAssertNotNil(subject.buttons.secondary)
        XCTAssertEqual(subject.buttons.secondary!.title, expectedCard.buttons.secondary!.title)
        XCTAssertEqual(subject.buttons.secondary!.action, expectedCard.buttons.secondary!.action)
    }

    func testLayer_cardsAreReturned_ThreeCardsReturned() {
        let expectedNumberOfCards = 3
        setupNimbusWith(cards: expectedNumberOfCards)
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual(expectedNumberOfCards, subject.count)
    }

    func testLayer_cardsAreReturned_InExpectedOrder() {
        let expectedNumberOfCards = 3
        setupNimbusWith(cards: expectedNumberOfCards)
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual("\(CardElementNames.name) 1", subject[0].name)
        XCTAssertEqual("\(CardElementNames.name) 2", subject[1].name)
        XCTAssertEqual("\(CardElementNames.name) 3", subject[2].name)
    }

    // MARK: - Test conditions
    // Conditions for cards are based on the feature's condition table. A card's
    // conditions (it's prerequisites & disqualifiers) get, respectively, reduced
    // down to a single boolean value. These tests will test the conditions
    // independently and then in a truth table fashion, reflecting real world evaulation
    //    - (T, T) (T, F), (F, T), and (F, F)
    // Testing for defaults was implicit in the previous tests, as defaults are:
    //    - prerequisities: true
    //    - disqualifiers: false
    func testLayer_conditionPrerequisiteAlways_returnsCard() {
        let expectedNumberOfCards = 1
        setupNimbusWith(prerequisites: ["ALWAYS"])
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual(expectedNumberOfCards, subject.count)
    }

    func testLayer_conditionPrerequisiteNever_returnsNoCard() {
        let expectedNumberOfCards = 0
        setupNimbusWith(prerequisites: ["NEVER"])
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual(expectedNumberOfCards, subject.count)
    }

    func testLayer_conditionDisqualifierAlways_returnsNoCard() {
        let expectedNumberOfCards = 0
        setupNimbusWith(disqualifiers: ["ALWAYS"])
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual(expectedNumberOfCards, subject.count)
    }

    func testLayer_conditionDesqualifierNever_returnsCard() {
        let expectedNumberOfCards = 1
        setupNimbusWith(disqualifiers: ["NEVER"])
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual(expectedNumberOfCards, subject.count)
    }

    func testLayer_conditionPrerequisiteAlwaysDisqualifierNever_returnsCard() {
        let expectedNumberOfCards = 1
        setupNimbusWith(
            prerequisites: ["ALWAYS"],
            disqualifiers: ["NEVER"])
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual(expectedNumberOfCards, subject.count)
    }

    func testLayer_conditionPrerequisiteNeverDisqualifierNever_returnsNoCard() {
        let expectedNumberOfCards = 0
        setupNimbusWith(
            prerequisites: ["NEVER"],
            disqualifiers: ["NEVER"])
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual(expectedNumberOfCards, subject.count)
    }

    func testLayer_conditionPrerequisiteAlwaysDisqualifierAlways_returnsNoCard() {
        let expectedNumberOfCards = 0
        setupNimbusWith(
            prerequisites: ["ALWAYS"],
            disqualifiers: ["ALWAYS"])
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual(expectedNumberOfCards, subject.count)
    }

    func testLayer_conditionPrerequisiteNeverDisqualifierAlways_returnsNoCard() {
        let expectedNumberOfCards = 0
        setupNimbusWith(
            prerequisites: ["NEVER"],
            disqualifiers: ["ALWAYS"])
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual(expectedNumberOfCards, subject.count)
    }

    // MARK: - Test image IDs
    func testLayer_cardIsReturned_WithGlobeImageIdenfier() {
        setupNimbusWith(image: .welcomeGlobe)
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.imageID, ImageIdentifiers.onboardingWelcomev106)
    }

    func testLayer_cardIsReturned_WithNotificationImageIdenfier() {
        setupNimbusWith(image: .notifications)
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.image, UIImage(named: ImageIdentifiers.onboardingNotification))
    }

    func testLayer_cardIsReturned_WithSyncImageIdenfier() {
        setupNimbusWith(image: .syncDevices)
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.image, UIImage(named: ImageIdentifiers.onboardingSyncv106))
    }

    // MARK: - Test install types
    func testLayer_cardIsReturned_WithFreshInstallType() {
        setupNimbusWith(type: .freshInstall)
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.type, OnboardingType.freshInstall)
    }

    func testLayer_cardIsReturned_WithUpdateType() {
        setupNimbusWith(type: .upgrade)
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .upgrade).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.type, OnboardingType.upgrade)
    }

    // MARK: - Test link
    func testLayer_cardIsReturned_WithNoLink() {
        setupNimbusWith(shouldAddLink: false)
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertNil(subject.link)
    }

    func testLayer_cardIsReturned_WithLink() {
        setupNimbusWith(shouldAddLink: true)
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertNotNil(subject.link)
        XCTAssertEqual(subject.link?.title, CardElementNames.linkTitle)
        XCTAssertEqual(subject.link?.url, URL(string: CardElementNames.linkURL)!)
    }

    // MARK: - Test buttons
    func testLayer_cardIsReturned_WithOneButton() {
        setupNimbusWith(withSecondaryButton: false)
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertNotNil(subject.buttons.primary)
        XCTAssertNil(subject.buttons.secondary)
    }

    func testLayer_cardIsReturned_WithTwoButtons() {
        setupNimbusWith(withSecondaryButton: true)
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertNotNil(subject.buttons.primary)
        XCTAssertNotNil(subject.buttons.secondary)
    }

    // MARK: - Test button actions
    func testLayer_cardIsReturned_WithNextCardButton() {
        setupNimbusWith(
            withSecondaryButton: false,
            withPrimaryButtonAction: .nextCard
        )
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.buttons.primary.action, .nextCard)
    }

    func testLayer_cardIsReturned_WithDefaultBrowserButton() {
        setupNimbusWith(
            withSecondaryButton: true,
            withPrimaryButtonAction: .setDefaultBrowser
        )
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.buttons.primary.action, .setDefaultBrowser)
    }

    func testLayer_cardIsReturned_WithSyncSignInButton() {
        setupNimbusWith(
            withSecondaryButton: true,
            withPrimaryButtonAction: .syncSignIn
        )
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.buttons.primary.action, .syncSignIn)
    }

    func testLayer_cardIsReturned_WithRequestNotificationsButton() {
        setupNimbusWith(
            withSecondaryButton: true,
            withPrimaryButtonAction: .requestNotifications
        )
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.buttons.primary.action, .requestNotifications)
    }

    // MARK: - Helpers
    private func setupNimbusForStringTesting() {
        let dictionary = ["\(CardElementNames.name)": NimbusOnboardingCardData(
            body: "\(CardElementNames.noPlaceholderString)",
            buttons: createButtons(
                withPrimaryAction: .nextCard,
                andSecondaryButton: false),
            disqualifiers: ["NEVER"],
            image: .notifications,
            link: nil,
            order: 10,
            prerequisites: ["ALWAYS"],
            title: "\(CardElementNames.placeholderString)",
            type: .freshInstall)]

        FxNimbus.shared.features.onboardingFrameworkFeature.with(initializer: { _ in
            OnboardingFrameworkFeature(cards: dictionary, dismissable: true)
        })
    }

    private func setupNimbusWith(
        cards numberOfCards: Int = 1,
        image: NimbusOnboardingImages = .welcomeGlobe,
        type: OnboardingType = .freshInstall,
        dismissable: Bool = true,
        shouldAddLink: Bool = false,
        withSecondaryButton: Bool = false,
        withPrimaryButtonAction: OnboardingActions = .nextCard,
        prerequisites: [String] = ["ALWAYS"],
        disqualifiers: [String] = ["NEVER"]
    ) {
        let cards = createCards(
            numbering: numberOfCards,
            image: image,
            type: type,
            shouldAddLink: shouldAddLink,
            withSecondaryButton: withSecondaryButton,
            primaryButtonAction: withPrimaryButtonAction,
            prerequisites: prerequisites,
            disqualifiers: disqualifiers)

        FxNimbus.shared.features.onboardingFrameworkFeature.with(initializer: { _ in
            OnboardingFrameworkFeature(cards: cards, dismissable: dismissable)
        })
    }

    private func createCards(
        numbering numberOfCards: Int,
        image: NimbusOnboardingImages,
        type: OnboardingType,
        shouldAddLink: Bool,
        withSecondaryButton: Bool,
        primaryButtonAction: OnboardingActions,
        prerequisites: [String],
        disqualifiers: [String]
    ) -> [String: NimbusOnboardingCardData] {
        var dictionary = [String: NimbusOnboardingCardData]()

        for number in 1...numberOfCards {
            dictionary["\(CardElementNames.name) \(number)"] = NimbusOnboardingCardData(
                body: "\(CardElementNames.body) \(number)",
                buttons: createButtons(
                    withPrimaryAction: primaryButtonAction,
                    andSecondaryButton: withSecondaryButton),
                disqualifiers: disqualifiers,
                image: image,
                link: shouldAddLink ? createLink() : nil,
                order: number,
                prerequisites: prerequisites,
                title: "\(CardElementNames.title) \(number)",
                type: type)
        }

        return dictionary
    }

    private func createButtons(
        withPrimaryAction primaryAction: OnboardingActions,
        andSecondaryButton withSecondaryButton: Bool
    ) -> NimbusOnboardingButtons {
        if withSecondaryButton {
            return NimbusOnboardingButtons(
                primary: NimbusOnboardingButton(
                    action: primaryAction,
                    title: "\(CardElementNames.primaryButtonTitle)"),
                secondary: NimbusOnboardingButton(
                    action: .nextCard,
                    title: "\(CardElementNames.secondaryButtonTitle)")
            )
        }

        return NimbusOnboardingButtons(
            primary: NimbusOnboardingButton(
                action: primaryAction,
                title: "\(CardElementNames.primaryButtonTitle)"
            )
        )
    }

    private func createLink() -> NimbusOnboardingLink {
        return NimbusOnboardingLink(
            title: "\(CardElementNames.linkTitle)",
            url: "\(CardElementNames.linkURL)")
    }
}
