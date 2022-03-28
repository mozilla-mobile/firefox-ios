// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

/// This file contains enums that serve as options for flaggable features.
/// Each should be set as an enum and should conform to String type and
/// the FlaggableFeatureOptions protocol.
protocol FlaggableFeatureOptions { }

enum UserFeaturePreference: String, FlaggableFeatureOptions {
    case enabled
    case disabled
}

enum StartAtHomeSetting: String, FlaggableFeatureOptions {
    case afterFourHours
    case always
    case disabled
}
