/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Combine

public class OnboardingEventsHandlerV1: OnboardingEventsHandling {
    private let setShownTips: (Set<ToolTipRoute>) -> Void

    @Published public var route: ToolTipRoute?
    public var routePublisher: Published<ToolTipRoute?>.Publisher { $route }

    private var visitedURLcounter = 0
    private var shownTips = Set<ToolTipRoute>() {
        didSet {
            setShownTips(shownTips)
        }
    }

    public init(
        visitedURLcounter: Int = 0,
        getShownTips: () -> Set<ToolTipRoute>,
        setShownTips: @escaping (Set<ToolTipRoute>) -> Void
    ) {
        self.visitedURLcounter = visitedURLcounter
        self.setShownTips = setShownTips
        self.shownTips = getShownTips()
    }

    public func send(_ action: Action) {
        switch action {
        case .applicationDidLaunch:
            show(route: .onboarding(.v1))

        case .enterHome:
            show(route: .menu)

        case .startBrowsing:
            visitedURLcounter += 1

            if visitedURLcounter == 3 {
                show(route: .trash(.v1))
            }

        case .showTrackingProtection:
            show(route: .trackingProtection)

        case .trackerBlocked:
            show(route: .trackingProtectionShield(.v1))

        default:
            break
        }
    }

    private func show(route: ToolTipRoute) {
        if !shownTips.contains(route) {
            self.route = route
            shownTips.insert(route)
        }
    }
}
