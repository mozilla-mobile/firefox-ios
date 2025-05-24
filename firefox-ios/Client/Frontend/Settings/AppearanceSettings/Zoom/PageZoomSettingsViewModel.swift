// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage

class PageZoomSettingsViewModel: ObservableObject {
    let zoomManager: ZoomPageManager
    @Published var domainZoomLevels: [DomainZoomLevel]

    init(zoomManager: ZoomPageManager) {
        self.zoomManager = zoomManager
        self.domainZoomLevels = zoomManager.getDomainLevel()
    }

    func resetDomainZoomLevel() {
        domainZoomLevels.removeAll()
        zoomManager.resetDomainZoomLevel()
    }

    func deleteZoomLevel(at indexSet: IndexSet) {
        guard let index = indexSet.first else { return }

        let deleteItem = domainZoomLevels[index]
        zoomManager.deleteZoomLevel(for: deleteItem.host)
        domainZoomLevels.remove(at: index)
    }
}
