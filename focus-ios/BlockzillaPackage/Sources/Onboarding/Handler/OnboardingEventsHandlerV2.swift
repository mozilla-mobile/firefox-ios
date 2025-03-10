// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Combine

enum TooltipTracking {
    case showOnce      // Original behavior - show once and never again
    case showUntilDismissed  // New behavior - show until explicitly dismissed
}

public class OnboardingEventsHandlerV2: OnboardingEventsHandling {
    private let setShownTips: (Set<ToolTipRoute>) -> Void

    @Published public var route: ToolTipRoute?
    public var routePublisher: Published<ToolTipRoute?>.Publisher { $route }

    private var shownTips = Set<ToolTipRoute>() {
        didSet {
            setShownTips(shownTips)
        }
    }
    
    private var tooltipTrackingTypes: [ToolTipRoute: TooltipTracking] = [
        .onboarding(.v1): .showOnce,
        .onboarding(.v2): .showUntilDismissed,
        .trackingProtection: .showOnce,
        .trackingProtectionShield(.v1): .showOnce,
        .trackingProtectionShield(.v2): .showOnce,
        .trash(.v1): .showOnce,
        .trash(.v2): .showOnce,
        .searchBar: .showOnce,
        .widget: .showOnce,
        .widgetTutorial: .showOnce,
        .menu: .showOnce
    ]

    public init(
        getShownTips: () -> Set<ToolTipRoute>,
        setShownTips: @escaping (Set<ToolTipRoute>) -> Void
    ) {
        self.setShownTips = setShownTips
        self.shownTips = getShownTips()
    }

    public func send(_ action: Action) {
        switch action {
        case .applicationDidLaunch:
            show(route: .onboarding(.v2))

        case .enterHome:
            show(route: .searchBar)

        case .showTrackingProtection:
            show(route: .trackingProtection)

        case .trackerBlocked:
            show(route: .trackingProtectionShield(.v2))

        case .showTrash:
            show(route: .trash(.v2))

        case .clearTapped:
            show(route: .widget)

        case .startBrowsing:
            break

        case .widgetDismissed:
            show(route: .widgetTutorial)
        }
    }

    private func show(route: ToolTipRoute) {
        let trackingType = tooltipTrackingTypes[route] ?? .showOnce
        
        switch trackingType {
        case .showOnce:
            if !shownTips.contains(route) {
                self.route = route
                shownTips.insert(route)
            }
        case .showUntilDismissed:
            // New behavior - only check if in set, don't insert until dismissed
            if !shownTips.contains(route) {
                self.route = route
            }
        }
    }

    public func dismissTooltip(route: ToolTipRoute) {
        shownTips.insert(route)
        
        if self.route == route {
            self.route = nil
        }
    }
}
