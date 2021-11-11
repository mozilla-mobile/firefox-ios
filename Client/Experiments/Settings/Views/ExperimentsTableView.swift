// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

class ExperimentsSubtitleTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ExperimentsTableView: UITableView {
    static let CellIdentifier = "ExperimentsBranchesView.cell"

    convenience init() {
        self.init(frame: .zero)
        register(ExperimentsSubtitleTableViewCell.self, forCellReuseIdentifier: Self.CellIdentifier)
    }
}
