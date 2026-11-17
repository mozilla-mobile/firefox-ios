// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux

enum VPNModernAction: ModernAction {
    case start
    case stop
    case changeLocation
    // User choices from the VPN alerts. Each one turns the VPN off.
    case continueWithoutVPN
    case closeThisTab
    case closeAllTabs
}

/// Shows a VPN alert in the window the action is dispatched for.
enum VPNAlertModernAction: ModernAction {
    case showFailureAlert
    case showDataLimitAlert(dataLimitBytes: Int64)
}
