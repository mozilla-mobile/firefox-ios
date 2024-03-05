// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum OnboardingVersion: Equatable, Hashable, Codable {
    init(_ shouldShowNewOnboarding: Bool) {
        self = shouldShowNewOnboarding ? .v2 : .v1
    }
    case v2
    case v1
}
