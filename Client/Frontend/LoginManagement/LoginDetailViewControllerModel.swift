// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

enum InfoItem: Int {
    case breachItem = 0
    case websiteItem
    case usernameItem
    case passwordItem
    case lastModifiedSeparator
    case deleteItem

    var indexPath: IndexPath {
        return IndexPath(row: rawValue, section: 0)
    }

    var shouldShowMenu: Bool {
        switch self {
        case .breachItem, .lastModifiedSeparator, .deleteItem:
            return false
        case .passwordItem, .usernameItem, .websiteItem:
            return true
        }
    }
}

struct LoginDetailViewControllerModel {
    let profile: Profile
    var login: LoginRecord
    let webpageNavigationHandler: ((_ url: URL?) -> Void)?
    let breachRecord: BreachRecord?

    private var cellTypes: [InfoItem] {
        if let breachRecord = breachRecord {
            return [.websiteItem, .usernameItem, .passwordItem, .lastModifiedSeparator, .deleteItem]
        } else {
            return [.breachItem, .websiteItem, .usernameItem, .passwordItem, .lastModifiedSeparator, .deleteItem]
        }
    }

    var numberOfRows: Int {
        cellTypes.count
    }

    func cellType(atIndexPath indexPath: IndexPath) -> InfoItem? {
        cellTypes[indexPath.row]
    }
}
