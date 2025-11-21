// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

final class OnboardingTelemetryUtility: OnboardingTelemetryProtocol {
    // MARK: - Properties
    private let cardOrder: [String]
    private let flowType: String
    private let onboardingVersion: String
    private let gleanWrapper: GleanWrapper

    // MARK: - Initializer
    init(
        with model: OnboardingViewModel,
        onboardingVersion: String = "legacy",
        gleanWrapper: GleanWrapper = DefaultGleanWrapper()
    ) {
        self.cardOrder = model.cards.map { $0.name }
        self.flowType = model.cards.first?.onboardingType.rawValue ?? "unknown"
        self.onboardingVersion = onboardingVersion
        self.gleanWrapper = gleanWrapper
    }

    init(
        with model: OnboardingKitViewModel,
        onboardingVersion: String = "modern",
        gleanWrapper: GleanWrapper = DefaultGleanWrapper()
    ) {
        self.cardOrder = model.cards.map { $0.name }
        self.flowType = model.cards.first?.onboardingType.rawValue ?? "unknown"
        self.onboardingVersion = onboardingVersion
        self.gleanWrapper = gleanWrapper
    }

    // MARK: - Public methods
    func sendCardViewTelemetry(from cardName: String) {
        let extras = GleanMetrics.Onboarding.CardViewExtra(
            cardType: cardName,
            flowType: flowType,
            onboardingVersion: onboardingVersion,
            sequenceId: sequenceID(from: cardOrder),
            sequencePosition: sequencePosition(for: cardName, from: cardOrder)
        )
        gleanWrapper.recordEvent(for: GleanMetrics.Onboarding.cardView, extras: extras)
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
                onboardingVersion: baseExtras.onboardingVersion,
                sequenceId: baseExtras.sequenceId,
                sequencePosition: baseExtras.sequencePosition
            )
            gleanWrapper.recordEvent(for: GleanMetrics.Onboarding.primaryButtonTap, extras: extras)
        } else {
            let extras = GleanMetrics.Onboarding.SecondaryButtonTapExtra(
                buttonAction: buttonAction,
                cardType: baseExtras.cardType,
                flowType: baseExtras.flowType,
                onboardingVersion: baseExtras.onboardingVersion,
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
            onboardingVersion: baseExtras.onboardingVersion,
            sequenceId: baseExtras.sequenceId,
            sequencePosition: baseExtras.sequencePosition
        )
        gleanWrapper.recordEvent(for: GleanMetrics.Onboarding.multipleChoiceButtonTap, extras: extras)
    }

    func sendDismissOnboardingTelemetry(from cardName: String) {
        let extras = GleanMetrics.Onboarding.CloseTapExtra(
            cardType: cardName,
            flowType: flowType,
            onboardingVersion: onboardingVersion,
            sequenceId: sequenceID(from: cardOrder),
            sequencePosition: sequencePosition(for: cardName, from: cardOrder)
        )
        gleanWrapper.recordEvent(for: GleanMetrics.Onboarding.closeTap, extras: extras)
    }

    // MARK: - Private functions
    private struct BaseExtras {
        let cardType: String
        let flowType: String
        let onboardingVersion: String
        let sequenceId: String
        let sequencePosition: String
    }

    private func buildBaseExtras(using cardName: String) -> BaseExtras {
        return BaseExtras(
            cardType: cardName,
            flowType: flowType,
            onboardingVersion: onboardingVersion,
            sequenceId: sequenceID(from: cardOrder),
            sequencePosition: sequencePosition(for: cardName, from: cardOrder)
        )
    }

    private func sequenceID(from sequence: [String]) -> String {
        return sequence.joined(separator: "_")
    }

    private func sequencePosition(
        for cardName: String,
        from sequence: [String]
    ) -> String {
        let index = sequence.firstIndex { $0 == cardName } ?? -1
        return String(index + 1)
    }
}
