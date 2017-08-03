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

    func refreshIfNeeded(forceHighlights highlights: Bool, forceTopSites topsites: Bool)
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
     refreshIfNeeded will refresh the underlying caches for both Topsites and Highlights.
     By default this will only refresh the highlights if the last fetch is older than 15 mins
     By default this will only refresh topsites if KeyTopSitesCacheIsValid is false
     */
    func refreshIfNeeded(forceHighlights highlights: Bool, forceTopSites topSites: Bool) {
        guard !profile.isShutdown else {
            return
        }

        // Highlights are cached for 15 mins 200 - 0 > 900 || 200 < 900
        let invalidateHighlights = highlights ? true : (Date.now() - lastInvalidation > invalidationTime)
        lastInvalidation = invalidateHighlights ? Date.now() : lastInvalidation

        // KeyTopSitesCacheIsValid is false when we want to invalidate. Thats why this logic is so backwards
        let invalidateTopSites = topSites ? true : !(profile.prefs.boolForKey(PrefsKeys.KeyTopSitesCacheIsValid) ?? false)
        if !invalidateTopSites && !invalidateHighlights {
            // There is nothing to refresh. Bye
            return
        }

        self.delegate?.willInvalidateDataSources()
        self.profile.recommendations.repopulateAll(invalidateTopSites, invalidateHighlights: invalidateHighlights).uponQueue(.main) { _ in
            if invalidateTopSites {
                self.profile.prefs.setBool(true, forKey: PrefsKeys.KeyTopSitesCacheIsValid)
            }
            self.delegate?.didInvalidateDataSources()
        }
    }

    @objc func notificationReceived(_ notification: Notification) {
        switch notification.name {
        case NotificationProfileDidFinishSyncing, NotificationFirefoxAccountChanged, NotificationPrivateDataClearedHistory:
            profile.prefs.setBool(false, forKey: PrefsKeys.KeyTopSitesCacheIsValid)
            refreshIfNeeded(forceHighlights: true, forceTopSites: true)
        default:
            log.warning("Received unexpected notification \(notification.name)")
        }
    }
}
