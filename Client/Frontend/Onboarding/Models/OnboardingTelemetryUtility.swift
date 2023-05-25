// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class OnboardingTelemetryUtility: OnboardingTelemetryProtocol {
    // MARK: - Properties
    private let cardOrder: [String]
    private let flowType: String

    // MARK: - Initializer
    init(with model: OnboardingViewModel) {
        self.cardOrder = model.cards.map { $0.name }
        self.flowType = model.cards.first?.type.rawValue ?? "unknown"
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

    func sendDismissOnboardingTelemetry(from cardName: String) {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .onboardingClose,
            value: nil,
            extras: buildBaseTelemetryExtras(using: cardName))
    }

    // MARK: - Private fuctions
    private func buildBaseTelemetryExtras(
        using cardName: String
    ) -> [String: String] {
        typealias Key = TelemetryWrapper.EventExtraKey
        return [
            Key.cardType.rawValue: cardName,
            Key.sequenceID.rawValue: sequenceID(from: cardOrder),
            Key.sequencePosition.rawValue: sequencePosition(for: cardName, from: cardOrder),
            Key.flowType.rawValue: flowType
        ]
    }

    private func sequenceID(from sequence: [String]) -> String {
        return sequence.joined(separator: "_")
    }

    // If the card is not available in the original card order, return 0 (zero)
    // to indicate an error in telemetry. Given how ``NimbusOnboardingFeatureLayer``
    // is built & tested, this should never happen, but we want eyes on it, in
    // the case that it does.
    private func sequencePosition(
        for cardName: String,
        from sequence: [String]
    ) -> String {
        // We add 1 to a regular index for a DataScience requested sequence
        // starting at 1, rather than 0.
        return String((sequence.firstIndex { $0 == cardName } ?? -1) + 1)
    }

    private func buildAdditioalButtonTelemetryExtras(
        using buttonAction: OnboardingActions
    ) -> [String: String] {
        return [TelemetryWrapper.EventExtraKey.buttonAction.rawValue: buttonAction.rawValue]
    }
}
