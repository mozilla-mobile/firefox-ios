// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Storage

struct ZoomConstants {
    static let defaultZoomLimit: CGFloat = 1.0
    static let lowerZoomLimit: CGFloat = 0.5
    static let upperZoomLimit: CGFloat = 2.0
}

class ZoomPageManager: TabEventHandler {
    var tabEventWindowResponseType: TabEventHandlerWindowResponseType { return .singleWindow(windowUUID) }

    let windowUUID: WindowUUID
    let zoomStore: ZoomLevelStorage
    var tab: Tab?

    init(windowUUID: WindowUUID,
         zoomStore: ZoomLevelStorage = ZoomLevelStore.shared) {
        self.windowUUID = windowUUID
        self.zoomStore = zoomStore
        register(self, forTabEvents: .didGainFocus)
    }

    func getZoomLevel() -> CGFloat {
        guard let tab else { return ZoomConstants.defaultZoomLimit}

        return getZoomLevel(for: tab.url?.host)
    }

    func zoomIn() -> CGFloat {
        guard let tab = tab,
              let host = tab.url?.host,
              tab.pageZoom < ZoomConstants.upperZoomLimit else { return ZoomConstants.upperZoomLimit}

        let newZoom = getNewZoomInLevel(level: tab.pageZoom)
        tab.pageZoom = newZoom
        saveZoomLevel(for: host, zoomLevel: newZoom)
        return newZoom
    }

    // Regular step is 0.25 except for the cases close to regular zoom
    // where we provide smaller step
    private func getNewZoomInLevel(level: CGFloat) -> CGFloat {
        switch level {
        case 0.75:
            return 0.9
        case 0.9:
            return 1.0
        case 1.0:
            return 1.10
        case 1.10:
            return 1.25
        default:
            return level + 0.25
        }
    }

    func zoomOut() -> CGFloat {
        guard let tab = tab,
              let host = tab.url?.host,
              tab.pageZoom > ZoomConstants.lowerZoomLimit else { return ZoomConstants.lowerZoomLimit}

        let newZoom = getNewZoomOutLevel(level: tab.pageZoom)
        tab.pageZoom = newZoom
        saveZoomLevel(for: host, zoomLevel: newZoom)
        return newZoom
    }

    // Regular step is 0.25 except for the cases close to regular zoom
    // where we provide smaller step
    private func getNewZoomOutLevel(level: CGFloat) -> CGFloat {
        switch level {
        case 0.9:
            return 0.75
        case 1.0:
            return 0.9
        case 1.10:
            return 1.0
        case 1.25:
            return 1.10
        default:
            return level - 0.25
        }
    }

    /// Reset zoom level for a given host and saves new value
    /// - Parameters:
    ///   - shouldSave: Only false when entering reader mode where zoom resets but we don't persist the value
    func resetZoom(shouldSave: Bool = true) {
        guard let tab, let host = tab.url?.host else { return }

        tab.pageZoom = ZoomConstants.defaultZoomLimit
        saveZoomLevel(for: host, zoomLevel: ZoomConstants.defaultZoomLimit)
    }

    func updatePageZoom() {
        guard let tab = tab else { return }

        tab.pageZoom = getZoomLevel(for: tab.url?.host)
    }

    func updateZoomChangedInOtherWindow() {
        tab?.pageZoom = getZoomLevel()
    }

    func setZoomAfterLeavingReaderMode() {
        guard let host = decodeReaderModeHost() else { return }

        tab?.pageZoom = getZoomLevel(for: host)
    }

    private func decodeReaderModeHost() -> String? {
        guard let tab,
              tab.readerModeAvailableOrActive,
              let host = tab.url?.decodeReaderModeURL?.host else { return nil }
        return host
    }

    // MARK: - Store level

    /// Saves the zoom level for a given host and notifies other windows of the change
    /// - Parameters:
    ///   - host: The domain or host for which the zoom level is being saved
    ///   - zoomLevel: The zoom level value to save
    private func saveZoomLevel(for host: String, zoomLevel: CGFloat) {
        let domainZoomLevel = DomainZoomLevel(host: host, zoomLevel: zoomLevel)
        zoomStore.save(domainZoomLevel, completion: nil)

        // Notify other windows of zoom change (other pages with identical host should also update)
        let userInfo: [AnyHashable: Any] = [WindowUUID.userInfoKey: windowUUID, "zoom": domainZoomLevel]
        NotificationCenter.default.post(name: .PageZoomLevelUpdated, withUserInfo: userInfo)
    }

    /// Retrieves the previously saved zoom level for a given domain.
    /// - Parameter host: The domain or host to load the zoom level for.
    /// - Returns: The saved zoom level if found, otherwise returns the default zoom level
    private func getZoomLevel(for host: String?) -> CGFloat {
        guard let host = host,
              let domainZoomLevel = zoomStore.findZoomLevel(forDomain: host) else {
            return ZoomConstants.defaultZoomLimit
        }

        return domainZoomLevel.zoomLevel
    }

    // MARK: - TabEventHandler

    func tabDidGainFocus(_ tab: Tab) {
        self.tab = tab
        if tab.pageZoom != getZoomLevel() {
            updatePageZoom()
        }
    }
}
