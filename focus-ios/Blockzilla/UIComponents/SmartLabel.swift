/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import UIHelpers

final class SmartLabel: UILabel {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupShrinkage()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupShrinkage()
    }
}
