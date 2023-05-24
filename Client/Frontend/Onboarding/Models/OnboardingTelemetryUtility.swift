// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class OnboardingTelemetryUtility: OnboardingTelemetryProtocol {
    // MARK: - Properties 6358
    private var cardOrder: [String]

    // MARK: - Initializer
    init(with model: OnboardingViewModel) {
        self.cardOrder = model.cards.map { $0.name }
    }

    // MARK: - Public methods
    func sendCardViewTelemetry(from card: OnboardingCardInfoModelProtocol) {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .view,
                                     object: .onboardingCardView,
                                     value: nil,
                                     extras: buildTelemetryExtras(using: card))
    }

    func sendButtonActionTelemetry() {
    }

    func sendDismissOnboardingTelemetry() {
    }

    // MARK: - Private fuctions
    private func buildTelemetryExtras(
        using card: OnboardingCardInfoModelProtocol
    ) -> [String: Any] {
        typealias Key = TelemetryWrapper.EventExtraKey
        return [
            Key.cardType.rawValue: card.name,
            Key.sequenceID.rawValue: sequenceID(from: cardOrder),
            Key.sequencePosition.rawValue: sequencePosition(for: card.name, from: cardOrder)
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
    ) -> Int {
        return sequence.firstIndex { $0 == cardName } ?? -1
    }

    private func elementType() {
    }
}
