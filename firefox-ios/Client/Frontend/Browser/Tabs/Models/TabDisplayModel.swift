// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct TabGroupDisplayModel: Equatable {
    let id: TabGroupID
    let name: String
    let color: TabGroupColor
    let isSelected: Bool
}

struct TabDisplayModel: Equatable {
    var isPrivateMode: Bool
    var tabs: [TabModel]
    var selectedGroupName: String? = nil
    var tabGroups: [TabGroupDisplayModel] = []
    var normalTabsCount: String
    var privateTabsCount: String
    var undoCloseType: ToastType?
    var enableDeleteTabsButton: Bool
}
