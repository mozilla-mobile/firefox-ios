/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import MessageUI

struct DebugSettingsBundleOptions {

    /// Don't restore tabs on app launch
    static var skipSessionRestore: Bool {
        return UserDefaults.standard.bool(forKey: "SettingsBundleSkipSessionRestore") ?? false
    }

    /// Disable the local web server we use for restoration, error pages, etc
    static var disableLocalWebServer: Bool {
        return UserDefaults.standard.bool(forKey: "SettingsBundleDisableLocalWebServer") ?? false
    }

    /// When enabled, the app launch will be replaced with the mail compose view appearing with the device
    /// logs pre-attached. When the mail is sent, the app continues launching normally.
    static var launchIntoEmailComposer: Bool {
        return ((attachTabStateToDebugEmail || attachLogsToDebugEmail) &&  MFMailComposeViewController.canSendMail()) ?? false
    }

    /// When enabled, the email composer will have the tab state attached.
    static var attachTabStateToDebugEmail: Bool {
        return UserDefaults.standard.bool(forKey: "SettingsBundleEmailTabState") ?? false
    }

    /// When enabled, the email composer will have the application logs attached.
    static var attachLogsToDebugEmail: Bool {
        return UserDefaults.standard.bool(forKey: "SettingsBundleEmailLogsOnLaunch") ?? false
    }
}
