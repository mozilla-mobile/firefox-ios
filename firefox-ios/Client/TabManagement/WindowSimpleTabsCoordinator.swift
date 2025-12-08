// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WidgetKit
import Common

@MainActor
protocol WindowSimpleTabsProvider {
    func windowSimpleTabs() -> [String: SimpleTab]
}

final class WindowSimpleTabsCoordinator {
    private struct Timing {
        static let throttleDelay = 1.0
    }
    private let throttler = MainThreadThrottler(seconds: Timing.throttleDelay)

    @MainActor
    func saveSimpleTabs(for providers: [WindowSimpleTabsProvider]) {
        throttler.throttle {
            let allTabs = providers.reduce([:], { $0.merge(with: $1.windowSimpleTabs()) })
            SimpleTab.saveSimpleTab(tabs: allTabs)
        }
    }
}
