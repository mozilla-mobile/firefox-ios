// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct TabTrayModel: Equatable {
    var isPrivateMode: Bool
    var selectedPanel: TabTrayPanelType
    var normalTabsCount: String
    var privateTabsCount: String
    var hasSyncableAccount: Bool
    var enableDeleteTabsButton: Bool
}
