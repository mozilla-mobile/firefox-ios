// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MozillaAppServices
import Shared

struct NimbusOnboardingTestingConfigUtility {
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

    func setupNimbus(withOrder order: [CardOrder]) {
        var dictionary = [String: NimbusOnboardingCardData]()

        for (index, item) in order.enumerated() {
            dictionary[item.rawValue] = createCard(withID: item, andOrder: index)
        }

        FxNimbus.shared.features.onboardingFrameworkFeature.with(initializer: { _ in
            OnboardingFrameworkFeature(cards: dictionary, dismissable: true)
        })
    }

    private func createCard(
        withID id: CardOrder,
        andOrder order: Int
    ) -> NimbusOnboardingCardData {
        let shouldAddLink: [CardOrder] = [.welcome, .updateWelcome]
        let isUpdate: [CardOrder] = [.updateWelcome, .updateSync]
        let image: NimbusOnboardingImages = {
            switch id {
            case .notifications: return .notifications
            case .welcome, .updateWelcome: return .welcomeGlobe
            case .sync, .updateSync: return .syncDevices
            }
        }()

        return NimbusOnboardingCardData(
            body: "body text",
            buttons: createButtons(for: id),
            disqualifiers: ["NEVER"],
            image: image,
            link: shouldAddLink.contains(where: { $0 == id }) ? buildLink() : nil,
            order: order,
            prerequisites: ["ALWAYS"],
            title: "title text",
            type: isUpdate.contains(where: { $0 == id }) ? .upgrade : .freshInstall)
    }

    private func buildLink() -> NimbusOnboardingLink {
        return NimbusOnboardingLink(
            title: "Link title",
            url: "https://www.mozilla.org/en-US/privacy/firefox/")
    }

    private func createButtons(for id: CardOrder) -> NimbusOnboardingButtons {
        switch id {
        case .welcome, .updateWelcome:
            return NimbusOnboardingButtons(
                primary: NimbusOnboardingButton(
                    action: .nextCard,
                    title: "Primary title"
                )
            )
        case .notifications:
            return NimbusOnboardingButtons(
                primary: NimbusOnboardingButton(
                    action: .requestNotifications,
                    title: "Primary title"),
                secondary: NimbusOnboardingButton(
                    action: .nextCard,
                    title: "Secondary title")
            )
        case .sync, .updateSync:
            return NimbusOnboardingButtons(
                primary: NimbusOnboardingButton(
                    action: .syncSignIn,
                    title: "Primary title"),
                secondary: NimbusOnboardingButton(
                    action: .nextCard,
                    title: "Secondary title")
            )
        }
    }
}
