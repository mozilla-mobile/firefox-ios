// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage

struct ContextMenuConfiguration: Equatable {
    var site: Site?
    var menuType: MenuType?
    var sourceView: UIView?
    var toastContainer: UIView

    init(
        site: Site?,
        menuType: MenuType?,
        sourceView: UIView? = nil,
        toastContainer: UIView
    ) {
        self.site = site
        self.menuType = menuType
        self.sourceView = sourceView
        self.toastContainer = toastContainer
    }
}

enum MenuType {
    case topSite
    case jumpBackIn
    case jumpBackInSyncedTab
    case bookmark
    case merino
    case shortcut
}

extension MenuType {
    init?(homepageItem: HomepageItem) {
        switch homepageItem {
        case .topSite: self = .topSite
        case .jumpBackIn: self = .jumpBackIn
        case .jumpBackInSyncedTab: self = .jumpBackInSyncedTab
        case .bookmark: self = .bookmark
        case .merino: self = .merino
        default: return nil
        }
    }
}
