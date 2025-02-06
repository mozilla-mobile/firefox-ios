// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public final class InvestmentsProjection: Publisher {
    public static let shared = InvestmentsProjection()
    public var subscriptions = [Subscription<Int>]()
    let timer = DispatchSource.makeTimerSource(queue: .main)

    init() {
        timer.activate()
        timer.setEventHandler { [weak self] in
            guard let count = self?.totalInvestedAt(Date()) else { return }
            self?.send(count)
        }
        let secondsToOneEuro = max(1/Statistics.shared.investmentPerSecond, 1)
        timer.schedule(deadline: .now(), repeating: secondsToOneEuro)
    }

    public func totalInvestedAt(_ date: Date) -> Int {
        let statistics = Statistics.shared
        let deltaTimeInSeconds = date.timeIntervalSince(statistics.totalInvestmentsLastUpdated)
        return .init(deltaTimeInSeconds * statistics.investmentPerSecond + statistics.totalInvestments)
    }
}
