/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import MessageUI

struct DebugSettingsBundleOptions {

    /// Don't restore tabs on app launch
    static var skipSessionRestore: Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey("SettingsBundleSkipSessionRestore") ?? false
    }

    /// Disable the local web server we use for restoration, error pages, etc
    static var disableLocalWebServer: Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey("SettingsBundleDisableLocalWebServer") ?? false
    }

    /// When enabled, the app launch will be replaced with the mail compose view appearing with the device
    /// logs pre-attached. When the mail is sent, the app continues launching normally.
    static var emailLogsOnLaunch: Bool {
        return (NSUserDefaults.standardUserDefaults().boolForKey("SettingsBundleEmailLogsOnLaunch") &&  MFMailComposeViewController.canSendMail()) ?? false
    }
}
