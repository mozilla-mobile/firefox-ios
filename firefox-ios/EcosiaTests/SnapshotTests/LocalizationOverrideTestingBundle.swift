// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import ObjectiveC.runtime
import Ecosia

var overriddenLocaleIdentifier: String = ""

final class LocalizationOverrideTestingBundle: Bundle {

    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        // You can dynamically choose the table based on a stored locale or use a predetermined table
        guard let path = Bundle.ecosia.path(forResource: overriddenLocaleIdentifier, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}
