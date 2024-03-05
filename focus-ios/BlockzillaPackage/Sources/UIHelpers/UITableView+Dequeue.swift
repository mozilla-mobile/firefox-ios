/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

public extension UITableView {
    func dequeueReusableCell<Cell: UITableViewCell>(_ type: Cell.Type, withIdentifier identifier: String) -> Cell? {
        return self.dequeueReusableCell(withIdentifier: identifier) as? Cell
    }

    func dequeueReusableCell<Cell: UITableViewCell>(_ type: Cell.Type, for indexPath: IndexPath) -> Cell? {
        return self.dequeueReusableCell(withIdentifier: String(describing: type), for: indexPath) as? Cell
    }

    func register<Cell: UITableViewCell>(_ type: Cell.Type) {
        register(type, forCellReuseIdentifier: String(describing: type))
    }
}
