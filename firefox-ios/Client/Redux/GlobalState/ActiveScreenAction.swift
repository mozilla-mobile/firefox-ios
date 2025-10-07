// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

struct ScreenAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let screen: AppScreen
}

enum AppScreen {
    case browserViewController
    case onboardingViewController
    case homepage
    case themeSettings
    case tabsTray
    case tabsPanel
    case remoteTabsPanel
    case tabPeek
    case mainMenu
    case microsurvey
    case termsOfUse
    case trackingProtection
    case toolbar
    case searchEngineSelection
    case passwordGenerator
    case nativeErrorPage
    case shortcutsLibrary
    case storiesFeed
}

enum ScreenActionType: ActionType {
    case showScreen
    case closeScreen
}
