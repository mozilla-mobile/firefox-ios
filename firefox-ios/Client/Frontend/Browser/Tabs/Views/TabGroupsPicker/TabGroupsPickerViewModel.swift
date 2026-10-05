// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct TabGroupsPickerViewModel: Equatable {
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

    let accentColor: Color
    let destinations: [Destination]
    let selectedDestinationID: String

    var switcherDestinations: [Destination] {
        destinations.filter { $0.kind != .privateTabs }
    }
}

enum TabGroupsPickerAction: Equatable {
    case selectDestination(id: String)
    case createEmptyGroup
}
