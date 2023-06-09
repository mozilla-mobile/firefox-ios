// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MozillaAppServices
import Shared

struct NimbusOnboardingConfigUtility {
    enum CardOrder: String {
        case welcome
        case notifications = "notificationPermissions"
        case sync = "signToSync"
        case updateWelcome = "update.welcome"
        case updateSync = "update.Sync"

        static let allCards: [CardOrder] = [.welcome, .notifications, .sync, .updateWelcome, .updateSync]
        static let welcomeNotificationSync: [CardOrder] = [.welcome, .notifications, .sync]
        static let welcomeSync: [CardOrder] = [.welcome, .sync]
    }

    func clearNimbus() {
        let features = HardcodedNimbusFeatures(with: ["onboarding-framework-feature": ""])
        features.connect(with: FxNimbus.shared)
    }

    func setupNimbus(withOrder order: [CardOrder]) {
        // make sure Nimbus is empty for a clean slate
        let features = HardcodedNimbusFeatures(with: [
            "onboarding-framework-feature": setupOnboarding(withOrder: order)
        ])

        features.connect(with: FxNimbus.shared)
    }

    private func setupOnboarding(withOrder order: [CardOrder]) -> String {
        var string = """
            {
              "cards": [
"""
        for (index, item) in order.enumerated() {
            switch item {
            case .welcome: string.append(addWelcome(order: index))
            case .notifications: string.append(addNotifications(order: index))
            case .sync: string.append(addSync(order: index))
            case .updateWelcome: string.append(addUpdateWelcome(order: index))
            case .updateSync: string.append(addUpdateSync(order: index))
            }
        }

        string.append("""
              ],
              "dismissable": true
            }
""")

        return string
    }

    private func addWelcome(order: Int) -> String {
        return """
{
  "name": "welcome",
  "order": \(order),
  "title": "title",
  "body": "body text",
  "image": "welcome-globe",
  "link": {
    "title": "link title",
    "url": "https://www.mozilla.org/en-US/privacy/firefox/"
  },
  "buttons": {
    "primary": {
      "title": "primary title",
      "action": "next-card"
    }
  },
  "type": "fresh-install"
},
"""
    }

    private func addNotifications(order: Int) -> String {
        return """
{
    "name": "notificationPermissions",
    "order": \(order),
    "title": "title",
    "body": "body text",
    "image": "welcome-globe",
    "buttons": {
        "primary": {
            "title": "primary title",
            "action": "request-notifications"
        },
        "secondary": {
            "title": "secondary title",
            "action": "next-card"
        }
    },
    "type": "fresh-install"
},
"""
    }

    private func addSync(order: Int) -> String {
        return """
{
    "name": "signToSync",
    "order": \(order),
    "title": "title",
    "body": "body text",
    "image": "welcome-globe",
    "buttons": {
        "primary": {
            "title": "primary title",
            "action": "sync-sign-in"
        },
        "secondary": {
            "title": "secondary title",
            "action": "next-card"
        }
    },
    "type": "fresh-install"
},
"""
    }

    private func addUpdateWelcome(order: Int) -> String {
        return """
{
    "name": "update.welcome",
    "order": \(order),
    "title": "title",
    "body": "body text",
    "image": "welcome-globe",
    "buttons": {
        "primary": {
            "title": "primary title",
            "action": "next-card"
        },
    },
    "type": "upgrade"
},
"""
    }

    private func addUpdateSync(order: Int) -> String {
        return """
{
    "name": "update.signToSync",
    "order": \(order),
    "title": "title",
    "body": "body text",
    "image": "welcome-globe",
    "buttons": {
        "primary": {
            "title": "primary title",
            "action": "sync-sign-in"
        },
        "secondary": {
            "title": "secondary title",
            "action": "next-card"
        }
    },
    "type": "upgrade"
}
"""
    }
}
