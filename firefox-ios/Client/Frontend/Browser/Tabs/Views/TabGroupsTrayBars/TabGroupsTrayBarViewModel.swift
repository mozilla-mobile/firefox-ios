// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI

enum TabGroupsTrayBarMetrics {
    static let topHeight: CGFloat = 48
    static let bottomHeight: CGFloat = 56
    static let buttonSize: CGFloat = 44
    static let glassButtonSize: CGFloat = 48
    static let bottomBarSpacing: CGFloat = 12
    static let bottomBarInset: CGFloat = 16
    static let contentSpacing: CGFloat = 8
}

struct TabGroupsTrayBarViewModel: Equatable {
    struct Colors: Equatable {
        let primaryText: Color
        let selectedPanelBackground: Color
        let emphasis: Color
        let onEmphasis: Color
        let destructive: Color
        var glassTint = Color(uiColor: .tertiarySystemFill)
        var plainDoneTint: Color?

        static let system = Colors(primaryText: Color(uiColor: .label),
                                   selectedPanelBackground: Color(uiColor: .secondarySystemGroupedBackground),
                                   emphasis: Color(uiColor: .label),
                                   onEmphasis: Color(uiColor: .systemBackground),
                                   destructive: Color(uiColor: .systemRed))

        static func themed(_ theme: Theme, isDefaultGroup: Bool = false) -> Self {
            let palette = theme.colors
            let selectedPanelBackground: UIColor
            if #available(iOS 26.0, *), theme.isNova {
                selectedPanelBackground = palette.layerGlassSelectedFill
            } else {
                selectedPanelBackground = palette.layer2
            }
            return Self(primaryText: Color(palette.textPrimary),
                        selectedPanelBackground: Color(selectedPanelBackground),
                        emphasis: Color(palette.actionPrimary),
                        onEmphasis: Color(isDefaultGroup ? palette.iconPrimary : palette.iconOnColor),
                        destructive: Color(palette.textCritical),
                        glassTint: Color(theme.isNova ? palette.layerTabGroupGlassTint : palette.layer2),
                        plainDoneTint: isDefaultGroup ? Color(palette.iconPrimary) : nil)
        }
    }

    enum Panel: Equatable {
        case privateTabs
        case tabs
        case syncedTabs
    }

    let destinationTitle: String
    let isGroupSelected: Bool
    let selectedPanel: Panel
    let privateTitle: String
    let syncedTitle: String
    let doneAccessibilityLabel: String
    let moreAccessibilityLabel: String
    let addTabAccessibilityLabel: String
    let tabCountTitle: String
    let selectionTitle: String
    let finishSelectionAccessibilityLabel: String
    let newGroupTitle: String
    let moveToGroupTitle: String
    let closeSelectedTabsTitle: String
    var colors: Colors = .system
    var groupIcon: TabGroupIcon?
    var groupColor: Color?
    var selectedTabCount: Int?

    var tabsTitle: String { String.TabsTray.TabsSelectorNormalTabsTitle }
    var hasSelectedTabs: Bool { (selectedTabCount ?? 0) > 0 }
    var selectionToggleTitle: String {
        hasSelectedTabs ? String.TabGroups.DeselectAll : String.TabGroups.SelectAll
    }
    var selectionReviewTitle: String {
        guard let selectedTabCount, selectedTabCount > 0 else { return String.TabGroups.SelectTabsPrompt }
        return String(format: String.TabGroups.ShowSelections, selectedTabCount.formatted())
    }
    var activeTint: Color { isGroupSelected ? groupColor ?? colors.emphasis : colors.emphasis }
}

enum TabGroupsTrayBarAction: Equatable {
    case openDestinationPicker
    case openMoreMenu
    case addTab
    case finishSelection
    case toggleSelectAll
    case showSelections
    case createGroupFromSelection
    case moveSelectionToGroup
    case closeSelectedTabs
    case selectPanel(TabGroupsTrayBarViewModel.Panel)
    case done
}
