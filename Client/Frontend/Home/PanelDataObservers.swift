/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Deferred
import Shared

public let NotificationASPanelDataInvalidated = Notification.Name("NotificationASPanelDataInvalidated")
private let log = Logger.browserLogger

struct PanelDataObservers {
    let activityStream: ActivityStreamDataObserver
}

protocol ActivityStreamDataDelegate: class {
    func didInvalidateDataSources()
}

class ActivityStreamDataObserver {
    let profile: Profile
    weak var delegate: ActivityStreamDataDelegate?

    fileprivate let events = [NotificationFirefoxAccountChanged, NotificationProfileDidFinishSyncing, NotificationPrivateDataClearedHistory, NotificationDynamicFontChanged]

    init(profile: Profile) {
        self.profile = profile
        events.forEach { NotificationCenter.default.addObserver(self, selector: #selector(self.notificationReceived(_:)), name: $0, object: nil) }
    }

    deinit {
        events.forEach { NotificationCenter.default.removeObserver(self, name: $0, object: nil) }
    }
    
    func invalidate() {
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
        case NotificationProfileDidFinishSyncing, NotificationFirefoxAccountChanged, NotificationPrivateDataClearedHistory, NotificationDynamicFontChanged:
            invalidate()
        default:
            log.warning("Received unexpected notification \(notification.name)")
        }
    }
}
