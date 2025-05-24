// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage

final class MockZoomStore: ZoomLevelStorage {
    var savedDefaultZoom: CGFloat = 1.0
    var store = [DomainZoomLevel]()
    var saveCalledCount = 0
    var findZoomLevelCalledCount = 0

    func findZoomLevel(forDomain host: String) -> DomainZoomLevel? {
        findZoomLevelCalledCount += 1
        return store.first { $0.host == host }
    }

    func saveDefaultZoomLevel(defaultZoom: CGFloat) {
        saveCalledCount += 1
        savedDefaultZoom = defaultZoom
    }

    func saveDomainZoom(_ domainZoomLevel: Storage.DomainZoomLevel, completion: (() -> Void)?) {
        saveCalledCount += 1
        store.append(domainZoomLevel)
    }

    func getDefaultZoom() -> CGFloat {
        return savedDefaultZoom
    }

    func getDomainZoomLevel() -> [Storage.DomainZoomLevel] {
        return [DomainZoomLevel]()
    }

    func deleteZoomLevel(for host: String) {
        guard let index = store.firstIndex(where: { return $0.host == host }) else { return }

        store.remove(at: index)
        saveCalledCount += 1
    }

    func resetDomainZoomLevel() {
        store.removeAll()
    }
}
