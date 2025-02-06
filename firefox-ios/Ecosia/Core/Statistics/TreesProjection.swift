// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public final class TreesProjection: Publisher {
    public static let shared = TreesProjection()
    public var subscriptions = [Subscription<Int>]()
    let timer = DispatchSource.makeTimerSource(queue: .main)

    init() {
        timer.activate()
        timer.setEventHandler { [weak self] in
            guard let count = self?.treesAt(Date()) else { return }
            self?.send(count)
        }
        timer.schedule(deadline: .now(), repeating: Statistics.shared.timePerTree)
    }

    public func treesAt(_ date: Date) -> Int {
        let statistics = Statistics.shared
        let timeSinceLastUpdate = date.timeIntervalSince(statistics.treesPlantedLastUpdated)
        return .init(timeSinceLastUpdate / statistics.timePerTree + statistics.treesPlanted - 1)
    }
}
