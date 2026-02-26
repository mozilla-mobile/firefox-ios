// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean
import OnboardingKit
import Shared

final class OnboardingTelemetryUtility: OnboardingTelemetryProtocol {
    // MARK: - Properties
    private let cardOrder: [String]
    private let flowType: String
    private let onboardingVariant: OnboardingVariant
    private let onboardingReason: OnboardingReason
    private let gleanWrapper: GleanWrapper

    // MARK: - Initializer (Legacy)
    init(
        with model: OnboardingKitViewModel,
        onboardingReason: OnboardingReason,
        gleanWrapper: GleanWrapper = DefaultGleanWrapper()
    ) {
        self.cardOrder = model.cards.map { $0.name }
        self.flowType = model.cards.first?.onboardingType.rawValue ?? "unknown"
        self.onboardingVariant = .legacy
        self.onboardingReason = onboardingReason
        self.gleanWrapper = gleanWrapper
    }

    // MARK: - Initializer (Modern)
    init(
        with model: OnboardingKitViewModel,
        onboardingVariant: OnboardingVariant,
        onboardingReason: OnboardingReason,
        gleanWrapper: GleanWrapper = DefaultGleanWrapper()
    ) {
        self.cardOrder = model.cards.map { $0.name }
        self.flowType = model.cards.first?.onboardingType.rawValue ?? "unknown"
        self.onboardingVariant = onboardingVariant
        self.onboardingReason = onboardingReason
        self.gleanWrapper = gleanWrapper
    }

    // MARK: - Public methods
    func sendCardViewTelemetry(from cardName: String) {
        let extras = GleanMetrics.Onboarding.CardViewExtra(
            cardType: cardName,
            flowType: flowType,
            onboardingReason: onboardingReason.rawValue,
            onboardingVariant: onboardingVariant.rawValue,
            sequenceId: sequenceID(from: cardOrder),
            sequencePosition: sequencePosition(for: cardName, from: cardOrder)
        )
        gleanWrapper.recordEvent(for: GleanMetrics.Onboarding.cardView, extras: extras)
        gleanWrapper.submit(ping: GleanMetrics.Pings.shared.onboarding)
    }

    func sendButtonActionTelemetry(
        from cardName: String,
        with action: OnboardingActions,
        and primaryButton: Bool
    ) {
        let baseExtras = buildBaseExtras(using: cardName)
        let buttonAction = action.rawValue

        if primaryButton {
            let extras = GleanMetrics.Onboarding.PrimaryButtonTapExtra(
                buttonAction: buttonAction,
                cardType: baseExtras.cardType,
                flowType: baseExtras.flowType,
                onboardingReason: onboardingReason.rawValue,
                onboardingVariant: baseExtras.onboardingVariant,
                sequenceId: baseExtras.sequenceId,
                sequencePosition: baseExtras.sequencePosition
            )
            gleanWrapper.recordEvent(for: GleanMetrics.Onboarding.primaryButtonTap, extras: extras)
        } else {
            let extras = GleanMetrics.Onboarding.SecondaryButtonTapExtra(
                buttonAction: buttonAction,
                cardType: baseExtras.cardType,
                flowType: baseExtras.flowType,
                onboardingReason: onboardingReason.rawValue,
                onboardingVariant: baseExtras.onboardingVariant,
                sequenceId: baseExtras.sequenceId,
                sequencePosition: baseExtras.sequencePosition
            )
            gleanWrapper.recordEvent(for: GleanMetrics.Onboarding.secondaryButtonTap, extras: extras)
        }
    }

    func sendMultipleChoiceButtonActionTelemetry(
        from cardName: String,
        with action: OnboardingMultipleChoiceAction
    ) {
        let baseExtras = buildBaseExtras(using: cardName)
        let extras = GleanMetrics.Onboarding.MultipleChoiceButtonTapExtra(
            buttonAction: action.rawValue,
            cardType: baseExtras.cardType,
            flowType: baseExtras.flowType,
            onboardingReason: onboardingReason.rawValue,
            onboardingVariant: baseExtras.onboardingVariant,
            sequenceId: baseExtras.sequenceId,
            sequencePosition: baseExtras.sequencePosition
        )
        gleanWrapper.recordEvent(for: GleanMetrics.Onboarding.multipleChoiceButtonTap, extras: extras)
    }

    func sendDismissOnboardingTelemetry(from cardName: String) {
        let extras = GleanMetrics.Onboarding.CloseTapExtra(
            cardType: cardName,
            flowType: flowType,
            onboardingReason: onboardingReason.rawValue,
            onboardingVariant: onboardingVariant.rawValue,
            sequenceId: sequenceID(from: cardOrder),
            sequencePosition: sequencePosition(for: cardName, from: cardOrder)
        )
        gleanWrapper.recordEvent(for: GleanMetrics.Onboarding.closeTap, extras: extras)
    }

