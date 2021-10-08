/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

struct Section {
    let headerTitle: String?
    let footerTitle: String?
    let items: [SectionItem]
    
    init(headerTitle: String? = nil, footerTitle: String? = nil, items: [SectionItem]) {
        self.headerTitle = headerTitle
        self.footerTitle = footerTitle
        self.items = items
    }
}
