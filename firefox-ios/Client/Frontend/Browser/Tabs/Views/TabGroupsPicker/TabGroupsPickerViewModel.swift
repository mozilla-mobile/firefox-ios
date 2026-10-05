// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct TabGroupsPickerViewModel: Equatable {
    struct Colors: Equatable {
        let background: Color
        let cardBackground: Color
        let primaryText: Color
        let accent: Color
        let onEmphasis: Color

        static let system = Colors(background: Color(uiColor: .systemGroupedBackground),
                                   cardBackground: Color(uiColor: .secondarySystemGroupedBackground),
                                   primaryText: Color(uiColor: .label),
                                   accent: .accentColor,
                                   onEmphasis: Color(uiColor: .systemBackground))
    }

    struct Destination: Equatable, Identifiable {
        enum Kind: Equatable {
            case device
            case group
            case privateTabs
        }

        let id: String
        let title: String
        let kind: Kind
        var icon: TabGroupIcon?
        var color: Color?
    }

    let title: String
    let colors: Colors
    let doneAccessibilityLabel: String
    let destinations: [Destination]
    let privateDestination: Destination
    let selectedDestinationID: String
    let createEmptyGroupTitle: String
    let createWithSelectedTabsTitle: String?
}

enum TabGroupsPickerAction: Equatable {
    case done
    case selectDestination(id: String)
    case deleteGroup(id: String)
    case moveGroup(fromOffsets: IndexSet, toOffset: Int)
    case createEmptyGroup
    case createWithSelectedTabs
}
