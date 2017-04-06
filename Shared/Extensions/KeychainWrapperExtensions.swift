/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SwiftKeychainWrapper

let appGroupSuffix = AppInfo.appGroupSuffix()
let accessGroupPrefix = Bundle.main.object(forInfoDictionaryKey: "MozDevelopmentTeam") as! String
let accessGroupIdentifier = AppInfo.keychainAccessGroupWithPrefix(accessGroupPrefix)
private var sharedAppKeychainWrapper = KeychainWrapper(serviceName: appGroupSuffix, accessGroup: accessGroupIdentifier)

public extension KeychainWrapper {
    static var sharedAppContainerKeychain: KeychainWrapper {
        return sharedAppKeychainWrapper
    }
}
