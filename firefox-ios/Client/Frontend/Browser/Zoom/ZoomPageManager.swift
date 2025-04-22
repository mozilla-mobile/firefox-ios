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
    let tabEventWindowResponseType: TabEventHandlerWindowResponseType = .allWindows

    let windowUUID: WindowUUID
    var tab: Tab?

    init(windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
        register(self, forTabEvents: .didGainFocus)
    }

    func getZoomValue() -> CGFloat {
        guard let tab,
              let url = tab.url else { return ZoomConstants.defaultZoomLimit}

        return getZoomLevelforDomain(for: url.host)
    }

    // Check if guard is returning the proper thing
    func zoomIn() -> CGFloat {
        guard let tab = tab,
              let host = tab.url?.host,
              tab.pageZoom <= ZoomConstants.upperZoomLimit else { return ZoomConstants.upperZoomLimit}

        let newZoom = getNewZoomInValue(value: tab.pageZoom)
        tab.pageZoom = newZoom
        saveZoomLevel(for: host, zoomLevel: newZoom)
        return newZoom
    }

    // Regular step is 0.25 except for the cases close to regular zoom
    // where we provide smaller step
    private func getNewZoomInValue(value: CGFloat) -> CGFloat {
        switch value {
        case 0.75:
            return 0.9
        case 0.9:
            return 1.0
        case 1.0:
            return 1.10
        case 1.10:
            return 1.25
        default:
            return value + 0.25
        }
    }

    // Check if guard is returning the proper thing
    func zoomOut() -> CGFloat {
        guard let tab = tab,
              let host = tab.url?.host,
              tab.pageZoom < ZoomConstants.upperZoomLimit else { return ZoomConstants.lowerZoomLimit}

        let newZoom = getNewZoomOutValue(value: tab.pageZoom)
        tab.pageZoom = newZoom
        saveZoomLevel(for: host, zoomLevel: newZoom)
        return newZoom
    }

    // Regular step is 0.25 except for the cases close to regular zoom
    // where we provide smaller step
    private func getNewZoomOutValue(value: CGFloat) -> CGFloat {
        switch value {
        case 0.9:
            return 0.75
        case 1.0:
            return 0.9
        case 1.10:
            return 1.0
        case 1.25:
            return 1.10
        default:
            return value - 0.25
        }
    }

    func resetZoom() {
        tab?.pageZoom = ZoomConstants.defaultZoomLimit
    }

    func updatePageZoom() {
        guard let tab,
              let host = tab.url?.host,
              let domainZoomLevel = ZoomLevelStore.shared.findZoomLevel(forDomain: host) else { return }

        tab.pageZoom = domainZoomLevel.zoomLevel
    }

    func setZoomAfterLeavingReaderMode() {
        guard let host = decodeReaderModeHost(),
              let domainZoomLevel = ZoomLevelStore.shared.findZoomLevel(forDomain: host)
        else { return }

        tab?.pageZoom = domainZoomLevel.zoomLevel
    }

    private func decodeReaderModeHost() -> String? {
        guard let tab,
              tab.readerModeAvailableOrActive,
              let host = tab.url?.decodeReaderModeURL?.host else { return nil }
        return host
    }

    func updatePageZoomFromOtherWindow(zoomLevel: CGFloat) {
        print("YRD --- update zoom level for window \(windowUUID) level \(zoomLevel)")

        tab?.pageZoom = zoomLevel
    }

    // MARK: - Store level

    /// Saves the zoom level for a given host and notifies other windows of the change
    /// - Parameters:
    ///   - host: The domain or host for which the zoom level is being saved
    ///   - zoomLevel: The zoom level value to save
    private func saveZoomLevel(for host: String, zoomLevel: CGFloat) {
        let domainZoomLevel = DomainZoomLevel(host: host, zoomLevel: zoomLevel)
        ZoomLevelStore.shared.save(domainZoomLevel)

        print("YRD --- save zoom level \(domainZoomLevel)")
        // Notify other windows of zoom change (other pages with identical host should also update)
        let userInfo: [AnyHashable: Any] = [WindowUUID.userInfoKey: windowUUID, "zoom": domainZoomLevel]
        NotificationCenter.default.post(name: .PageZoomLevelUpdated, withUserInfo: userInfo)
    }

    /// Retrieves the previously saved zoom level for a given domain.
    /// - Parameter host: The domain or host to load the zoom level for.
    /// - Returns: The saved zoom level if found, otherwise returns the default zoom level
    private func getZoomLevelforDomain(for host: String?) -> CGFloat {
        guard let host = host,
              let domainZoomLevel = ZoomLevelStore.shared.findZoomLevel(forDomain: host) else {
            return ZoomConstants.defaultZoomLimit
        }

        print("YRD --- load zoom level \(domainZoomLevel)")
        return domainZoomLevel.zoomLevel
    }

    func updatePageZoom() {
        guard let tab = tab,
              let host = tab.url?.host,
              let domainZoomLevel = ZoomLevelStore.shared.findZoomLevel(forDomain: host) else { return }
        print("YRD --- udpate zoom level for tab \(host)")

        tab.pageZoom = domainZoomLevel.zoomLevel
    }

    func updateZoomChangedInOtherWindow() {
        tab?.pageZoom = getZoomValue()
    }

    // MARK: - TabEventHandler
    func tabDidGainFocus(_ tab: Tab) {
        print("YRD --- didGainFocus \(tab.url?.host ?? "")")

        self.tab = tab
        if tab.pageZoom != getZoomValue() {
            updatePageZoom()
        }
    }
}
