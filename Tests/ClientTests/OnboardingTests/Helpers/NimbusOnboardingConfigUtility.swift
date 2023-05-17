// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MozillaAppServices
import Shared

struct NimbusOnboardingConfigUtility {
    struct CardOrder {
        static let welcome = "welcome"
        static let notifications = "notificationPermissions"
        static let sync = "signToSync"
        static let updateWelcome = "update.welcome"
        static let updateSync = "update.signToSync"

        // card order to be passed to Nimbus for a variety of tests
        static let allCards = "[\"\(welcome)\", \"\(updateWelcome)\", \"\(notifications)\", \"\(sync)\", \"\(updateSync)\"]"
        static let welcomeNotificationsSync = "[\"\(welcome)\", \"\(notifications)\", \"\(sync)\"]"
        static let welcomeSync = "[\"\(welcome)\", \"\(sync)\"]"
    }

    func clearNimbus() {
        let features = HardcodedNimbusFeatures(with: ["onboarding-framework-feature": ""])
        features.connect(with: FxNimbus.shared)
    }

    func setupNimbus(withOrder order: String) {
        // make sure Nimbus is empty for a clean slate
        let features = HardcodedNimbusFeatures(with: [
            "onboarding-framework-feature": """
            {
              "cards": [
                {
                  "name": "welcome",
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
                {
                  "name": "update.welcome",
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
                {
                  "name": "notificationPermissions",
                  "title": "title",
                  "body": "body text",
                  "image": "welcome-globe",
                  "buttons": {
                    "primary": {
                      "title": "primary title",
                      "action": "next-card"
                    },
                    "secondary": {
                      "title": "secondary title",
                      "action": "next-card"
                    }
                  },
                  "type": "fresh-install"
                },
                {
                  "name": "signToSync",
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
                {
                  "name": "update.signToSync",
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
              ],
              "card-ordering": \(order),
              "dismissable": true
            }
"""
        ])

        features.connect(with: FxNimbus.shared)
    }
}
