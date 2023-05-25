// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class OnboardingTelemetryUtility: OnboardingTelemetryProtocol {
    // MARK: - Properties
    private var cardOrder: [String]

    // MARK: - Initializer
    init(with model: OnboardingViewModel) {
        self.cardOrder = model.cards.map { $0.name }
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
            Key.sequencePosition.rawValue: sequencePosition(for: cardName, from: cardOrder)
        ]
    }

    private func sequenceID(from sequence: [String]) -> String {
        return sequence.joined(separator: "_")
    }

    // If the card is not available in the original card order, return -1
    // to indicate an error in telemetry
    private func sequencePosition(
        for cardName: String,
        from sequence: [String]
    ) -> String {
        return String(sequence.firstIndex { $0 == cardName } ?? -1)
    }

    private func buildAdditioalButtonTelemetryExtras(
        using buttonAction: OnboardingActions
    ) -> [String: String] {
        return [TelemetryWrapper.EventExtraKey.buttonAction.rawValue: buttonAction.rawValue]
    }
}
