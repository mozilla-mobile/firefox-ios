/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

extension UINavigationController {
    
    func iosThirteenNavBarAppearance() {
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            //navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            //navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
          //  navBarAppearance.backgroundColor = UIColor.navBackgroundColor
            navigationBar.standardAppearance = navBarAppearance
            navigationBar.scrollEdgeAppearance = navBarAppearance
        }
    }
    
}
