// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

extension UIColor {
    struct CredentialProvider {
        static var titleColor: UIColor {
            return UIColor(named: "labelColor") ?? UIColor.Photon.DarkGrey90
        }

        static var cellBackgroundColor: UIColor {
            return UIColor(named: "credentialCellColor") ?? UIColor.Photon.White100
        }

        static var tableViewBackgroundColor: UIColor = .systemGroupedBackground

        static var welcomeScreenBackgroundColor: UIColor {
            return UIColor(named: "launchScreenBackgroundColor") ?? UIColor.Photon.White100
        }
    }
}
