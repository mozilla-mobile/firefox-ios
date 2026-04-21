// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Enum representing the different onboarding variants available.
/// This mirrors the Nimbus OnboardingVariant configuration.
public enum OnboardingVariant: String, Sendable {
    case legacy
    case modern
    case japan
    case brandRefresh

    /// Whether the UI for the Onboarding should be according to the brand refresh.
    var shouldShowBrandRefreshUI: Bool {
        switch self {
        case .legacy, .modern:
            return false
        case .brandRefresh, .japan:
            return true
        }
    }
}
