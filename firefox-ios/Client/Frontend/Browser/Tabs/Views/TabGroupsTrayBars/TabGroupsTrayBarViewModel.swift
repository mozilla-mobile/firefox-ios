// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

enum TabGroupsTrayBarMetrics {
    static let topHeight: CGFloat = 48
    static let bottomHeight: CGFloat = 56
    static let buttonSize: CGFloat = 40
}

struct TabGroupsTrayBarViewModel: Equatable {
    struct Colors: Equatable {
        let primaryText: Color
        let selectedPanelBackground: Color
        let emphasis: Color
        let onEmphasis: Color

        static let system = Colors(primaryText: Color(uiColor: .label),
                                   selectedPanelBackground: Color(uiColor: .secondarySystemGroupedBackground),
                                   emphasis: Color(uiColor: .label),
                                   onEmphasis: Color(uiColor: .systemBackground))
    }

    enum Panel: Equatable {
        case privateTabs
        case tabs
        case syncedTabs
    }

    let destinationTitle: String
    let isGroupSelected: Bool
    let tabCount: Int
    let selectedPanel: Panel
    let privateTitle: String
    let syncedTitle: String
    let doneAccessibilityLabel: String
    let moreAccessibilityLabel: String
    let addTabAccessibilityLabel: String
    let tabCountTitle: String
    var colors: Colors = .system
    var groupEmoji: String?
    var groupColor: Color?

    var tabsTitle: String { tabCountTitle }
}

enum TabGroupsTrayBarAction: Equatable {
    case openDestinationPicker
    case openMoreMenu
    case addTab
    case selectPanel(TabGroupsTrayBarViewModel.Panel)
    case done
}
