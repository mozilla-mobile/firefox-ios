// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Glean

@testable import Client

class OnboardingTelemetryUtilityTests: XCTestCase {
    typealias CardNames = NimbusOnboardingConfigUtility.CardOrder
    
    override func setUp() {
        super.setUp()
        Glean.shared.resetGlean(clearStores: true)
    }

    override func tearDown() {
        super.tearDown()
        Glean.shared.resetGlean(clearStores: true)
    }

    // MARK: - Card View telemetry
    func testSendOnboardingCardView_WelcomeCard_Success() {
        let subject = createTelemetryUtility(for: .freshInstall)

        subject.sendCardViewTelemetry(from: CardNames.welcome)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.cardView)
    }

    func testSendOnboardingCardView_SyncCard_Success() {
        let subject = createTelemetryUtility(for: .freshInstall)

        subject.sendCardViewTelemetry(from: CardNames.sync)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.cardView)
    }

    func testSendOnboardingCardView_NotificationsCard_Success() {
        let subject = createTelemetryUtility(for: .freshInstall)

        subject.sendCardViewTelemetry(from: CardNames.notifications)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.cardView)
    }

    func testSendOnboardingCardView_UpgradeSyncCard_Success() {
        let subject = createTelemetryUtility(for: .upgrade)

        subject.sendCardViewTelemetry(from: CardNames.updateSync)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.cardView)
    }

    func testSendOnboardingCardView_UpgradeWelcomeCard_Success() {
        let subject = createTelemetryUtility(for: .upgrade)

        subject.sendCardViewTelemetry(from: CardNames.updateWelcome)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.cardView)
    }

    // MARK: - Primary tap
    func testSendOnboardingPrimaryTap_WelcomeCard() {
        let isPrimaryButton = true
        let subject = createTelemetryUtility(for: .freshInstall)

        subject.sendButtonActionTelemetry(from: CardNames.welcome,
                                          with: .nextCard,
                                          and: isPrimaryButton)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.primaryButtonTap)
    }

    func testSendOnboardingPrimaryTap_UpgradeWelcomeCard() {
        let isPrimaryButton = true
        let subject = createTelemetryUtility(for: .upgrade)

        subject.sendButtonActionTelemetry(from: CardNames.updateWelcome,
                                          with: .setDefaultBrowser,
                                          and: isPrimaryButton)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.primaryButtonTap)
    }

    // MARK: - Secondary tap
    func testSendOnboardingSecondaryTap_SyncCard() {
        let isPrimaryButton = false
        let subject = createTelemetryUtility(for: .freshInstall)

        subject.sendButtonActionTelemetry(from: CardNames.sync,
                                          with: .nextCard,
                                          and: isPrimaryButton)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.secondaryButtonTap)
    }

    func testSendOnboardingSecondaryTap_UpdateSyncCard() {
        let isPrimaryButton = false
        let subject = createTelemetryUtility(for: .upgrade)

        subject.sendButtonActionTelemetry(from: CardNames.updateSync,
                                          with: .nextCard,
                                          and: isPrimaryButton)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.secondaryButtonTap)
    }

    // MARK: - Close
    func testSendOnboardingClose_NotificationsCard() {
        let subject = createTelemetryUtility(for: .freshInstall)

        subject.sendDismissOnboardingTelemetry(from: CardNames.notifications)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.closeTap)
    }

    // MARK: Private
    private func createTelemetryUtility(
        for onboardingType: OnboardingType,
        file: StaticString = #file,
        line: UInt = #line
    ) -> OnboardingTelemetryUtility {
        let nimbusConfigUtility = NimbusOnboardingConfigUtility()
        nimbusConfigUtility.clearNimbus()
        nimbusConfigUtility.setupNimbus(
            withOrder: NimbusOnboardingConfigUtility.CardOrder.allCards)
        let model = NimbusOnboardingFeatureLayer().getOnboardingModel(for: onboardingType)

        let telemetryUtility = OnboardingTelemetryUtility(with: model)
        trackForMemoryLeaks(telemetryUtility, file: file, line: line)

        return telemetryUtility
    }
    private func createInfoModel() -> OnboardingCardInfoModelProtocol {
        return OnboardingCardInfoModel(
            name: "name",
            title: "Title",
            body: "Description",
            link: OnboardingLinkInfoModel(
                title: "Link",
                url: URL(string: "https://macrumors.com")!),
            buttons: OnboardingButtons(
                primary: OnboardingButtonInfoModel(title: "Button1", action: .nextCard),
                secondary: OnboardingButtonInfoModel(title: "Button2", action: .nextCard)),
            type: .freshInstall,
            a11yIdRoot: "A11yId",
            imageID: "image")
    }
}
