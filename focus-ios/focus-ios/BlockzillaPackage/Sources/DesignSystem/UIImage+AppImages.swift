/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

// MARK: - Tracking protection images

public extension UIImage {
    convenience init?(named name: String) {
        self.init(named: name, in: Bundle.myModule, compatibleWith: nil)
    }
}

public extension UIImage {
    // MARK: Tracking Protection
    static let trackingProtectionOff = UIImage(named: "tracking_protection_off")!
    static let trackingProtectionOn = UIImage(named: "tracking_protection")!
    static let connectionNotSecure = UIImage(named: "connection_not_secure")!
    static let connectionSecure = UIImage(named: "icon_https")!

    // MARK: Tracking Protection Drawer
    static let defaultFavicon = UIImage(named: "icon_favicon")!
    static let iconClose = UIImage(named: "icon_close")!

    // MARK: Website Shortcuts
    static let removeShortcut = UIImage(named: "icon_shortcuts_remove")!
    static let renameShortcut = UIImage(named: "edit")!

    // MARK: Biometric Auth
    static let faceid = UIImage(named: "faceid")!
    static let touchid = UIImage(named: "touchid")!

    // MARK: Onboarding
    static let mozilla = UIImage(named: "icon_mozilla")!
    static let privateMode = UIImage(named: "icon_private_mode")!
    static let history = UIImage(named: "icon_history")!
    static let settings = UIImage(named: "icon_settings")!

    // MARK: URLBar
    static let clear = UIImage(named: "icon_clear")!
    static let cancel = UIImage(named: "icon_cancel")!
    static let backActive = UIImage(named: "icon_back_active")!
    static let forwardActive = UIImage(named: "icon_forward_active")!
    static let refreshMenu = UIImage(named: "icon_refresh_menu")!
    static let delete = UIImage(named: "icon_delete")!
    static let hamburgerMenu = UIImage(named: "icon_hamburger_menu")!
    static let stopMenu = UIImage(named: "icon_stop_menu")!
}
