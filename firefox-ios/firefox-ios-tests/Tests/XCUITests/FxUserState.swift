// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MappaMundi

@objcMembers
class FxUserState: MMUserState {
    required init() {
        super.init()
        initialScreenState = FirstRun
    }
    var currentScreen: String = FirstRun

    var isPrivate = false
    var showIntro = false
    var showWhatsNew = false
    var waitForLoading = true
    var url: String?
    var requestDesktopSite = false

    var noImageMode = false
    var nightMode = false

    var pocketInNewTab = false
    var bookmarksInNewTab = true
    var historyInNewTab = true

    var fxaUsername: String?
    var fxaPassword: String?

    var numTabs = 0
    var numTopSitesRows = 2

    var trackingProtectionPerTabEnabled = true
    var trackingProtectionSettingOnNormalMode = true
    var trackingProtectionSettingOnPrivateMode = true

    var localeIsExpectedDifferent = false
}
