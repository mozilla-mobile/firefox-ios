// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Enum representing the different onboarding variants available.
/// This mirrors the Nimbus OnboardingVariant configuration.
public enum OnboardingVariant: String, Sendable {
    /// rawValue stays "modern" to match the Nimbus `uiVariant` / Glean `onboarding_variant`
    /// wire values; only the Swift identifier was renamed (FXIOS-16008).
    case base = "modern"
    case japan
    case brandRefresh

    /// Whether the UI for the Onboarding should be according to the brand refresh.
    var shouldShowBrandRefreshUI: Bool {
        switch self {
        case .base:
            return false
        case .brandRefresh, .japan:
            return true
        }
    }
}
