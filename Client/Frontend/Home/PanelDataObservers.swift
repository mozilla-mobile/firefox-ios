/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Deferred
import Shared

public let ActivityStreamTopSiteCacheSize: Int32 = 16

private let log = Logger.browserLogger

protocol DataObserver {
    var profile: Profile { get }
    weak var delegate: DataObserverDelegate? { get set }

    func refreshIfNeeded(forceHighlights highlights: Bool, forceTopSites topSites: Bool)
}

protocol DataObserverDelegate: AnyObject {
    func didInvalidateDataSources(refresh forced: Bool, highlightsRefreshed: Bool, topSitesRefreshed: Bool)
    func willInvalidateDataSources(forceHighlights highlights: Bool, forceTopSites topSites: Bool)
}

// Make these delegate methods optional by providing default implementations
extension DataObserverDelegate {
    func didInvalidateDataSources(refresh forced: Bool, highlightsRefreshed: Bool, topSitesRefreshed: Bool) {}
    func willInvalidateDataSources(forceHighlights highlights: Bool, forceTopSites topSites: Bool) {}
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
     refreshIfNeeded will refresh the underlying caches for both TopSites and Highlights.
     By default this will only refresh the highlights if the last fetch is older than 15 mins
     By default this will only refresh topSites if KeyTopSitesCacheIsValid is false
     */
    func refreshIfNeeded(forceHighlights highlights: Bool, forceTopSites topSites: Bool) {
        guard !profile.isShutdown else {
            return
        }

        // Highlights are cached for 15 mins
        let userEnabledHighlights = profile.prefs.boolForKey(PrefsKeys.ASRecentHighlightsVisible) ?? true
        let lastInvalidationTime = UInt64(profile.prefs.unsignedLongForKey(PrefsKeys.ASLastInvalidation) ?? 0)
        let shouldInvalidateHighlights = (highlights || (Date.now() - lastInvalidationTime > invalidationTime)) && userEnabledHighlights

        // KeyTopSitesCacheIsValid is false when we want to invalidate. Thats why this logic is so backwards
        let shouldInvalidateTopSites = topSites || !(profile.prefs.boolForKey(PrefsKeys.KeyTopSitesCacheIsValid) ?? false)
        if !shouldInvalidateTopSites && !shouldInvalidateHighlights {
            // There is nothing to refresh. Bye
            return
        }

        // Flip the `KeyTopSitesCacheIsValid` flag now to prevent subsequent calls to refresh
        // from re-invalidating the cache.
        if shouldInvalidateTopSites {
            self.profile.prefs.setBool(true, forKey: PrefsKeys.KeyTopSitesCacheIsValid)
        }

        // Set the `ASLastInvalidation` timestamp now to prevent subsequent calls to refresh
        // from re-invalidating the cache.
        if shouldInvalidateHighlights {
            let newInvalidationTime = shouldInvalidateHighlights ? Date.now() : lastInvalidationTime
            self.profile.prefs.setLong(newInvalidationTime, forKey: PrefsKeys.ASLastInvalidation)
        }

        self.delegate?.willInvalidateDataSources(forceHighlights: highlights, forceTopSites: topSites)
        self.profile.recommendations.repopulate(invalidateTopSites: shouldInvalidateTopSites, invalidateHighlights: shouldInvalidateHighlights).uponQueue(.main) { _ in
            self.delegate?.didInvalidateDataSources(refresh: highlights || topSites, highlightsRefreshed: shouldInvalidateHighlights, topSitesRefreshed: shouldInvalidateTopSites)
        }
    }

    @objc func notificationReceived(_ notification: Notification) {
        switch notification.name {
        case .ProfileDidFinishSyncing, .FirefoxAccountChanged, .PrivateDataClearedHistory:
             refreshIfNeeded(forceHighlights: true, forceTopSites: true)
        default:
            log.warning("Received unexpected notification \(notification.name)")
        }
    }
}
