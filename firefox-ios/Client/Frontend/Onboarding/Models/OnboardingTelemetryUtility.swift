// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class OnboardingTelemetryUtility: OnboardingTelemetryProtocol {
    // MARK: - Properties
    private let cardOrder: [String]
    private let flowType: String
    private let onboardingVersion: String

    // MARK: - Initializer
    init(with model: OnboardingViewModel, onboardingVersion: String = "legacy") {
        self.cardOrder = model.cards.map { $0.name }
        self.flowType = model.cards.first?.onboardingType.rawValue ?? "unknown"
        self.onboardingVersion = onboardingVersion
    }

    init(with model: OnboardingKitViewModel, onboardingVersion: String = "modern") {
        self.cardOrder = model.cards.map { $0.name }
        self.flowType = model.cards.first?.onboardingType.rawValue ?? "unknown"
        self.onboardingVersion = onboardingVersion
    }

    // MARK: - Public methods
    func sendCardViewTelemetry(from cardName: String) {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .view,
            object: .onboardingCardView,
            value: nil,
            extras: buildBaseTelemetryExtras(using: cardName))
    }

    func sendButtonActionTelemetry(
        from cardName: String,
        with action: OnboardingActions,
        and primaryButton: Bool
    ) {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: primaryButton ? .onboardingPrimaryButton : .onboardingSecondaryButton,
            value: nil,
            extras: buildBaseTelemetryExtras(using: cardName)
                .merging(
                    buildAdditioalButtonTelemetryExtras(using: action),
                    uniquingKeysWith: { (first, _) in first }))
    }

    func sendMultipleChoiceButtonActionTelemetry(
        from cardName: String,
        with action: OnboardingMultipleChoiceAction
    ) {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .onboardingMultipleChoiceButton,
            value: nil,
            extras: buildBaseTelemetryExtras(using: cardName)
                .merging(
                    buildAdditionalMultipleChoiceButtonTelemetryExtras(using: action),
                    uniquingKeysWith: { (first, _) in first }))
    }

    func sendDismissOnboardingTelemetry(from cardName: String) {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .onboardingClose,
            value: nil,
            extras: buildBaseTelemetryExtras(using: cardName))
    }

    // MARK: - Private functions
    private func buildBaseTelemetryExtras(
        using cardName: String
    ) -> [String: String] {
        typealias Key = TelemetryWrapper.EventExtraKey
        return [
            Key.cardType.rawValue: cardName,
            Key.sequenceID.rawValue: sequenceID(from: cardOrder),
            Key.sequencePosition.rawValue: sequencePosition(for: cardName, from: cardOrder),
            Key.flowType.rawValue: flowType,
            Key.onboardingVersion.rawValue: onboardingVersion
        ]
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

    private func buildAdditioalButtonTelemetryExtras(
        using buttonAction: OnboardingActions
    ) -> [String: String] {
        return [TelemetryWrapper.EventExtraKey.buttonAction.rawValue: buttonAction.rawValue]
    }

    private func buildAdditionalMultipleChoiceButtonTelemetryExtras(
        using buttonAction: OnboardingMultipleChoiceAction
    ) -> [String: String] {
        return [TelemetryWrapper.EventExtraKey.multipleChoiceButtonAction.rawValue: buttonAction.rawValue]
    }
}
