// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Used to determine the sign in flow, used mostly with deeplinks
struct FxASignInViewParameters: Equatable {
    var launchParameters: FxALaunchParams
    var flowType: FxAPageType
    var referringPage: ReferringPage
}
