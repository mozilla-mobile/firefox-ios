// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class WhatsNewViewModel {
    var items: [WhatsNewItem]
    
    init(provider: WhatsNewDataProvider) {
        let providerItems = try? provider.getWhatsNewItemsInRange()
        self.items = providerItems ?? []
    }
}
