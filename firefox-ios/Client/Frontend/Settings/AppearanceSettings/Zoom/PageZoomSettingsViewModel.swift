// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Storage

class PageZoomSettingsViewModel: ObservableObject {
    let zoomManager: ZoomPageManager
    private let zoomTelemetry = ZoomTelemetry()
    @Published var domainZoomLevels: [DomainZoomLevel]
    public var notificationCenter: NotificationProtocol

    init(zoomManager: ZoomPageManager,
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.zoomManager = zoomManager
        self.domainZoomLevels = zoomManager.getDomainLevel()
        self.notificationCenter = notificationCenter
    }

    func updateDefaultZoomLevel(newValue: ZoomLevel) {
        zoomManager.saveDefaultZoomLevel(defaultZoom: newValue.rawValue)
        notificationCenter.post(name: .PageZoomSettingsChanged)
        zoomTelemetry.updateDefaultZoomLevel(zoomLevel: newValue)
    }

    func resetDomainZoomLevel() {
        domainZoomLevels.removeAll()
        zoomManager.resetDomainZoomLevel()
        notificationCenter.post(name: .PageZoomSettingsChanged)
        zoomTelemetry.resetDomainZoomLevel()
    }

    func deleteZoomLevel(at indexSet: IndexSet) {
        guard let index = indexSet.first else { return }

        let deleteItem = domainZoomLevels[index]
        zoomManager.deleteZoomLevel(for: deleteItem.host)
        domainZoomLevels.remove(at: index)
        notificationCenter.post(name: .PageZoomSettingsChanged)
        zoomTelemetry.deleteZoomDomainLevel(value: Int32(index))
    }
}
