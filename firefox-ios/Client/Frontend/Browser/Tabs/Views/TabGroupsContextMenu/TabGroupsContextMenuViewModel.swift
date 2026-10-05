// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

struct TabGroupsContextMenuViewModel: Equatable {
    let showsGroupActions: Bool
    let selectTabsTitle: String
    let arrangeTabsTitle: String
    let customizeGroupTitle: String
    let closeTabsTitle: String
    let ungroupTitle: String
    let tabSettingsTitle: String
    let originalOrderTitle: String
    let titleOrderTitle: String
    let moreAccessibilityLabel: String
    var colors: TabGroupsTrayBarViewModel.Colors = .system
    var sortsByTitle = false
}

enum TabGroupsContextMenuAction: Equatable {
    case selectTabs
    case arrangeTabsByOriginalOrder
    case arrangeTabsByTitle
    case customizeGroup
    case closeTabs
    case ungroup
    case tabSettings
}
