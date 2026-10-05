// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum TabGroupColor: String, Codable, CaseIterable, Sendable {
    case red, orange, yellow, green, teal, blue, purple, pink
}

struct TabGroup: Codable, Equatable, Identifiable, Sendable {
    let id: TabGroupID
    var title: String
    var color: TabGroupColor
    var emoji: String?
    var tabIDs: [TabUUID]

    init(id: TabGroupID = UUID(), title: String, color: TabGroupColor = .blue, tabIDs: [TabUUID] = []) {
        self.id = id
        self.title = title
        self.color = color
        self.tabIDs = tabIDs
    }
}
