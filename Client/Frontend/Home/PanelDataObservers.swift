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
    
    func invalidate()
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

    fileprivate let events = [NotificationFirefoxAccountChanged, NotificationProfileDidFinishSyncing, NotificationPrivateDataClearedHistory]

    init(profile: Profile) {
        self.profile = profile
        self.profile.history.setTopSitesCacheSize(ActivityStreamTopSiteCacheSize)
        events.forEach { NotificationCenter.default.addObserver(self, selector: #selector(self.notificationReceived(_:)), name: $0, object: nil) }
    }

    deinit {
        events.forEach { NotificationCenter.default.removeObserver(self, name: $0, object: nil) }
    }

    func invalidate() {
        self.delegate?.willInvalidateDataSources()

        let notify = {
            self.delegate?.didInvalidateDataSources()
        }
        
        let invalidateTopSites: () -> Success = {
            self.profile.history.setTopSitesNeedsInvalidation()
            return self.profile.history.updateTopSitesCacheIfInvalidated() >>> succeed
        }

        accumulate([self.profile.recommendations.invalidateHighlights, invalidateTopSites]) >>> effect(notify)
    }
    
    @objc func notificationReceived(_ notification: Notification) {
        switch notification.name {
        case NotificationProfileDidFinishSyncing, NotificationFirefoxAccountChanged, NotificationPrivateDataClearedHistory:
            invalidate()
        default:
            log.warning("Received unexpected notification \(notification.name)")
        }
    }
}
