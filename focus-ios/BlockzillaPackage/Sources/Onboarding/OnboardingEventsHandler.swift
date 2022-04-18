/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Combine

public class OnboardingEventsHandler {

    private let alwaysShowOnboarding: () -> Bool
    private let setShownTips: (Set<ToolTipRoute>) -> Void
    public let shouldShowNewOnboarding: () -> Bool

    public enum Action {
        case applicationDidLaunch
        case enterHome
        case startBrowsing
        case showTrackingProtection
    }

    public enum OnboardingType: Equatable, Hashable, Codable {
        init(_ shouldShowNewOnboarding: Bool) {
            self = shouldShowNewOnboarding ? .new : .old
        }
        case new
        case old
    }

    public enum ToolTipRoute: Equatable, Hashable, Codable {
        case onboarding(OnboardingType)
        case trackingProtection
        case trackingProtectionShield
        case trash
        case menu
    }

    @Published public var route: ToolTipRoute?

    private var visitedURLcounter = 0
    private var shownTips = Set<ToolTipRoute>() {
        didSet {
            setShownTips(shownTips)
        }
    }

    public init(
        alwaysShowOnboarding: @escaping () -> Bool,
        shouldShowNewOnboarding: @escaping () -> Bool,
        visitedURLcounter: Int = 0,
        getShownTips: () -> Set<OnboardingEventsHandler.ToolTipRoute>,
        setShownTips: @escaping (Set<OnboardingEventsHandler.ToolTipRoute>) -> Void
    ) {
        self.alwaysShowOnboarding = alwaysShowOnboarding
        self.shouldShowNewOnboarding = shouldShowNewOnboarding
        self.visitedURLcounter = visitedURLcounter
        self.setShownTips = setShownTips
        self.shownTips = getShownTips()
    }

    public func send(_ action: OnboardingEventsHandler.Action) {
        switch action {
        case .applicationDidLaunch:
            let onboardingRoute = ToolTipRoute.onboarding(OnboardingType(shouldShowNewOnboarding()))
            if shownTips.contains(onboardingRoute) {
                show(route: .menu)
            } else {
                show(route: onboardingRoute)
            }

        case .enterHome:
            guard shouldShowNewOnboarding() else { return }
            show(route: .menu)

        case .startBrowsing:
            visitedURLcounter += 1
            guard shouldShowNewOnboarding() else { return }

            if visitedURLcounter == 1 {
                show(route: .trackingProtectionShield)
            }

            if visitedURLcounter == 3 {
                show(route: .trash)
            }

        case .showTrackingProtection:
            guard shouldShowNewOnboarding() else { return }
            show(route: .trackingProtection)
        }
    }

    private func show(route: ToolTipRoute) {
        #if DEBUG
        if alwaysShowOnboarding() {
            shownTips.remove(route)
        }
        #endif

        if !shownTips.contains(route) {
            self.route = route
            shownTips.insert(route)
        }
    }
}
