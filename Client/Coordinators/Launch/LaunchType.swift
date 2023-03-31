// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared

enum LaunchType {
    // Showing the intro onboarding
    case intro

    // Show the update onboarding
    case update

    // Show the surface survey
    case survey

    // Show the default browser onboarding, only shown from deeplink
    case defaultBrowser
}
