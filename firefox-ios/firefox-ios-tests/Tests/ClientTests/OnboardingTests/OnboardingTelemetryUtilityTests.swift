// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Glean

@testable import Client

// TODO: FXIOS-13514 - Migrate OnboardingTelemetryUtilityTests to use mock telemetry or GleanWrapper
class OnboardingTelemetryUtilityTests: XCTestCase {
    typealias CardNames = NimbusOnboardingTestingConfigUtility.CardOrder

    override func setUp() {
        super.setUp()
        setupTelemetry(with: MockProfile())
    }

    override func tearDown() {
        tearDownTelemetry()
        super.tearDown()
    }

    // MARK: - Card View telemetry
    func testSendOnboardingCardView_WelcomeCard_Success() throws {
        let subject = createTelemetryUtility(for: .freshInstall)

        subject.sendCardViewTelemetry(from: CardNames.welcome.rawValue)

        try testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.cardView)
    }

    func testSendOnboardingCardView_SyncCard_Success() throws {
        let subject = createTelemetryUtility(for: .freshInstall)

        subject.sendCardViewTelemetry(from: CardNames.sync.rawValue)

        try testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.cardView)
    }

    func testSendOnboardingCardView_NotificationsCard_Success() throws {
        let subject = createTelemetryUtility(for: .freshInstall)

        subject.sendCardViewTelemetry(from: CardNames.notifications.rawValue)

        try testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.cardView)
    }

    func testSendOnboardingCardView_UpgradeSyncCard_Success() throws {
        let subject = createTelemetryUtility(for: .upgrade)

        subject.sendCardViewTelemetry(from: CardNames.updateSync.rawValue)

        try testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.cardView)
    }

    func testSendOnboardingCardView_UpgradeWelcomeCard_Success() throws {
        let subject = createTelemetryUtility(for: .upgrade)

        subject.sendCardViewTelemetry(from: CardNames.updateWelcome.rawValue)

        try testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.cardView)
    }

    // MARK: - Primary tap
    func testSendOnboardingPrimaryTap_WelcomeCard() throws {
        let isPrimaryButton = true
        let subject = createTelemetryUtility(for: .freshInstall)

        subject.sendButtonActionTelemetry(from: CardNames.welcome.rawValue,
                                          with: .forwardOneCard,
                                          and: isPrimaryButton)

        try testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.primaryButtonTap)
    }

    func testSendOnboardingPrimaryTap_UpgradeWelcomeCard() throws {
        let isPrimaryButton = true
        let subject = createTelemetryUtility(for: .upgrade)

        subject.sendButtonActionTelemetry(from: CardNames.updateWelcome.rawValue,
                                          with: .setDefaultBrowser,
                                          and: isPrimaryButton)

        try testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.primaryButtonTap)
    }

    // MARK: - Secondary tap
    func testSendOnboardingSecondaryTap_SyncCard() throws {
        let isPrimaryButton = false
        let subject = createTelemetryUtility(for: .freshInstall)

        subject.sendButtonActionTelemetry(from: CardNames.sync.rawValue,
                                          with: .forwardOneCard,
                                          and: isPrimaryButton)

        try testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.secondaryButtonTap)
    }

    func testSendOnboardingSecondaryTap_UpdateSyncCard() throws {
        let isPrimaryButton = false
        let subject = createTelemetryUtility(for: .upgrade)

        subject.sendButtonActionTelemetry(from: CardNames.updateSync.rawValue,
                                          with: .forwardOneCard,
                                          and: isPrimaryButton)

        try testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.secondaryButtonTap)
    }

    // MARK: - Multiple Choice Buttons
    func testSendOnboardingMultipleChoiceButton() throws {
        let subject = createTelemetryUtility(for: .freshInstall)

        subject.sendMultipleChoiceButtonActionTelemetry(from: CardNames.welcome.rawValue,
                                                        with: .themeDark)

        try testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.multipleChoiceButtonTap)
    }

    // MARK: - Close
    func testSendOnboardingClose_NotificationsCard() throws {
        let subject = createTelemetryUtility(for: .freshInstall)

        subject.sendDismissOnboardingTelemetry(from: CardNames.notifications.rawValue)

        try testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.closeTap)
    }

    // MARK: Private
    private func createTelemetryUtility(
        for onboardingType: OnboardingType,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OnboardingTelemetryUtility {
        let nimbusConfigUtility = NimbusOnboardingTestingConfigUtility()
        nimbusConfigUtility.setupNimbus(withOrder: NimbusOnboardingTestingConfigUtility.CardOrder.allCards)
        let model = NimbusOnboardingFeatureLayer().getOnboardingModel(for: onboardingType)

        let telemetryUtility = OnboardingTelemetryUtility(with: model)
        trackForMemoryLeaks(telemetryUtility, file: file, line: line)

        return telemetryUtility
    }
}
