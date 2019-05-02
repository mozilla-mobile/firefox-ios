/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

public let ActivityStreamTopSiteCacheSize: Int32 = 32

private let log = Logger.browserLogger

protocol DataObserver {
    var profile: Profile { get }
    var delegate: DataObserverDelegate? { get set }

    func refreshIfNeeded(forceTopSites topSites: Bool)
}

protocol DataObserverDelegate: AnyObject {
    func didInvalidateDataSources(refresh forced: Bool, topSitesRefreshed: Bool)
    func willInvalidateDataSources(forceTopSites topSites: Bool)
}

// Make these delegate methods optional by providing default implementations
extension DataObserverDelegate {
    func didInvalidateDataSources(refresh forced: Bool, topSitesRefreshed: Bool) {}
    func willInvalidateDataSources(forceTopSites topSites: Bool) {}
}

open class PanelDataObservers {
    var activityStream: DataObserver

    init(profile: Profile) {
        self.activityStream = ActivityStreamDataObserver(profile: profile)
    }
}

class ActivityStreamDataObserver: DataObserver {
    let profile: Profile
    let invalidationTime: UInt64
    weak var delegate: DataObserverDelegate?

    fileprivate let events: [Notification.Name] = [.FirefoxAccountChanged, .ProfileDidFinishSyncing, .PrivateDataClearedHistory]

    init(profile: Profile) {
        self.profile = profile
        self.profile.history.setTopSitesCacheSize(ActivityStreamTopSiteCacheSize)
        self.invalidationTime = OneMinuteInMilliseconds * 15
        events.forEach { NotificationCenter.default.addObserver(self, selector: #selector(self.notificationReceived), name: $0, object: nil) }
    }

    /*
     refreshIfNeeded will refresh the underlying caches for TopSites.
     By default this will only refresh topSites if KeyTopSitesCacheIsValid is false
     */
    func refreshIfNeeded(forceTopSites topSites: Bool) {
        guard !profile.isShutdown else {
            return
        }

        // KeyTopSitesCacheIsValid is false when we want to invalidate. Thats why this logic is so backwards
        let shouldInvalidateTopSites = topSites || !(profile.prefs.boolForKey(PrefsKeys.KeyTopSitesCacheIsValid) ?? false)
        if !shouldInvalidateTopSites {
            // There is nothing to refresh. Bye
            return
        }

        // Flip the `KeyTopSitesCacheIsValid` flag now to prevent subsequent calls to refresh
        // from re-invalidating the cache.
        if shouldInvalidateTopSites {
            self.profile.prefs.setBool(true, forKey: PrefsKeys.KeyTopSitesCacheIsValid)
        }

        self.delegate?.willInvalidateDataSources(forceTopSites: topSites)
        self.profile.recommendations.repopulate(invalidateTopSites: shouldInvalidateTopSites).uponQueue(.main) { _ in
            self.delegate?.didInvalidateDataSources(refresh: topSites, topSitesRefreshed: shouldInvalidateTopSites)
        }
    }

    @objc func notificationReceived(_ notification: Notification) {
        switch notification.name {
        case .ProfileDidFinishSyncing, .FirefoxAccountChanged, .PrivateDataClearedHistory:
             refreshIfNeeded(forceTopSites: true)
        default:
            log.warning("Received unexpected notification \(notification.name)")
        }
    }
}
