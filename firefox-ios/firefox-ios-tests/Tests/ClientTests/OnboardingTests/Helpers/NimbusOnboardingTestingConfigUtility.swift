// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices

struct NimbusOnboardingTestingConfigUtility {
    struct CardElementNames {
        static let name = "Name"
        static let title = "Title"
        static let body = "Body"
        static let popupTitle = "Popup"
        static let popupButtonTitle = "Popup Button"
        static let popupFirstInstruction = "first instruction"
        static let popupSecondInstruction = "second instruction"
        static let popupThirdInstruction = "third instruction"
        static let a11yIDOnboarding = "onboarding."
        static let a11yIDUpgrade = "upgrade."
        static let linkTitle = "MacRumors"
        static let linkURL = "https://www.mozilla.org/en-US/privacy/firefox/"
        static let primaryButtonTitle = "Primary Button"
        static let secondaryButtonTitle = "Secondary Button"
        static let placeholderString = "A string inside %@ with a placeholder"
        static let noPlaceholderString = "On Wednesday's, we wear pink"
    }

    enum CardOrder: String {
        case welcome
        case notifications = "notificationPermissions"
        case sync = "signToSync"
        case updateWelcome = "update.welcome"
        case updateSync = "update.signToSync"

        static let allCards: [CardOrder] = [.welcome, .notifications, .sync, .updateWelcome, .updateSync]
        static let welcomeNotificationSync: [CardOrder] = [.welcome, .notifications, .sync]
        static let welcomeSync: [CardOrder] = [.welcome, .sync]
    }

    // MARK: - Order-based setups
    func setupNimbus(withOrder order: [CardOrder]) {
        var dictionary = [String: NimbusOnboardingCardData]()

        for (index, item) in order.enumerated() {
            dictionary[item.rawValue] = createCard(withID: item, andOrder: index)
        }

        FxNimbus.shared.features.onboardingFrameworkFeature.with(initializer: { _, _ in
            OnboardingFrameworkFeature(
                cards: dictionary,
                dismissable: true)
        })
    }

    // MARK: - Custom setups
    func setupNimbusWith(
        image: NimbusOnboardingHeaderImage = .welcomeGlobe,
        cardType: OnboardingCardType = .basic,
        onboardingType: OnboardingType = .freshInstall,
        dismissable: Bool = true,
        shouldAddLink: Bool = false,
        withSecondaryButton: Bool = false,
        withPrimaryButtonAction primaryAction: [OnboardingActions] = [.forwardOneCard],
        prerequisites: [String] = ["ALWAYS"],
        disqualifiers: [String] = []
    ) {
        let cards = createCards(
            numbering: primaryAction.count,
            image: image,
            cardType: cardType,
            onboardingType: onboardingType,
            shouldAddLink: shouldAddLink,
            withSecondaryButton: withSecondaryButton,
            primaryButtonAction: primaryAction,
            prerequisites: prerequisites,
            disqualifiers: disqualifiers)

        FxNimbus.shared.features.onboardingFrameworkFeature.with(initializer: { _, _ in
            OnboardingFrameworkFeature(
                cards: cards,
                dismissable: dismissable)
        })
    }

    // MARK: - Private helpers
    private func createCards(
        numbering numberOfCards: Int,
        image: NimbusOnboardingHeaderImage,
        cardType: OnboardingCardType,
        onboardingType: OnboardingType,
        shouldAddLink: Bool,
        withSecondaryButton: Bool,
        primaryButtonAction: [OnboardingActions],
        prerequisites: [String],
        disqualifiers: [String]
    ) -> [String: NimbusOnboardingCardData] {
        var dictionary = [String: NimbusOnboardingCardData]()

        for number in 1...numberOfCards {
            dictionary["\(CardElementNames.name) \(number)"] = NimbusOnboardingCardData(
                body: "\(CardElementNames.body) \(number)",
                buttons: createButtons(
                    withPrimaryAction: primaryButtonAction[number - 1],
                    andSecondaryButton: withSecondaryButton),
                cardType: cardType,
                disqualifiers: disqualifiers,
                image: image,
                instructionsPopup: buildInfoPopup(),
                link: shouldAddLink ? buildLink() : nil,
                onboardingType: onboardingType,
                order: number,
                prerequisites: prerequisites,
                title: "\(CardElementNames.title) \(number)")
        }

        return dictionary
    }

    private func createCard(
        withID id: CardOrder,
        andOrder order: Int
    ) -> NimbusOnboardingCardData {
        let shouldAddLink: [CardOrder] = [.welcome, .updateWelcome]
        let isUpdate: [CardOrder] = [.updateWelcome, .updateSync]
        let image: NimbusOnboardingHeaderImage = {
            switch id {
            case .notifications: return .notifications
            case .welcome, .updateWelcome: return .welcomeGlobe
            case .sync, .updateSync: return .syncDevices
            }
        }()

        return NimbusOnboardingCardData(
            body: "body text",
            buttons: createButtons(for: id),
            cardType: .basic,
            disqualifiers: ["NEVER"],
            image: image,
            instructionsPopup: buildInfoPopup(),
            link: shouldAddLink.contains(where: { $0 == id }) ? buildLink() : nil,
            onboardingType: isUpdate.contains(where: { $0 == id }) ? .upgrade : .freshInstall,
            order: order,
            prerequisites: ["ALWAYS"],
            title: "title text")
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
                    action: .forwardOneCard,
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

    private func createButtons(for id: CardOrder) -> NimbusOnboardingButtons {
        switch id {
        case .welcome, .updateWelcome:
            return NimbusOnboardingButtons(
                primary: NimbusOnboardingButton(
                    action: .forwardOneCard,
                    title: "\(CardElementNames.primaryButtonTitle)"))
        case .notifications:
            return NimbusOnboardingButtons(
                primary: NimbusOnboardingButton(
                    action: .requestNotifications,
                    title: "\(CardElementNames.primaryButtonTitle)"),
                secondary: NimbusOnboardingButton(
                    action: .forwardOneCard,
                    title: "\(CardElementNames.secondaryButtonTitle)"))
        case .sync, .updateSync:
            return NimbusOnboardingButtons(
                primary: NimbusOnboardingButton(
                    action: .syncSignIn,
                    title: "\(CardElementNames.primaryButtonTitle)"),
                secondary: NimbusOnboardingButton(
                    action: .forwardOneCard,
                    title: "\(CardElementNames.secondaryButtonTitle)"))
        }
    }

    private func buildLink() -> NimbusOnboardingLink {
        return NimbusOnboardingLink(
            title: "\(CardElementNames.linkTitle)",
            url: "\(CardElementNames.linkURL)")
    }

    private func buildInfoPopup() -> NimbusOnboardingInstructionPopup {
        return NimbusOnboardingInstructionPopup(
            buttonAction: .dismiss,
            buttonTitle: CardElementNames.popupButtonTitle,
            instructions: [
                CardElementNames.popupFirstInstruction,
                CardElementNames.popupSecondInstruction,
                CardElementNames.popupThirdInstruction,
            ],
            title: CardElementNames.popupTitle)
    }
}
