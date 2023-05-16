// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Glean

@testable import Client

class OnboardingCardViewModelTests: XCTestCase {
// Disabled. To be fixed when https://mozilla-hub.atlassian.net/browse/FXIOS-6358
// is implemented.
//    var subject: OnboardingCardViewModel!
//
//    override func setUp() {
//        super.setUp()
//        Glean.shared.resetGlean(clearStores: true)
//    }
//
//    override func tearDown() {
//        super.tearDown()
//        Glean.shared.resetGlean(clearStores: true)
//        subject = nil
//    }
//
//    func testSendOnboardingCardView_WelcomeCard() {
//        subject = OnboardingCardViewModel(cardType: .welcome,
//                                          infoModel: createInfoModel())
//        subject.sendCardViewTelemetry()
//
//        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.cardView)
//    }
//
//    func testSendOnboardingCardView_SyncCard() {
//        subject = OnboardingCardViewModel(cardType: .signSync,
//                                          infoModel: createInfoModel())
//        subject.sendCardViewTelemetry()
//
//        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.cardView)
//    }
//
//    func testSendUpgradeCardView_WelcomeCard() {
//        subject = OnboardingCardViewModel(cardType: .updateWelcome,
//                                          infoModel: createInfoModel())
//        subject.sendCardViewTelemetry()
//
//        testEventMetricRecordingSuccess(metric: GleanMetrics.Upgrade.cardView)
//    }
//
//    func testSendUpgradeCardView_SyncCard() {
//        subject = OnboardingCardViewModel(cardType: .updateSignSync,
//                                          infoModel: createInfoModel())
//        subject.sendCardViewTelemetry()
//
//        testEventMetricRecordingSuccess(metric: GleanMetrics.Upgrade.cardView)
//    }
//
//    // MARK: - Primary tap
//    func testSendOnboardingPrimaryTap_WelcomeCard() {
//        subject = OnboardingCardViewModel(cardType: .welcome,
//                                          infoModel: createInfoModel())
//        subject.sendTelemetryButton(isPrimaryAction: true)
//
//        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.primaryButtonTap)
//    }
//
//    func testSendOnboardingPrimaryTap_SyncCard() {
//        subject = OnboardingCardViewModel(cardType: .signSync,
//                                          infoModel: createInfoModel())
//        subject.sendTelemetryButton(isPrimaryAction: true)
//
//        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.primaryButtonTap)
//    }
//
//    func testSendUpgradePrimaryTap_WallpaperCard() {
//        subject = OnboardingCardViewModel(cardType: .updateWelcome,
//                                          infoModel: createInfoModel())
//        subject.sendTelemetryButton(isPrimaryAction: true)
//
//        testEventMetricRecordingSuccess(metric: GleanMetrics.Upgrade.primaryButtonTap)
//    }
//
//    func testSendUpgradePrimaryTap_SyncCard() {
//        subject = OnboardingCardViewModel(cardType: .updateSignSync,
//                                          infoModel: createInfoModel())
//        subject.sendTelemetryButton(isPrimaryAction: true)
//
//        testEventMetricRecordingSuccess(metric: GleanMetrics.Upgrade.primaryButtonTap)
//    }
//
//    // MARK: - Secondary tap
//    func testSendOnboardingSecondaryTap_SyncCard() {
//        subject = OnboardingCardViewModel(cardType: .signSync,
//                                          infoModel: createInfoModel())
//        subject.sendTelemetryButton(isPrimaryAction: false)
//
//        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.secondaryButtonTap)
//    }
//
//    func testSendUpgradeSecondaryTap_SyncCard() {
//        subject = OnboardingCardViewModel(cardType: .updateSignSync,
//                                          infoModel: createInfoModel())
//        subject.sendTelemetryButton(isPrimaryAction: false)
//
//        testEventMetricRecordingSuccess(metric: GleanMetrics.Upgrade.secondaryButtonTap)
//    }
//
//    // MARK: Private
//    private func createInfoModel() -> OnboardingCardInfoModelProtocol {
//        return OnboardingCardInfoModel(
//            name: "name",
//            title: "Title",
//            body: "Description",
//            link: OnboardingLinkInfoModel(
//                title: "Link",
//                url: URL(string: "https://macrumors.com")!),
//            buttons: OnboardingButtons(
//                primary: OnboardingButtonInfoModel(title: "Button1", action: .nextCard),
//                secondary: OnboardingButtonInfoModel(title: "Button2", action: .nextCard)),
//            type: .freshInstall,
//            a11yIdRoot: "A11yId",
//            imageID: "image")
//    }
}
