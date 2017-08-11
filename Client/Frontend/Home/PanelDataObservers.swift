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

@objc protocol DataObserverDelegate: class {
    func didInvalidateDataSources()
    func willInvalidateDataSources()
}

open class PanelDataObservers {
    var activityStream: DataObserver

    init(profile: Profile) {
        self.activityStream = ActivityStreamDataObserver(profile: profile)
    }
}

class ActivityStreamDataObserver: DataObserver {
    let profile: Profile
    weak var delegate: DataObserverDelegate?
    private var invalidationTime = OneMinuteInMilliseconds * 15
    private var lastInvalidation: UInt64 = 0

    fileprivate let events = [NotificationFirefoxAccountChanged, NotificationProfileDidFinishSyncing, NotificationPrivateDataClearedHistory]

    init(profile: Profile) {
        self.profile = profile
        self.profile.history.setTopSitesCacheSize(ActivityStreamTopSiteCacheSize)
        events.forEach { NotificationCenter.default.addObserver(self, selector: #selector(self.notificationReceived(_:)), name: $0, object: nil) }
    }

    deinit {
        events.forEach { NotificationCenter.default.removeObserver(self, name: $0, object: nil) }
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
        let shouldInvalidateHighlights = highlights || (Timestamp.uptimeInMilliseconds() - lastInvalidation > invalidationTime)

        // KeyTopSitesCacheIsValid is false when we want to invalidate. Thats why this logic is so backwards
        let shouldInvalidateTopSites = topSites || !(profile.prefs.boolForKey(PrefsKeys.KeyTopSitesCacheIsValid) ?? false)
        if !shouldInvalidateTopSites && !shouldInvalidateHighlights {
            // There is nothing to refresh. Bye
            return
        }

        self.delegate?.willInvalidateDataSources()
        self.profile.recommendations.repopulate(invalidateTopSites: shouldInvalidateTopSites, invalidateHighlights: shouldInvalidateHighlights).uponQueue(.main) { _ in
            if shouldInvalidateTopSites {
                self.profile.prefs.setBool(true, forKey: PrefsKeys.KeyTopSitesCacheIsValid)
            }
            self.lastInvalidation = shouldInvalidateHighlights ? Timestamp.uptimeInMilliseconds() : self.lastInvalidation
            self.delegate?.didInvalidateDataSources()
        }
    }

    @objc func notificationReceived(_ notification: Notification) {
        switch notification.name {
        case NotificationProfileDidFinishSyncing, NotificationFirefoxAccountChanged, NotificationPrivateDataClearedHistory:
             refreshIfNeeded(forceHighlights: true, forceTopSites: true)
        default:
            log.warning("Received unexpected notification \(notification.name)")
        }
    }
}
