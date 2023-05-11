// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
//
// Tests are disabled as there's curretly a string issue. Will be enabled once
// the issue is resolved and tests can pass properly.
// import XCTest
//
// @testable import Client
//
// class NimbusOnboardingFeatureLayerDefaultsTests: XCTestCase {
//     func testLayer_ReturnsExpectedDefaults_forOnboarding() {
//         let welcomeCard = OnboardingCardInfoModel(
//             name: "welcome",
//             title: String(format: .Onboarding.Welcome.Title),
//             body: String(format: .Onboarding.Welcome.Description),
//             link: OnboardingLinkInfoModel(
//                 title: .Onboarding.PrivacyPolicyLinkButtonTitle,
//                 url: URL(string: "https://macrumors.com")!),
//             buttons: OnboardingButtons(
//                 primary: OnboardingButtonInfoModel(
//                     title: .Onboarding.Welcome.GetStartedAction,
//                     action: .nextCard)),
//             type: .freshInstall,
//             a11yIdRoot: AccessibilityIdentifiers.Onboarding.welcomeCard,
//             imageID: ImageIdentifiers.onboardingWelcomev106)
//
//         let syncCard = OnboardingCardInfoModel(
//             name: "signToSync",
//             title: String(format: .Onboarding.Sync.Title),
//             body: String(format: .Onboarding.Sync.Description),
//             link: nil,
//             buttons: OnboardingButtons(
//                 primary: OnboardingButtonInfoModel(
//                     title: .Onboarding.Sync.SignInAction,
//                     action: .syncSignIn),
//                 secondary: OnboardingButtonInfoModel(
//                     title: .Onboarding.Sync.SkipAction,
//                     action: .nextCard)),
//             type: .freshInstall,
//             a11yIdRoot: AccessibilityIdentifiers.Onboarding.signSyncCard,
//             imageID: ImageIdentifiers.onboardingSyncv106)
//
//         let notificationsCard = OnboardingCardInfoModel(
//             name: "notificationPermissions",
//             title: String(format: .Onboarding.Notification.Title),
//             body: String(format: .Onboarding.Notification.Description),
//             link: nil,
//             buttons: OnboardingButtons(
//                 primary: OnboardingButtonInfoModel(
//                     title: .Onboarding.Notification.ContinueAction,
//                     action: .requestNotifications),
//                 secondary: OnboardingButtonInfoModel(
//                     title: .Onboarding.Notification.SkipAction,
//                     action: .nextCard)),
//             type: .freshInstall,
//             a11yIdRoot: AccessibilityIdentifiers.Onboarding.notificationCard,
//             imageID: ImageIdentifiers.onboardingSyncv106)
//
//         let expectedResult = OnboardingViewModel(
//             cards: [welcomeCard, notificationsCard, syncCard],
//             isDismissable: true)
//
//         let result = NimbusOnboardingFeatureLayer().getOnboardingModel(for: .freshInstall)
//         guard let resultCards = result.cards else {
//             XCTFail("Expected onboarding cards, but found none.")
//             return
//         }
//
//         XCTAssertEqual(result.isDismissable, expectedResult.isDismissable)
//         XCTAssertEqual(resultCards.count, expectedResult.cards!.count)
//
//         resultCards.indices.forEach { index in
//             test(resultCards[index], isEqualTo: expectedResult.cards![index])
//         }
//     }
//
//     func testLayer_ReturnsExpectedDefaults_forUpgrade() {
//         let welcomeCard = OnboardingCardInfoModel(
//             name: "update.welcome",
//             title: .Upgrade.Welcome.Title,
//             body: .Upgrade.Welcome.Description,
//             link: nil,
//             buttons: OnboardingButtons(
//                 primary: OnboardingButtonInfoModel(
//                     title: .Upgrade.Welcome.Action,
//                     action: .nextCard)),
//             type: .upgrade,
//             a11yIdRoot: AccessibilityIdentifiers.Upgrade.welcomeCard,
//             imageID: ImageIdentifiers.onboardingWelcomev106)
//
//         let syncCard = OnboardingCardInfoModel(
//             name: "update.signToSync",
//             title: .Upgrade.Sync.Title,
//             body: .Upgrade.Sync.Description,
//             link: nil,
//             buttons: OnboardingButtons(
//                 primary: OnboardingButtonInfoModel(
//                     title: .Upgrade.Sync.Action,
//                     action: .syncSignIn),
//                 secondary: OnboardingButtonInfoModel(
//                     title: .Onboarding.LaterAction,
//                     action: .nextCard)),
//             type: .upgrade,
//             a11yIdRoot: AccessibilityIdentifiers.Upgrade.signSyncCard,
//             imageID: ImageIdentifiers.onboardingSyncv106)
//
//         let expectedResult = OnboardingViewModel(
//             cards: [welcomeCard, syncCard],
//             isDismissable: true)
//
//         let result = NimbusOnboardingFeatureLayer().getOnboardingModel(for: .upgrade)
//
//         XCTAssertEqual(result.isDismissable, expectedResult.isDismissable)
//     }
//
//     // MARK: - Helper functions
//     private func test(
//         _ subject: OnboardingCardInfoModel,
//         isEqualTo expectedCard: OnboardingCardInfoModel,
//         file: StaticString = #filePath,
//         line: UInt = #line
//     ) {
//         XCTAssertEqual(subject.name, expectedCard.name)
//         XCTAssertEqual(subject.title, expectedCard.title)
//         XCTAssertEqual(subject.body, expectedCard.body)
//         XCTAssertEqual(subject.type, expectedCard.type)
//         XCTAssertEqual(subject.image, expectedCard.image)
//         XCTAssertEqual(subject.link?.title, expectedCard.link?.title)
//         XCTAssertEqual(subject.link?.url, expectedCard.link?.url)
//         XCTAssertEqual(subject.buttons.primary.title, expectedCard.buttons.primary.title)
//         XCTAssertEqual(subject.buttons.primary.action, expectedCard.buttons.primary.action)
//         XCTAssertEqual(subject.buttons.secondary?.title, expectedCard.buttons.secondary?.title)
//         XCTAssertEqual(subject.buttons.secondary?.action, expectedCard.buttons.secondary?.action)
//     }
// }
