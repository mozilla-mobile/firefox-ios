// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class ExperimentsSettings: HiddenSetting {
    override var title: NSAttributedString? { return NSAttributedString(string: "Experiments")}

    override func onClick(_ navigationController: UINavigationController?) {
        navigationController?.pushViewController(ExperimentsViewController(), animated: true)
    }
}
