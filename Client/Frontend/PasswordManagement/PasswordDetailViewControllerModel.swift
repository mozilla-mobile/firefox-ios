// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

enum LoginDetailCellType: Int {
    case breach = 0
    case website
    case username
    case password
    case lastModifiedSeparator
    case delete

    var shouldShowMenu: Bool {
        switch self {
        case .breach, .lastModifiedSeparator, .delete:
            return false
        case .password, .username, .website:
            return true
        }
    }
}

struct PasswordDetailViewControllerModel {
    let profile: Profile
    var login: LoginRecord
    let webpageNavigationHandler: ((_ url: URL?) -> Void)?
    let breachRecord: BreachRecord?

    private var cellTypes: [LoginDetailCellType] {
        if breachRecord != nil {
            return [.breach, .website, .username, .password, .lastModifiedSeparator, .delete]
        } else {
            return [.website, .username, .password, .lastModifiedSeparator, .delete]
        }
    }

    var numberOfRows: Int {
        cellTypes.count
    }

    func cellType(atIndexPath indexPath: IndexPath) -> LoginDetailCellType? {
        cellTypes[indexPath.row]
    }

    func indexPath(for cellType: LoginDetailCellType) -> IndexPath? {
        guard let index = cellTypes.firstIndex(of: cellType) else { return nil }
        return IndexPath(row: index, section: 0)
    }
}