    func sendGoToSettingsButtonTappedTelemetry() {
        let extras = GleanMetrics.OnboardingDefaultBrowserSheet.GoToSettingsButtonTappedExtra(
            onboardingReason: onboardingReason.rawValue,
            onboardingVariant: onboardingVariant.rawValue
        )
        gleanWrapper.recordEvent(for: GleanMetrics.OnboardingDefaultBrowserSheet.goToSettingsButtonTapped, extras: extras)
    }

    func sendDismissButtonTappedTelemetry() {
        let extras = GleanMetrics.OnboardingDefaultBrowserSheet.DismissButtonTappedExtra(
            onboardingReason: onboardingReason.rawValue,
            onboardingVariant: onboardingVariant.rawValue
        )
        gleanWrapper.recordEvent(for: GleanMetrics.OnboardingDefaultBrowserSheet.dismissButtonTapped, extras: extras)
    }

    func sendOnboardingShownTelemetry() {
        let extras = GleanMetrics.Onboarding.ShownExtra(onboardingReason: onboardingReason.rawValue)
        gleanWrapper.recordEvent(for: GleanMetrics.Onboarding.shown, extras: extras)
        gleanWrapper.submit(ping: GleanMetrics.Pings.shared.onboarding)
    }

    func sendOnboardingDismissedTelemetry(outcome: OnboardingFlowOutcome) {
        let extras = GleanMetrics.Onboarding.DismissedExtra(
            method: outcome.rawValue,
            onboardingReason: onboardingReason.rawValue
        )
        gleanWrapper.recordEvent(for: GleanMetrics.Onboarding.dismissed, extras: extras)
        gleanWrapper.submit(ping: GleanMetrics.Pings.shared.onboarding)
    }

    func sendWallpaperSelectorViewTelemetry() {
        let extras = GleanMetrics.Onboarding.WallpaperSelectorViewExtra(
            onboardingReason: onboardingReason.rawValue
        )
        gleanWrapper.recordEvent(for: GleanMetrics.Onboarding.wallpaperSelectorView, extras: extras)
    }

    func sendWallpaperSelectorCloseTelemetry() {
        let extras = GleanMetrics.Onboarding.WallpaperSelectorCloseExtra(
            onboardingReason: onboardingReason.rawValue
        )
        gleanWrapper.recordEvent(for: GleanMetrics.Onboarding.wallpaperSelectorClose, extras: extras)
    }

    func sendWallpaperSelectorSelectedTelemetry(wallpaperName: String, wallpaperType: String) {
        let extras = GleanMetrics.Onboarding.WallpaperSelectorSelectedExtra(
            onboardingReason: onboardingReason.rawValue,
            wallpaperName: wallpaperName,
            wallpaperType: wallpaperType
        )
        gleanWrapper.recordEvent(for: GleanMetrics.Onboarding.wallpaperSelectorSelected, extras: extras)
    }

    func sendWallpaperSelectedTelemetry(wallpaperName: String, wallpaperType: String) {
        let extras = GleanMetrics.Onboarding.WallpaperSelectedExtra(
            onboardingReason: onboardingReason.rawValue,
            wallpaperName: wallpaperName,
            wallpaperType: wallpaperType
        )
        gleanWrapper.recordEvent(for: GleanMetrics.Onboarding.wallpaperSelected, extras: extras)
    }

    func sendEngagementNotificationTappedTelemetry() {
        let extras = GleanMetrics.Onboarding.EngagementNotificationTappedExtra(
            onboardingReason: onboardingReason.rawValue
        )
        gleanWrapper.recordEvent(for: GleanMetrics.Onboarding.engagementNotificationTapped, extras: extras)
    }

    func sendEngagementNotificationCancelTelemetry() {
        let extras = GleanMetrics.Onboarding.EngagementNotificationCancelExtra(
            onboardingReason: onboardingReason.rawValue
        )
        gleanWrapper.recordEvent(for: GleanMetrics.Onboarding.engagementNotificationCancel, extras: extras)
    }

    private struct BaseExtras {
        let cardType: String
        let flowType: String
        let onboardingVariant: String
        let sequenceId: String
        let sequencePosition: String
    }

    private func buildBaseExtras(using cardName: String) -> BaseExtras {
        return BaseExtras(
            cardType: cardName,
            flowType: flowType,
            onboardingVariant: onboardingVariant.rawValue,
            sequenceId: sequenceID(from: cardOrder),
            sequencePosition: sequencePosition(for: cardName, from: cardOrder)
        )
    }

    private func sequenceID(from sequence: [String]) -> String {
        return sequence.joined(separator: "_")
    }

    /// If the card is not available in the original card order, return 0 (zero) to indicate an error in telemetry. Given how
    /// `NimbusOnboardingFeatureLayer` is built & tested, this should never happen, but we want eyes on it, in the case that
    /// it does.
    private func sequencePosition(
        for cardName: String,
        from sequence: [String]
    ) -> String {
        // We add 1 to a regular index for a DataScience requested sequence starting at 1, rather than 0.
        let index = sequence.firstIndex { $0 == cardName } ?? -1
        return String(index + 1)
    }
}
