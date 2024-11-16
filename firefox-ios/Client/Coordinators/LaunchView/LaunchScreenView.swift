// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// LaunchScreen is the LaunchScreen.xib we show at launch, but loaded programmatically
class LaunchScreenView: UIView {
    private static let viewName = "LaunchScreen"

    class func fromNib() -> UIView? {
        guard let view = Bundle.main.loadNibNamed(
            LaunchScreenView.viewName,
            owner: nil,
            options: nil
        )?[0] as? UIView else {
            return nil
        }
        return view
    }
}
