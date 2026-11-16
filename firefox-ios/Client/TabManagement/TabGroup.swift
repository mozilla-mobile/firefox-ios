// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct TabGroup: Codable, Equatable, Identifiable, Sendable {
    let id: TabGroupID
    var title: String
    var color: CodableColor
    var icon: TabGroupIcon
    var tabIDs: [TabUUID]

    init(id: TabGroupID = UUID(),
         title: String,
         color: CodableColor = CodableColor(red: 0.20, green: 0.44, blue: 0.90),
         icon: TabGroupIcon = .sfSymbol("rectangle.portrait.on.rectangle.portrait.angled.fill"),
         tabIDs: [TabUUID] = []) {
        self.id = id
        self.title = title
        self.color = color
        self.icon = icon
        self.tabIDs = tabIDs
    }
}

enum TabGroupIcon: Codable, Equatable, Hashable, Sendable {
    case sfSymbol(String)
}
