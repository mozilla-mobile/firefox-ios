// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

protocol GleanWrapper {
    func handleDeeplinkUrl(url: URL)
    func submitPing()
    func setUpload(isEnabled: Bool)
}

/// Glean wrapper to abstract Glean from our application
struct DefaultGleanWrapper: GleanWrapper {
    public static let shared = DefaultGleanWrapper()

    func handleDeeplinkUrl(url: URL) {
        Glean.shared.handleCustomUrl(url: url)
    }
    func setUpload(isEnabled: Bool) {
        Glean.shared.setCollectionEnabled(isEnabled)
    }
    func submitPing() {
        GleanMetrics.Pings.shared.firstSession.submit()
    }

    func submitEventMetricType<ExtraObject>(event: EventMetricType<ExtraObject>,
                                            extras: EventExtras) where ExtraObject: EventExtras {
        if let castedExtras = extras as? ExtraObject {
            event.record(castedExtras)
        } else {
            fatalError("extras could not be cast to the expected type \(ExtraObject.self)")
        }
    }
}

class Example {
    func example() {
        let didConfirmExtra = GleanMetrics.PrivateBrowsing.DataClearanceIconTappedExtra(didConfirm: true)
        DefaultGleanWrapper().submitEventMetricType(event: GleanMetrics.PrivateBrowsing.dataClearanceIconTapped,
                                                    extras: didConfirmExtra)
    }
}
