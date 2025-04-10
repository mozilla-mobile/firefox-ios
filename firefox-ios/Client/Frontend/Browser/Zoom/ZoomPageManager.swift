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

class ZoomPageManager {
    let windowUUID: WindowUUID

    init(windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
    }

    // Regular step is 0.25 except for the cases close to regular zoom
    // where we provide smaller step
    @objc
    func zoomIn(value: CGFloat) -> CGFloat {
        guard value < ZoomConstants.upperZoomLimit else { return value}

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

    // Regular step is 0.25 except for the cases close to regular zoom
    // where we provide smaller step
    @objc
    func zoomOut(value: CGFloat) -> CGFloat {
        guard value > ZoomConstants.lowerZoomLimit else { return value}

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

    /// Saves the zoom level for a given host and notifies other windows of the change
    /// - Parameters:
    ///   - host: The domain or host for which the zoom level is being saved
    ///   - zoomLevel: The zoom level value to save
    func saveZoomLevel(for host: String, zoomLevel: CGFloat) {
        let domainZoomLevel = DomainZoomLevel(host: host, zoomLevel: zoomLevel)
        ZoomLevelStore.shared.save(domainZoomLevel)

        // Notify other windows of zoom change (other pages with identical host should also update)
        let userInfo: [AnyHashable: Any] = [WindowUUID.userInfoKey: windowUUID, "zoom": domainZoomLevel]
        NotificationCenter.default.post(name: .PageZoomLevelUpdated, withUserInfo: userInfo)
    }

    /// Retrieves the previously saved zoom level for a given domain.
    /// - Parameter host: The domain or host to load the zoom level for.
    /// - Returns: The saved zoom level if found, otherwise returns the default zoom level
    func setZoomLevelforDomain(for host: String?) -> CGFloat {
        guard let host = host,
              let domainZoomLevel = ZoomLevelStore.shared.findZoomLevel(forDomain: host) else {
            return ZoomConstants.defaultZoomLimit
        }

        return domainZoomLevel.zoomLevel
    }
}
