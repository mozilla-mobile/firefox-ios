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
        let layer = NimbusOnboardingFeatureLayer(with: MockGleanPlumbHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.title, expectedPlaceholderString)
        XCTAssertEqual(subject.body, expectedNoPlaceholderString)
    }

    // MARK: - Test Dismissable
    func testLayer_dismissable_isTrue() {
        setupNimbusWith(cards: nil, cardOrdering: nil, dismissable: true)
        let layer = NimbusOnboardingFeatureLayer(with: MockGleanPlumbHelperUtility())
        let subject = layer.getOnboardingModel(for: .freshInstall)

        XCTAssertTrue(subject.isDismissable)
    }

    func testLayer_dismissable_isFalse() {
        setupNimbusWith(dismissable: false)
        let layer = NimbusOnboardingFeatureLayer(with: MockGleanPlumbHelperUtility())
        let subject = layer.getOnboardingModel(for: .freshInstall)

        XCTAssertFalse(subject.isDismissable)
    }

    // MARK: - Test A11yRoot
    func testLayer_a11yroot_isOnboarding() {
        setupNimbusWith(
            cards: 2,
            cardOrdering: [
                "\(CardElementNames.name) 1",
                "\(CardElementNames.name) 2"
            ])
        let layer = NimbusOnboardingFeatureLayer(with: MockGleanPlumbHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual(subject[0].a11yIdRoot, "\(CardElementNames.a11yIDOnboarding)0")
        XCTAssertEqual(subject[1].a11yIdRoot, "\(CardElementNames.a11yIDOnboarding)1")
    }

    func testLayer_a11yroot_isUpgrade() {
        setupNimbusWith(
            cards: 2,
            cardOrdering: [
                "\(CardElementNames.name) 1",
                "\(CardElementNames.name) 2"
            ],
            type: OnboardingType.upgrade.rawValue)
        let layer = NimbusOnboardingFeatureLayer(with: MockGleanPlumbHelperUtility())

        let subject = layer.getOnboardingModel(for: .upgrade).cards

        XCTAssertEqual(subject[0].a11yIdRoot, "\(CardElementNames.a11yIDUpgrade)0")
        XCTAssertEqual(subject[1].a11yIdRoot, "\(CardElementNames.a11yIDUpgrade)1")
    }

    // MARK: - Test card(s) being returned
    func testLayer_cardIsReturned_OneCard() {
        setupNimbusWith(
            cards: 1,
            cardOrdering: ["\(CardElementNames.name) 1"])
        let layer = NimbusOnboardingFeatureLayer(with: MockGleanPlumbHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        let expectedCard = OnboardingCardInfoModel(
            name: CardElementNames.name + " 1",
            title: CardElementNames.title + " 1",
            body: CardElementNames.body + " 1",
            link: OnboardingLinkInfoModel(title: CardElementNames.linkTitle + " 1",
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
        // Make sure a second button exists
        XCTAssertNotNil(subject.buttons.secondary)
        XCTAssertEqual(subject.buttons.secondary!.title, expectedCard.buttons.secondary!.title)
        XCTAssertEqual(subject.buttons.secondary!.action, expectedCard.buttons.secondary!.action)
    }

    func testLayer_cardsAreReturned_ThreeCardsReturned() {
        let expectedNumberOfCards = 3
        setupNimbusWith(
            cards: expectedNumberOfCards,
            cardOrdering: [
                "\(CardElementNames.name) 1",
                "\(CardElementNames.name) 2",
                "\(CardElementNames.name) 3",
            ])
        let layer = NimbusOnboardingFeatureLayer(with: MockGleanPlumbHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual(expectedNumberOfCards, subject.count)
    }

    func testLayer_cardsAreReturned_InExpectedOrder() {
        let expectedNumberOfCards = 3
        setupNimbusWith(
            cards: expectedNumberOfCards,
            cardOrdering: [
                "\(CardElementNames.name) 3",
                "\(CardElementNames.name) 1",
                "\(CardElementNames.name) 2",
            ])
        let layer = NimbusOnboardingFeatureLayer(with: MockGleanPlumbHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual("\(CardElementNames.name) 3", subject[0].name)
        XCTAssertEqual("\(CardElementNames.name) 1", subject[1].name)
        XCTAssertEqual("\(CardElementNames.name) 2", subject[2].name)
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
        setupNimbusWith(
            cards: expectedNumberOfCards,
            cardOrdering: ["\(CardElementNames.name) 1"],
            prerequisites: "ALWAYS")
        let layer = NimbusOnboardingFeatureLayer(with: MockGleanPlumbHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual(expectedNumberOfCards, subject.count)
    }

    func testLayer_conditionPrerequisiteNever_returnsNoCard() {
        let expectedNumberOfCards = 0
        setupNimbusWith(
            cards: 1,
            cardOrdering: ["\(CardElementNames.name) 1"],
            prerequisites: "NEVER")
        let layer = NimbusOnboardingFeatureLayer(with: MockGleanPlumbHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual(expectedNumberOfCards, subject.count)
    }

    func testLayer_conditionDisqualifierAlways_returnsNoCard() {
        let expectedNumberOfCards = 0
        setupNimbusWith(
            cards: 1,
            cardOrdering: ["\(CardElementNames.name) 1"],
            disqualifiers: "ALWAYS")
        let layer = NimbusOnboardingFeatureLayer(with: MockGleanPlumbHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual(expectedNumberOfCards, subject.count)
    }

    func testLayer_conditionDesqualifierNever_returnsCard() {
        let expectedNumberOfCards = 1
        setupNimbusWith(
            cards: expectedNumberOfCards,
            cardOrdering: ["\(CardElementNames.name) 1"],
            disqualifiers: "NEVER")
        let layer = NimbusOnboardingFeatureLayer(with: MockGleanPlumbHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual(expectedNumberOfCards, subject.count)
    }

    func testLayer_conditionPrerequisiteAlwaysDisqualifierNever_returnsCard() {
        let expectedNumberOfCards = 1
        setupNimbusWith(
            cards: expectedNumberOfCards,
            cardOrdering: ["\(CardElementNames.name) 1"],
            prerequisites: "ALWAYS",
            disqualifiers: "NEVER")
        let layer = NimbusOnboardingFeatureLayer(with: MockGleanPlumbHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual(expectedNumberOfCards, subject.count)
    }

    func testLayer_conditionPrerequisiteNeverDisqualifierNever_returnsNoCard() {
        let expectedNumberOfCards = 0
        setupNimbusWith(
            cards: expectedNumberOfCards,
            cardOrdering: ["\(CardElementNames.name) 1"],
            prerequisites: "NEVER",
            disqualifiers: "NEVER")
        let layer = NimbusOnboardingFeatureLayer(with: MockGleanPlumbHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual(expectedNumberOfCards, subject.count)
    }

    func testLayer_conditionPrerequisiteAlwaysDisqualifierAlways_returnsNoCard() {
        let expectedNumberOfCards = 0
        setupNimbusWith(
            cards: 1,
            cardOrdering: ["\(CardElementNames.name) 1"],
            prerequisites: "ALWAYS",
            disqualifiers: "ALWAYS")
        let layer = NimbusOnboardingFeatureLayer(with: MockGleanPlumbHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual(expectedNumberOfCards, subject.count)
    }

    func testLayer_conditionPrerequisiteNeverDisqualifierAlways_returnsNoCard() {
        let expectedNumberOfCards = 0
        setupNimbusWith(
            cards: 1,
            cardOrdering: ["\(CardElementNames.name) 1"],
            prerequisites: "NEVER",
            disqualifiers: "ALWAYS")
        let layer = NimbusOnboardingFeatureLayer(with: MockGleanPlumbHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual(expectedNumberOfCards, subject.count)
    }

    // MARK: - Test image IDs
    func testLayer_cardIsReturned_WithGlobeImageIdenfier() {
        setupNimbusWith(
            cards: 1,
            cardOrdering: ["\(CardElementNames.name) 1"],
            image: NimbusOnboardingImages.welcomeGlobe.rawValue
        )
        let layer = NimbusOnboardingFeatureLayer(with: MockGleanPlumbHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.imageID, ImageIdentifiers.onboardingWelcomev106)
    }

    func testLayer_cardIsReturned_WithNotificationImageIdenfier() {
        setupNimbusWith(
          cards: 1,
          cardOrdering: ["\(CardElementNames.name) 1"],
          image: NimbusOnboardingImages.notifications.rawValue
        )
        let layer = NimbusOnboardingFeatureLayer(with: MockGleanPlumbHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.image, UIImage(named: ImageIdentifiers.onboardingNotification))
    }

    func testLayer_cardIsReturned_WithSyncImageIdenfier() {
        setupNimbusWith(
          cards: 1,
          cardOrdering: ["\(CardElementNames.name) 1"],
          image: NimbusOnboardingImages.syncDevices.rawValue
        )
        let layer = NimbusOnboardingFeatureLayer(with: MockGleanPlumbHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.image, UIImage(named: ImageIdentifiers.onboardingSyncv106))
    }

    func testLayer_cardIsReturnedWithDefaultIMageID_IfBadImageID() {
        setupNimbusWith(
          cards: 1,
          cardOrdering: ["\(CardElementNames.name) 1"],
          image: "i am a bad image"
        )
        let layer = NimbusOnboardingFeatureLayer(with: MockGleanPlumbHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.image, UIImage(named: ImageIdentifiers.onboardingWelcomev106))
    }

    // MARK: - Test install types
    func testLayer_cardIsReturned_WithFreshInstallType() {
        setupNimbusWith(
          cards: 1,
          cardOrdering: ["\(CardElementNames.name) 1"],
          type: OnboardingType.freshInstall.rawValue
        )
        let layer = NimbusOnboardingFeatureLayer(with: MockGleanPlumbHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.type, OnboardingType.freshInstall)
    }

    func testLayer_cardIsReturned_WithUpdateType() {
        setupNimbusWith(
          cards: 1,
          cardOrdering: ["\(CardElementNames.name) 1"],
          type: OnboardingType.upgrade.rawValue
        )
        let layer = NimbusOnboardingFeatureLayer(with: MockGleanPlumbHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .upgrade).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.type, OnboardingType.upgrade)
    }

    // MARK: - Test link
    func testLayer_cardIsReturned_WithNoLink() {
        setupNimbusWith(
          cards: 1,
          cardOrdering: ["\(CardElementNames.name) 1"],
          shouldAddLink: false
        )
        let layer = NimbusOnboardingFeatureLayer(with: MockGleanPlumbHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertNil(subject.link)
    }

    // MARK: - Test buttons
    func testLayer_cardIsReturned_WithOneButton() {
        let expectedNumberOfButtons = 1
        setupNimbusWith(
          cards: 1,
          cardOrdering: ["\(CardElementNames.name) 1"],
          numberOfButtons: expectedNumberOfButtons
        )
        let layer = NimbusOnboardingFeatureLayer(with: MockGleanPlumbHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertNotNil(subject.buttons.primary)
        XCTAssertNil(subject.buttons.secondary)
    }

    func testLayer_cardIsReturned_WithTwoButtons() {
        let expectedNumberOfButtons = 2
        setupNimbusWith(
          cards: 1,
          cardOrdering: ["\(CardElementNames.name) 1"],
          numberOfButtons: expectedNumberOfButtons
        )
        let layer = NimbusOnboardingFeatureLayer(with: MockGleanPlumbHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertNotNil(subject.buttons.primary)
        XCTAssertNotNil(subject.buttons.secondary)
    }

    func testLayer_cardIsReturnedWithDefaultPrimaryButton_IfNoButtonsSpecified() {
        setupNimbusWith(
          cards: 1,
          cardOrdering: ["\(CardElementNames.name) 1"],
          numberOfButtons: 0
        )
        let layer = NimbusOnboardingFeatureLayer(with: MockGleanPlumbHelperUtility())

        XCTAssertNotNil(layer.getOnboardingModel(for: .freshInstall).cards.first)
    }

    // MARK: - Test button actions
    func testLayer_cardIsReturned_WithNextCardButton() {
        setupNimbusWith(
          cards: 1,
          cardOrdering: ["\(CardElementNames.name) 1"],
          numberOfButtons: 1,
          buttonActions: .nextCard
        )
        let layer = NimbusOnboardingFeatureLayer(with: MockGleanPlumbHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.buttons.primary.action, .nextCard)
    }

    func testLayer_cardIsReturned_WithDefaultBrowserButton() {
        setupNimbusWith(
          cards: 1,
          cardOrdering: ["\(CardElementNames.name) 1"],
          numberOfButtons: 1,
          buttonActions: .setDefaultBrowser
        )
        let layer = NimbusOnboardingFeatureLayer(with: MockGleanPlumbHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.buttons.primary.action, .setDefaultBrowser)
    }

    func testLayer_cardIsReturned_WithSyncSignInButton() {
        setupNimbusWith(
          cards: 1,
          cardOrdering: ["\(CardElementNames.name) 1"],
          numberOfButtons: 1,
          buttonActions: .syncSignIn
        )
        let layer = NimbusOnboardingFeatureLayer(with: MockGleanPlumbHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.buttons.primary.action, .syncSignIn)
    }

    func testLayer_cardIsReturned_WithRequestNotificationsButton() {
        setupNimbusWith(
          cards: 1,
          cardOrdering: ["\(CardElementNames.name) 1"],
          numberOfButtons: 1,
          buttonActions: .requestNotifications
        )
        let layer = NimbusOnboardingFeatureLayer(with: MockGleanPlumbHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.buttons.primary.action, .requestNotifications)
    }

    // MARK: - Helpers
    private func setupNimbusForStringTesting() {
        let features = HardcodedNimbusFeatures(with: [
            "onboarding-framework-feature": """
{
"cards": [
    {
        "name": "test",
        "title": "\(CardElementNames.placeholderString)",
        "body": "\(CardElementNames.noPlaceholderString)",
        "image": "\(NimbusOnboardingImages.welcomeGlobe.rawValue)",
        "link": {
            "title": "Hello, senator",
            "url": "https://macrumors.com"
        },
        "buttons": {
            "primary": {
                "title": "Primary Button 2",
                "action": "sync-sign-in"
            },
        },
        "type": "\(OnboardingType.freshInstall.rawValue)"
    }
],
"card-ordering": ["test"],
"dismissable": false
}
"""
        ])

        features.connect(with: FxNimbus.shared)
    }
    private func setupNimbusWith(
        cards numberOfCards: Int? = nil,
        cardOrdering: [String]? = nil,
        image: String = NimbusOnboardingImages.welcomeGlobe.rawValue,
        type: String = OnboardingType.freshInstall.rawValue,
        dismissable: Bool? = nil,
        shouldAddLink: Bool = true,
        numberOfButtons: Int = 2,
        buttonActions: OnboardingActions = .nextCard,
        prerequisites: String? = nil,
        disqualifiers: String? = nil
    ) {
        var string = ""

        if let numberOfCards = numberOfCards, let cardOrdering = cardOrdering {
            string.append(contentsOf: createCards(
                numbering: numberOfCards,
                image: image,
                type: type,
                shouldAddLink: shouldAddLink,
                numberOfButtons: numberOfButtons,
                buttonActions: buttonActions,
                prerequisites: prerequisites,
                disqualifiers: disqualifiers))
            string.append(contentsOf: "\"card-ordering\": \(cardOrdering),")
        }

        if let dismissable = dismissable {
            string.append(contentsOf: addDismissableSet(to: dismissable))
        }

        let features = HardcodedNimbusFeatures(with: [
            "onboarding-framework-feature": """
              {\(string)}
            """
        ])

        features.connect(with: FxNimbus.shared)
    }

    private func addDismissableSet(to dismissable: Bool?) -> String {
        guard let dismissable = dismissable else { return "" }

        return "\"dismissable\": \(dismissable)"
    }

    private func createCards(
        numbering numberOfCards: Int,
        image: String,
        type: String,
        shouldAddLink: Bool,
        numberOfButtons: Int,
        buttonActions: OnboardingActions,
        prerequisites: String?,
        disqualifiers: String?
    ) -> String {
        var string = "\"cards\": ["
        for x in 1...numberOfCards {
            let cardString = createCard(
                number: x,
                image: image,
                type: type,
                shouldAddLink: shouldAddLink,
                numberOfButtons: numberOfButtons,
                buttonActions: buttonActions,
                prerequisites: prerequisites,
                disqualifiers: disqualifiers)
            string.append(contentsOf: "\(cardString),")
        }
        string.append(contentsOf: "],")

        return string
    }

    private func createCard(
        number: Int,
        image: String,
        type: String,
        shouldAddLink: Bool,
        numberOfButtons: Int,
        buttonActions: OnboardingActions,
        prerequisites: String?,
        disqualifiers: String?
    ) -> String {
        var string = "{"
        string.append(contentsOf: addBasicElements(number: number,
                                                   image: image,
                                                   type: type))
        if let prerequisites = prerequisites {
            string.append(contentsOf: addPrerequisites(prerequisites))
        }
        if let disqualifiers = disqualifiers {
            string.append(contentsOf: addDisqualifiers(disqualifiers))
        }
        string.append(contentsOf: addLink(number: number,
                                          shouldAddLink: shouldAddLink))
        string.append(contentsOf: addButtons(numberOfButtons: numberOfButtons,
                                             buttonActions: buttonActions))
        string.append(contentsOf: "}")

        return string
    }

    private func addBasicElements(
        number: Int,
        image: String,
        type: String
    ) -> String {
        return """
  "name": "\(CardElementNames.name) \(number)",
  "title": "\(CardElementNames.title) \(number)",
  "body": "\(CardElementNames.body) \(number)",
  "image": "\(image)",
  "type": "\(type)",
"""
    }
    private func addPrerequisites(_ string: String) -> String {
        return """
  "prerequisites": ["\(string)"],
"""
    }

    private func addDisqualifiers(_ string: String) -> String {
        return """
  "disqualifiers": ["\(string)"],
"""
    }

    private func addLink(
        number: Int,
        shouldAddLink: Bool
    ) -> String {
        if !shouldAddLink { return "" }

        return """
  "link": {
    "title": "\(CardElementNames.linkTitle) \(number)",
    "url": "\(CardElementNames.linkURL)"
  },
"""
    }

    private func addButtons(
        numberOfButtons: Int,
        buttonActions: OnboardingActions
    ) -> String {
        var string = "\"buttons\": {"

        if numberOfButtons > 0 {
            string.append(contentsOf: """
    "primary": {
      "title": "\(CardElementNames.primaryButtonTitle)",
      "action": "\(buttonActions.rawValue)",
    },
""")
        }

        if numberOfButtons > 1 {
            string.append(contentsOf: """
    "secondary": {
      "title": "\(CardElementNames.secondaryButtonTitle)",
      "action": "\(buttonActions.rawValue)",
    },
""")
        }

        string.append(contentsOf: "},")
        return string
    }
}
