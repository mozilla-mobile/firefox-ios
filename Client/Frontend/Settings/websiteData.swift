/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

let dataStore = WKWebsiteDataStore.default()
let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()

struct siteData {
    let dataOfSite: WKWebsiteDataRecord
    let nameOfSite: String

    init(dataOfSite: WKWebsiteDataRecord, nameOfSite: String) {
        self.dataOfSite = dataOfSite
        self.nameOfSite = nameOfSite
    }
}
