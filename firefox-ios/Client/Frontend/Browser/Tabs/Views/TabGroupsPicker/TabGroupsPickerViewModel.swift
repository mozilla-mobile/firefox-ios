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
        var emoji: String?
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

struct TabGroupColorComponents {
    let red: Double
    let green: Double
    let blue: Double
}

extension TabGroupColor {
    var components: TabGroupColorComponents {
        switch self {
        case .red: TabGroupColorComponents(red: 0.88, green: 0.28, blue: 0.28)
        case .orange: TabGroupColorComponents(red: 0.96, green: 0.38, blue: 0.16)
        case .yellow: TabGroupColorComponents(red: 0.75, green: 0.53, blue: 0.08)
        case .green: TabGroupColorComponents(red: 0.20, green: 0.62, blue: 0.32)
        case .teal: TabGroupColorComponents(red: 0.13, green: 0.62, blue: 0.62)
        case .blue: TabGroupColorComponents(red: 0.20, green: 0.44, blue: 0.90)
        case .purple: TabGroupColorComponents(red: 0.54, green: 0.37, blue: 0.84)
        case .pink: TabGroupColorComponents(red: 0.84, green: 0.32, blue: 0.59)
        }
    }
}
