// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage

final class MockZoomStore: ZoomLevelStorage {
    var store = [DomainZoomLevel]()
    var saveCalledCount = 0
    var findZoomLevelCalledCount = 0

    func save(_ domainZoomLevel: DomainZoomLevel, completion: (() -> Void)?) {
        saveCalledCount += 1
        store.append(domainZoomLevel)
    }

    func findZoomLevel(forDomain host: String) -> DomainZoomLevel? {
        findZoomLevelCalledCount += 1
        return store.first { $0.host == host }
    }

    func loadAll() -> [DomainZoomLevel] {
        return [DomainZoomLevel]()
    }
}
