// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Glean

@testable import Client

final class OnboardingTelemetryUtilityTests: XCTestCase {
    typealias CardNames = NimbusOnboardingTestingConfigUtility.CardOrder
    var mockGleanWrapper: MockGleanWrapper!

    override func setUp() async throws {
        try await super.setUp()
        await DependencyHelperMock().bootstrapDependencies()
        mockGleanWrapper = MockGleanWrapper()
    }

    override func tearDown() async throws {
        mockGleanWrapper = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - Card View telemetry
    func testSendOnboardingCardView_WelcomeCard_Success() throws {
        let subject = createTelemetryUtility(for: .freshInstall)
        let event = GleanMetrics.Onboarding.cardView
        typealias EventExtrasType = GleanMetrics.Onboarding.CardViewExtra

        subject.sendCardViewTelemetry(from: CardNames.welcome.rawValue)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.cardType, CardNames.welcome.rawValue)
        XCTAssertEqual(savedExtras.onboardingVariant, "legacy")
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testSendOnboardingCardView_SyncCard_Success() throws {
        let subject = createTelemetryUtility(for: .freshInstall)
        let event = GleanMetrics.Onboarding.cardView
        typealias EventExtrasType = GleanMetrics.Onboarding.CardViewExtra

        subject.sendCardViewTelemetry(from: CardNames.sync.rawValue)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.cardType, CardNames.sync.rawValue)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testSendOnboardingCardView_NotificationsCard_Success() throws {
        let subject = createTelemetryUtility(for: .freshInstall)
        let event = GleanMetrics.Onboarding.cardView
        typealias EventExtrasType = GleanMetrics.Onboarding.CardViewExtra

        subject.sendCardViewTelemetry(from: CardNames.notifications.rawValue)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.cardType, CardNames.notifications.rawValue)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testSendOnboardingCardView_UpgradeSyncCard_Success() throws {
        let subject = createTelemetryUtility(for: .upgrade)
        let event = GleanMetrics.Onboarding.cardView
        typealias EventExtrasType = GleanMetrics.Onboarding.CardViewExtra

        subject.sendCardViewTelemetry(from: CardNames.updateSync.rawValue)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.cardType, CardNames.updateSync.rawValue)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testSendOnboardingCardView_UpgradeWelcomeCard_Success() throws {
        let subject = createTelemetryUtility(for: .upgrade)
        let event = GleanMetrics.Onboarding.cardView
        typealias EventExtrasType = GleanMetrics.Onboarding.CardViewExtra

        subject.sendCardViewTelemetry(from: CardNames.updateWelcome.rawValue)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.cardType, CardNames.updateWelcome.rawValue)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    // MARK: - Primary tap
    func testSendOnboardingPrimaryTap_WelcomeCard() throws {
        let isPrimaryButton = true
        let subject = createTelemetryUtility(for: .freshInstall)
        let event = GleanMetrics.Onboarding.primaryButtonTap
        typealias EventExtrasType = GleanMetrics.Onboarding.PrimaryButtonTapExtra

        subject.sendButtonActionTelemetry(from: CardNames.welcome.rawValue,
                                          with: .forwardOneCard,
                                          and: isPrimaryButton)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.cardType, CardNames.welcome.rawValue)
        XCTAssertEqual(savedExtras.buttonAction, OnboardingActions.forwardOneCard.rawValue)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testSendOnboardingPrimaryTap_UpgradeWelcomeCard() throws {
        let isPrimaryButton = true
        let subject = createTelemetryUtility(for: .upgrade)
        let event = GleanMetrics.Onboarding.primaryButtonTap
        typealias EventExtrasType = GleanMetrics.Onboarding.PrimaryButtonTapExtra

        subject.sendButtonActionTelemetry(from: CardNames.updateWelcome.rawValue,
                                          with: .setDefaultBrowser,
                                          and: isPrimaryButton)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.cardType, CardNames.updateWelcome.rawValue)
        XCTAssertEqual(savedExtras.buttonAction, OnboardingActions.setDefaultBrowser.rawValue)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    // MARK: - Secondary tap
    func testSendOnboardingSecondaryTap_SyncCard() throws {
        let isPrimaryButton = false
        let subject = createTelemetryUtility(for: .freshInstall)
        let event = GleanMetrics.Onboarding.secondaryButtonTap
        typealias EventExtrasType = GleanMetrics.Onboarding.SecondaryButtonTapExtra

        subject.sendButtonActionTelemetry(from: CardNames.sync.rawValue,
                                          with: .forwardOneCard,
                                          and: isPrimaryButton)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.cardType, CardNames.sync.rawValue)
        XCTAssertEqual(savedExtras.buttonAction, OnboardingActions.forwardOneCard.rawValue)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testSendOnboardingSecondaryTap_UpdateSyncCard() throws {
        let isPrimaryButton = false
        let subject = createTelemetryUtility(for: .upgrade)
        let event = GleanMetrics.Onboarding.secondaryButtonTap
        typealias EventExtrasType = GleanMetrics.Onboarding.SecondaryButtonTapExtra

        subject.sendButtonActionTelemetry(from: CardNames.updateSync.rawValue,
                                          with: .forwardOneCard,
                                          and: isPrimaryButton)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.cardType, CardNames.updateSync.rawValue)
        XCTAssertEqual(savedExtras.buttonAction, OnboardingActions.forwardOneCard.rawValue)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    // MARK: - Multiple Choice Buttons
    func testSendOnboardingMultipleChoiceButton() throws {
        let subject = createTelemetryUtility(for: .freshInstall)
        let event = GleanMetrics.Onboarding.multipleChoiceButtonTap
        typealias EventExtrasType = GleanMetrics.Onboarding.MultipleChoiceButtonTapExtra

        subject.sendMultipleChoiceButtonActionTelemetry(from: CardNames.welcome.rawValue,
                                                        with: .themeDark)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.cardType, CardNames.welcome.rawValue)
        XCTAssertEqual(savedExtras.buttonAction, OnboardingMultipleChoiceAction.themeDark.rawValue)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    // MARK: - Close
    func testSendOnboardingClose_NotificationsCard() throws {
        let subject = createTelemetryUtility(for: .freshInstall)
        let event = GleanMetrics.Onboarding.closeTap
        typealias EventExtrasType = GleanMetrics.Onboarding.CloseTapExtra

        subject.sendDismissOnboardingTelemetry(from: CardNames.notifications.rawValue)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.cardType, CardNames.notifications.rawValue)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    // MARK: - Modern Onboarding Tests
    func testSendModernOnboardingCardView_WelcomeCard_Success() throws {
        let subject = createModernTelemetryUtility(for: .freshInstall)
        let event = GleanMetrics.Onboarding.cardView
        typealias EventExtrasType = GleanMetrics.Onboarding.CardViewExtra

        subject.sendCardViewTelemetry(from: CardNames.welcome.rawValue)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.cardType, CardNames.welcome.rawValue)
        XCTAssertEqual(savedExtras.onboardingVariant, "modern")
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testSendModernOnboardingPrimaryButtonTap() throws {
        let subject = createModernTelemetryUtility(for: .freshInstall)
        let event = GleanMetrics.Onboarding.primaryButtonTap
        typealias EventExtrasType = GleanMetrics.Onboarding.PrimaryButtonTapExtra

        subject.sendButtonActionTelemetry(from: CardNames.welcome.rawValue,
                                          with: .forwardOneCard,
                                          and: true)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.cardType, CardNames.welcome.rawValue)
        XCTAssertEqual(savedExtras.buttonAction, OnboardingActions.forwardOneCard.rawValue)
        XCTAssertEqual(savedExtras.onboardingVariant, "modern")
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testOnboardingVariant_Modern_IsSetCorrectly() throws {
        let subject = createModernTelemetryUtility(for: .freshInstall)
        typealias EventExtrasType = GleanMetrics.Onboarding.CardViewExtra

        subject.sendCardViewTelemetry(from: CardNames.welcome.rawValue)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        XCTAssertEqual(savedExtras.onboardingVariant, "modern")
    }

    func testOnboardingVariant_Japan_IsSetCorrectly() throws {
        let subject = createModernTelemetryUtility(for: .freshInstall, variant: .japan)
        typealias EventExtrasType = GleanMetrics.Onboarding.CardViewExtra

        subject.sendCardViewTelemetry(from: CardNames.welcome.rawValue)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        XCTAssertEqual(savedExtras.onboardingVariant, "japan")
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

        let telemetryUtility = OnboardingTelemetryUtility(
            with: model,
            gleanWrapper: mockGleanWrapper
        )
        trackForMemoryLeaks(telemetryUtility, file: file, line: line)

        return telemetryUtility
    }

    private func createModernTelemetryUtility(
        for onboardingType: OnboardingType,
        variant: OnboardingVariant = .modern,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OnboardingTelemetryUtility {
        let nimbusConfigUtility = NimbusOnboardingTestingConfigUtility()
        let cardOrder: [NimbusOnboardingTestingConfigUtility.CardOrder] = {
            switch onboardingType {
            case .freshInstall:
                return [.welcome, .notifications, .sync]
            case .upgrade:
                return [.updateWelcome, .updateSync]
            }
        }()
        nimbusConfigUtility.setupNimbus(withOrder: cardOrder, uiVariant: variant)
        let layer = NimbusOnboardingKitFeatureLayer(
            onboardingVariant: variant,
            isDefaultBrowser: false,
            isIpad: false
        )
        let model = layer.getOnboardingModel(for: onboardingType)

        let telemetryUtility = OnboardingTelemetryUtility(
            with: model,
            onboardingVariant: variant,
            gleanWrapper: mockGleanWrapper
        )
        trackForMemoryLeaks(telemetryUtility, file: file, line: line)

        return telemetryUtility
    }
}
