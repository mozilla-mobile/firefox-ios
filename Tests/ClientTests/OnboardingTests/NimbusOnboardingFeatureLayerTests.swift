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
        static let linkTitle = "MacRumors"
        static let linkURL = "https://macrumors.com"
        static let primaryButtonTitle = "Primary Button"
        static let secondaryButtonTitle = "Secondary Button"
    }

    override func setUp() {
        super.setUp()
        let features = HardcodedNimbusFeatures(with: ["onboarding-framework-feature": ""])
        features.connect(with: FxNimbus.shared)
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Test Dismissable
    func testLayer_dismissable_isTrue() {
        setupNimbusWith(cards: nil, cardOrdering: nil, dismissable: true)
        let layer = NimbusOnboardingFeatureLayer()
        let subject = layer.getOnboardingModel()

        XCTAssertTrue(subject.isDismissable)
    }

    func testLayer_dismissable_isFalse() {
        setupNimbusWith(dismissable: false)
        let layer = NimbusOnboardingFeatureLayer()
        let subject = layer.getOnboardingModel()

        XCTAssertFalse(subject.isDismissable)
    }

    // MARK: - Test card(s) being returned
    func testLayer_cardIsReturned_OneCard() {
        setupNimbusWith(
            cards: 1,
            cardOrdering: ["\(CardElementNames.name) 1"])
        let layer = NimbusOnboardingFeatureLayer()

        guard let subject = layer.getOnboardingModel().cards?.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        let expectedCard = OnboardingCardInfoModel(
            name: CardElementNames.name + " 1",
            title: CardElementNames.title + " 1",
            body: CardElementNames.body + " 1",
            image: ImageIdentifiers.onboardingWelcomev106,
            link: OnboardingLinkInfoModel(title: CardElementNames.linkTitle + " 1",
                                          url: URL(string: CardElementNames.linkURL)!),
            buttons: [
                OnboardingButtonInfoModel(title: CardElementNames.primaryButtonTitle + " 1",
                                          action: .nextCard),
                OnboardingButtonInfoModel(title: CardElementNames.secondaryButtonTitle + " 1",
                                          action: .nextCard)
            ],
            type: .freshInstall)

        XCTAssertEqual(subject.name, expectedCard.name)
        XCTAssertEqual(subject.title, expectedCard.title)
        XCTAssertEqual(subject.body, expectedCard.body)
        XCTAssertEqual(subject.image, expectedCard.image)
        XCTAssertEqual(subject.type, expectedCard.type)
        XCTAssertEqual(subject.link?.title, expectedCard.link?.title)
        XCTAssertEqual(subject.link?.url, expectedCard.link?.url)
        XCTAssertEqual(subject.buttons[0].title, expectedCard.buttons[0].title)
        XCTAssertEqual(subject.buttons[0].action, expectedCard.buttons[0].action)
        XCTAssertEqual(subject.buttons[1].title, expectedCard.buttons[1].title)
        XCTAssertEqual(subject.buttons[1].action, expectedCard.buttons[1].action)
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
        let layer = NimbusOnboardingFeatureLayer()

        guard let subject = layer.getOnboardingModel().cards else {
            XCTFail("Expected cards, and got none.")
            return
        }

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
        let layer = NimbusOnboardingFeatureLayer()

        guard let subject = layer.getOnboardingModel().cards else {
            XCTFail("Expected cards, and got none.")
            return
        }

        XCTAssertEqual("\(CardElementNames.name) 3", subject[0].name)
        XCTAssertEqual("\(CardElementNames.name) 1", subject[1].name)
        XCTAssertEqual("\(CardElementNames.name) 2", subject[2].name)
    }

    func testLayer_cardsAreReturned_InExpectedOrder_WithoutMisspelledCards() {
        let expectedNumberOfCards = 3
        setupNimbusWith(
            cards: expectedNumberOfCards + 1,
            cardOrdering: [
                "\(CardElementNames.name) 1",
                "\(CardElementNames.name) mispelling",
                "\(CardElementNames.name) 3",
                "\(CardElementNames.name) 4",
            ])
        let layer = NimbusOnboardingFeatureLayer()

        guard let subject = layer.getOnboardingModel().cards else {
            XCTFail("Expected cards, and got none.")
            return
        }

        XCTAssertEqual(expectedNumberOfCards, subject.count)
        XCTAssertEqual("\(CardElementNames.name) 1", subject[0].name)
        XCTAssertEqual("\(CardElementNames.name) 3", subject[1].name)
        XCTAssertEqual("\(CardElementNames.name) 4", subject[2].name)
    }

    // MARK: - Test image IDs
    func testLayer_cardIsReturned_WithGlobeImageIdenfier() {
        setupNimbusWith(
            cards: 1,
            cardOrdering: ["\(CardElementNames.name) 1"],
            image: NimbusOnboardingImages.welcomeGlobe.rawValue
        )
        let layer = NimbusOnboardingFeatureLayer()

        guard let subject = layer.getOnboardingModel().cards?.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.image, ImageIdentifiers.onboardingWelcomev106)
    }

    func testLayer_cardIsReturned_WithNotificationImageIdenfier() {
        setupNimbusWith(
          cards: 1,
          cardOrdering: ["\(CardElementNames.name) 1"],
          image: NimbusOnboardingImages.notifications.rawValue
        )
        let layer = NimbusOnboardingFeatureLayer()

        guard let subject = layer.getOnboardingModel().cards?.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.image, ImageIdentifiers.onboardingNotification)
    }

    func testLayer_cardIsReturned_WithSyncImageIdenfier() {
        setupNimbusWith(
          cards: 1,
          cardOrdering: ["\(CardElementNames.name) 1"],
          image: NimbusOnboardingImages.syncDevices.rawValue
        )
        let layer = NimbusOnboardingFeatureLayer()

        guard let subject = layer.getOnboardingModel().cards?.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.image, ImageIdentifiers.onboardingSyncv106)
    }

    func testLayer_cardIsReturnedWithDefaultIMageID_IfBadImageID() {
        setupNimbusWith(
          cards: 1,
          cardOrdering: ["\(CardElementNames.name) 1"],
          image: "i am a bad image"
        )
        let layer = NimbusOnboardingFeatureLayer()

        guard let subject = layer.getOnboardingModel().cards?.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.image, ImageIdentifiers.onboardingWelcomev106)
    }

    // MARK: - Test install types
    func testLayer_cardIsReturned_WithFreshInstallType() {
        setupNimbusWith(
          cards: 1,
          cardOrdering: ["\(CardElementNames.name) 1"],
          type: OnboardingType.freshInstall.rawValue
        )
        let layer = NimbusOnboardingFeatureLayer()

        guard let subject = layer.getOnboardingModel().cards?.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.type, OnboardingType.freshInstall)
    }

    func testLayer_cardIsReturned_WithUpdateType() {
        setupNimbusWith(
          cards: 1,
          cardOrdering: ["\(CardElementNames.name) 1"],
          type: OnboardingType.update.rawValue
        )
        let layer = NimbusOnboardingFeatureLayer()

        guard let subject = layer.getOnboardingModel().cards?.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.type, OnboardingType.update)
    }

    // MARK: - Test link
    func testLayer_cardIsReturned_WithNoLink() {
        setupNimbusWith(
          cards: 1,
          cardOrdering: ["\(CardElementNames.name) 1"],
          shouldAddLink: false
        )
        let layer = NimbusOnboardingFeatureLayer()

        guard let subject = layer.getOnboardingModel().cards?.first else {
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
        let layer = NimbusOnboardingFeatureLayer()

        guard let subject = layer.getOnboardingModel().cards?.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.buttons.count, expectedNumberOfButtons)
    }

    func testLayer_cardIsNotReturned_IfNoButtons() {
        let expectedNumberOfButtons = 0
        setupNimbusWith(
          cards: 1,
          cardOrdering: ["\(CardElementNames.name) 1"],
          numberOfButtons: expectedNumberOfButtons
        )
        let layer = NimbusOnboardingFeatureLayer()

        XCTAssertNil(layer.getOnboardingModel().cards?.first)
    }

    // MARK: - Test button actions
    func testLayer_cardIsReturned_WithNextCardButton() {
        setupNimbusWith(
          cards: 1,
          cardOrdering: ["\(CardElementNames.name) 1"],
          numberOfButtons: 1,
          buttonActions: .nextCard
        )
        let layer = NimbusOnboardingFeatureLayer()

        guard let subject = layer.getOnboardingModel().cards?.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.buttons[0].action, .nextCard)
    }

    func testLayer_cardIsReturned_WithDefaultBrowserButton() {
        setupNimbusWith(
          cards: 1,
          cardOrdering: ["\(CardElementNames.name) 1"],
          numberOfButtons: 1,
          buttonActions: .setDefaultBrowser
        )
        let layer = NimbusOnboardingFeatureLayer()

        guard let subject = layer.getOnboardingModel().cards?.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.buttons[0].action, .setDefaultBrowser)
    }

    func testLayer_cardIsReturned_WithSyncSignInButton() {
        setupNimbusWith(
          cards: 1,
          cardOrdering: ["\(CardElementNames.name) 1"],
          numberOfButtons: 1,
          buttonActions: .syncSignIn
        )
        let layer = NimbusOnboardingFeatureLayer()

        guard let subject = layer.getOnboardingModel().cards?.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.buttons[0].action, .syncSignIn)
    }

    func testLayer_cardIsReturned_WithRequestNotificationsButton() {
        setupNimbusWith(
          cards: 1,
          cardOrdering: ["\(CardElementNames.name) 1"],
          numberOfButtons: 1,
          buttonActions: .requestNotifications
        )
        let layer = NimbusOnboardingFeatureLayer()

        guard let subject = layer.getOnboardingModel().cards?.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.buttons[0].action, .requestNotifications)
    }

    // MARK: - Helpers
    private func setupNimbusWith(
        cards numberOfCards: Int? = nil,
        cardOrdering: [String]? = nil,
        image: String = NimbusOnboardingImages.welcomeGlobe.rawValue,
        type: String = OnboardingType.freshInstall.rawValue,
        dismissable: Bool? = nil,
        shouldAddLink: Bool = true,
        numberOfButtons: Int = 2,
        buttonActions: OnboardingActions = .nextCard
    ) {
        var string = ""

        if let numberOfCards = numberOfCards, let cardOrdering = cardOrdering {
            string.append(contentsOf: createCards(
                numbering: numberOfCards,
                image: image,
                type: type,
                shouldAddLink: shouldAddLink,
                numberOfButtons: numberOfButtons,
                buttonActions: buttonActions))
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
        buttonActions: OnboardingActions
    ) -> String {
        var string = "\"cards\": ["
        for x in 1...numberOfCards {
            let cardString = createCard(
                number: x,
                image: image,
                type: type,
                shouldAddLink: shouldAddLink,
                numberOfButtons: numberOfButtons,
                buttonActions: buttonActions)
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
        buttonActions: OnboardingActions
    ) -> String {
        var string = "{"
        string.append(contentsOf: addBasicElements(number: number,
                                                   image: image,
                                                   type: type))
        string.append(contentsOf: addLink(number: number,
                                          shouldAddLink: shouldAddLink))
        string.append(contentsOf: addButtons(number: number,
                                             numberOfButtons: numberOfButtons,
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
        number: Int,
        numberOfButtons: Int,
        buttonActions: OnboardingActions
    ) -> String {
        let buttonInfo = [CardElementNames.primaryButtonTitle, CardElementNames.secondaryButtonTitle]
        var string = "\"buttons\": ["

        for x in 0..<numberOfButtons {
            string.append(contentsOf: """
    {
      "title": "\(buttonInfo[x]) \(number)",
      "action": "\(buttonActions.rawValue)",
    },
""")
        }

        string.append(contentsOf: "],")
        return string
    }
}
