/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct DebugSettingsBundleOptions {

    /// Save logs to `~/Documents` folder
    static var saveLogsToDocuments: Bool {
        return UserDefaults.standard.bool(forKey: "SettingsBundleSaveLogsToDocuments")
    }

    /// Don't restore tabs on app launch
    static var skipSessionRestore: Bool {
        return UserDefaults.standard.bool(forKey: "SettingsBundleSkipSessionRestore")
    }
}
