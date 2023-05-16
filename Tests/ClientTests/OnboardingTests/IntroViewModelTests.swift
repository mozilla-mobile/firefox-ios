// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MozillaAppServices
import Shared
import XCTest

@testable import Client

class IntroViewModelTests: XCTestCase {
    private struct CardOrder {
        static let welcome = "welcome"
        static let notifications = "notificationPermissions"
        static let sync = "signToSync"
        static let updateWelcome = "update.welcome"
        static let updateSync = "update.signToSync"

        // card order to be passed to Nimbus for a variety of tests
        static let welcomeNotificationsSync = "[\"\(welcome)\", \"\(notifications)\", \"\(sync)\"]"
        static let welcomeSync = "[\"\(welcome)\", \"\(sync)\"]"
    }

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        let features = HardcodedNimbusFeatures(with: ["onboarding-framework-feature": ""])
        features.connect(with: FxNimbus.shared)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testModel_hasThreeAvailableCards_inExpectedOrder() {
        setupNimbus(withOrder: CardOrder.welcomeNotificationsSync)
        let subject = createSubject()
        let expectedNumberOfViewControllers = 3

        subject.setupViewControllerDelegates(with: MockOnboardinCardDelegateController())

        XCTAssertEqual(subject.availableCards.count, expectedNumberOfViewControllers)
        XCTAssertEqual(subject.availableCards[0].viewModel.infoModel.name, CardOrder.welcome)
        XCTAssertEqual(subject.availableCards[1].viewModel.infoModel.name, CardOrder.notifications)
        XCTAssertEqual(subject.availableCards[2].viewModel.infoModel.name, CardOrder.sync)
    }

    func testModel_hasTwoAvailableCards_inExpectedOrder() {
        setupNimbus(withOrder: CardOrder.welcomeSync)
        let subject = createSubject()
        let expectedNumberOfViewControllers = 2

        subject.setupViewControllerDelegates(with: MockOnboardinCardDelegateController())

        XCTAssertEqual(subject.availableCards.count, expectedNumberOfViewControllers)
        XCTAssertEqual(subject.availableCards[0].viewModel.infoModel.name, CardOrder.welcome)
        XCTAssertEqual(subject.availableCards[1].viewModel.infoModel.name, CardOrder.sync)
    }

    func testNextIndexAfterLastCard() {
        let index = viewModel.getNextIndex(currentIndex: 2, goForward: true)
        XCTAssertNil(index)
    }

    func testNextIndexBeforeFirstCard() {
        let index = viewModel.getNextIndex(currentIndex: 0, goForward: false)
        XCTAssertNil(index)
    }

    // MARK: - Private Helpers
    func createSubject() -> IntroViewModel {
        let subject = IntroViewModel(profile: MockProfile(databasePrefix: "introViewModelTests_"))

        trackForMemoryLeaks(subject)

        return subject
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
                  "link": {
                    "title": "link title",
                    "url": "https://www.mozilla.org/en-US/privacy/firefox/"
                  },
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
                  "type": "upgrade"
                },
                {
                  "name": "notificationPermissions",
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
                  "link": {
                    "title": "link title",
                    "url": "https://www.mozilla.org/en-US/privacy/firefox/"
                  },
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
                  "link": {
                    "title": "link title",
                    "url": "https://www.mozilla.org/en-US/privacy/firefox/"
                  },
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
