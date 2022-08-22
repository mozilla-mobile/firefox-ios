// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Glean

@testable import Client

class OnboardingCardViewModelTests: XCTestCase {

    var sut: OnboardingCardViewModel!

    override func setUp() {
        super.setUp()
        Glean.shared.resetGlean(clearStores: true)
    }

    override func tearDown() {
        super.tearDown()
        Glean.shared.resetGlean(clearStores: true)
        sut = nil
    }

    func testSendOnboardingCardView_WelcomeCard() {
        sut = OnboardingCardViewModel(cardType: .welcome,
                                      infoModel: createInfoModel(),
                                      isv106Version: false)
        sut.sendCardViewTelemetry()

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.cardView)
    }

    func testSendOnboardingCardView_WallpaperCard() {
        sut = OnboardingCardViewModel(cardType: .wallpapers,
                                      infoModel: createInfoModel(),
                                      isv106Version: false)
        sut.sendCardViewTelemetry()

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.cardView)
    }

    func testSendOnboardingCardView_SyncCard() {
        sut = OnboardingCardViewModel(cardType: .signSync,
                                      infoModel: createInfoModel(),
                                      isv106Version: false)
        sut.sendCardViewTelemetry()

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.cardView)
    }

    func testSendUpgradeCardView_WelcomeCard() {
        sut = OnboardingCardViewModel(cardType: .updateWelcome,
                                      infoModel: createInfoModel(),
                                      isv106Version: false)
        sut.sendCardViewTelemetry()

        testEventMetricRecordingSuccess(metric: GleanMetrics.Upgrade.cardView)
    }

    func testSendUpgradeCardView_SyncCard() {
        sut = OnboardingCardViewModel(cardType: .updateSignSync,
                                      infoModel: createInfoModel(),
                                      isv106Version: false)
        sut.sendCardViewTelemetry()

        testEventMetricRecordingSuccess(metric: GleanMetrics.Upgrade.cardView)
    }

    // MARK: - Primary tap
    func testSendOnboardingPrimaryTap_WelcomeCard() {
        sut = OnboardingCardViewModel(cardType: .welcome,
                                      infoModel: createInfoModel(),
                                      isv106Version: false)
        sut.sendTelemetryButton(isPrimaryAction: true)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.primaryButtonTap)
    }

    func testSendOnboardingPrimaryTap_WallpaperCard() {
        sut = OnboardingCardViewModel(cardType: .wallpapers,
                                      infoModel: createInfoModel(),
                                      isv106Version: false)
        sut.sendTelemetryButton(isPrimaryAction: true)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.primaryButtonTap)
    }

    func testSendOnboardingPrimaryTap_SyncCard() {
        sut = OnboardingCardViewModel(cardType: .signSync,
                                      infoModel: createInfoModel(),
                                      isv106Version: false)
        sut.sendTelemetryButton(isPrimaryAction: true)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.primaryButtonTap)
    }

    func testSendUpgradePrimaryTap_WallpaperCard() {
        sut = OnboardingCardViewModel(cardType: .updateWelcome,
                                      infoModel: createInfoModel(),
                                      isv106Version: false)
        sut.sendTelemetryButton(isPrimaryAction: true)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Upgrade.primaryButtonTap)
    }

    func testSendUpgradePrimaryTap_SyncCard() {
        sut = OnboardingCardViewModel(cardType: .updateSignSync,
                                      infoModel: createInfoModel(),
                                      isv106Version: false)
        sut.sendTelemetryButton(isPrimaryAction: true)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Upgrade.primaryButtonTap)
    }

    // MARK: - Secondary tap
    func testSendOnboardingSecondaryTap_WallpaperCard() {
        sut = OnboardingCardViewModel(cardType: .wallpapers,
                                      infoModel: createInfoModel(),
                                      isv106Version: false)
        sut.sendTelemetryButton(isPrimaryAction: false)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.secondaryButtonTap)
    }

    func testSendOnboardingSecondaryTap_SyncCard() {
        sut = OnboardingCardViewModel(cardType: .signSync,
                                      infoModel: createInfoModel(),
                                      isv106Version: false)
        sut.sendTelemetryButton(isPrimaryAction: false)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.secondaryButtonTap)
    }

    func testSendUpgradeSecondaryTap_SyncCard() {
        sut = OnboardingCardViewModel(cardType: .updateSignSync,
                                      infoModel: createInfoModel(),
                                      isv106Version: false)
        sut.sendTelemetryButton(isPrimaryAction: false)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Upgrade.secondaryButtonTap)
    }

    // MARK: Private
    private func createInfoModel() -> OnboardingModelProtocol {
        return OnboardingInfoModel(image: nil,
                                   title: "Title",
                                   description: "Description",
                                   primaryAction: "Button1",
                                   secondaryAction: "Button2",
                                   a11yIdRoot: "A11yId")
    }

}
