// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension UILabel {
    func getHeight(with width: CGFloat) -> CGFloat {
        return self.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
    }
}
