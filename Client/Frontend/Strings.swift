/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public struct Strings {
    public static let bundle = Bundle(for: BundleClass.self)
}

class BundleClass {}

enum AppVersion {
    case v39
    case unknown
}

func MZLocalizedString(_ key: String, tableName: String? = nil, value: String = "", comment: String, lastUpdated: AppVersion) -> String {
    return NSLocalizedString(key, tableName: tableName, bundle: Strings.bundle, value: value, comment: comment)
}
