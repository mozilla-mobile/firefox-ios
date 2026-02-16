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
}
