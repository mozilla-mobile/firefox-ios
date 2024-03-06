// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum ToolTipRoute: Equatable, Hashable, Codable {
    case onboarding(OnboardingVersion)
    case trackingProtection
    case trackingProtectionShield(OnboardingVersion)
    case trash(OnboardingVersion)
    case searchBar
    case widget
    case widgetTutorial
    case menu
}
