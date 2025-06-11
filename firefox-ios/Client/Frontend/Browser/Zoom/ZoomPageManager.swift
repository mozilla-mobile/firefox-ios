// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Storage

struct ZoomConstants {
    static let defaultZoomLimit: CGFloat = ZoomLevel.oneHundredPercent.rawValue
    static let lowerZoomLimit: CGFloat = ZoomLevel.fiftyPercent.rawValue
    static let upperZoomLimit: CGFloat = ZoomLevel.threeHundredPercent.rawValue
}

class ZoomPageManager: TabEventHandler, FeatureFlaggable {
    var tabEventWindowResponseType: TabEventHandlerWindowResponseType { return .singleWindow(windowUUID) }

    let windowUUID: WindowUUID
    let zoomStore: ZoomLevelStorage
    var tab: Tab?

    var defaultZoomIsEnabled: Bool {
        return featureFlags.isFeatureEnabled(.defaultZoomFeature, checking: .buildOnly)
    }

    var defaultZoomLevel: CGFloat {
        guard defaultZoomIsEnabled else { return ZoomConstants.defaultZoomLimit }

        return zoomStore.getDefaultZoom()
    }

    init(windowUUID: WindowUUID,
         zoomStore: ZoomLevelStorage = ZoomLevelStore.shared) {
        self.windowUUID = windowUUID
        self.zoomStore = zoomStore
        register(self, forTabEvents: .didGainFocus, .didChangeURL)
    }

    func getZoomLevel() -> CGFloat {
        guard let tab else { return defaultZoomLevel}

        return getZoomLevel(for: tab.url?.host)
    }

    func zoomIn() -> CGFloat {
        guard let tab = tab,
              let host = tab.url?.host else { return defaultZoomLevel}

        let newZoom = ZoomLevel.getNewZoomInLevel(for: tab.pageZoom)
        tab.pageZoom = newZoom
        saveZoomLevel(for: host, zoomLevel: newZoom)
        return newZoom
    }

    func zoomOut() -> CGFloat {
        guard let tab = tab,
              let host = tab.url?.host else { return defaultZoomLevel}

        let newZoom = ZoomLevel.getNewZoomOutLevel(for: tab.pageZoom)
        tab.pageZoom = newZoom
        saveZoomLevel(for: host, zoomLevel: newZoom)
        return newZoom
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

    func saveDefaultZoomLevel(defaultZoom: CGFloat) {
        zoomStore.saveDefaultZoomLevel(defaultZoom: defaultZoom)
    }

    func getDomainLevel() -> [DomainZoomLevel] {
        let domainZoomLevels = zoomStore.getDomainZoomLevel()

        // Filter current default zoom level from the list
        let filterList = domainZoomLevels.filter { $0.zoomLevel != defaultZoomLevel }
        return filterList
    }

    /// Saves the zoom level for a given host and notifies other windows of the change
    /// - Parameters:
    ///   - host: The domain or host for which the zoom level is being saved
    ///   - zoomLevel: The zoom level value to save
    private func saveZoomLevel(for host: String, zoomLevel: CGFloat) {
        let domainZoomLevel = DomainZoomLevel(host: host, zoomLevel: zoomLevel)
        zoomStore.saveDomainZoom(domainZoomLevel, completion: nil)

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
            return defaultZoomLevel
        }

        return domainZoomLevel.zoomLevel
    }

    func deleteZoomLevel(for host: String) {
        zoomStore.deleteZoomLevel(for: host)
    }

    func resetDomainZoomLevel() {
        zoomStore.resetDomainZoomLevel()
    }

    // MARK: - TabEventHandler

    func tabDidGainFocus(_ tab: Tab) {
        self.tab = tab
        if tab.pageZoom != getZoomLevel() {
            updatePageZoom()
        }
    }

    func tab(_ tab: Tab, didChangeURL url: URL) {
        guard tab == self.tab else { return }

        if tab.pageZoom != getZoomLevel() {
            updatePageZoom()
        }
    }
}
