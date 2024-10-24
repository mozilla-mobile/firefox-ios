// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

public protocol ConfigurableTableViewCell: UITableViewCell {
    associatedtype E: ElementData

    func configureCellWith(model: E)
    func applyTheme(theme: Theme)
}
