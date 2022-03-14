/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit


//MARK: - Tracking protection images

extension UIImage {
    static let trackingProtectionOff = UIImage(named: "tracking_protection_off")!
    static let trackingProtectionOn = UIImage(named: "tracking_protection")!
    static let connectionNotSecure = UIImage(named: "connection_not_secure")!
    static let connectionSecure = UIImage(named: "icon_https")!
    
    static let defaultFavicon = UIImage(named: "icon_favicon")!
    
    static let iconClose = UIImage(named: "icon_close")!
    
    static let removeShortcut = UIImage(named: "icon_shortcuts_remove")!
    static let renameShortcut = UIImage(named: "edit")!
}
