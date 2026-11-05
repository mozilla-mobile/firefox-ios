// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean

struct InstallationTelemetry {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    /// Saves the original purchase date and app version to Glean when available.
    func recordAcquisition(appAcquisition: AppAcquisition) {
        gleanWrapper.recordDatetime(
            for: GleanMetrics.Installation.originalPurchaseDate,
            value: appAcquisition.originalPurchaseDate
        )
        gleanWrapper.recordString(
            for: GleanMetrics.Installation.originalAppVersion,
            value: appAcquisition.originalAppVersion
        )
    }

    func recordInstallationHistory(count: Int64, lastSeenDate: Date?) {
        gleanWrapper.recordQuantity(
            for: GleanMetrics.Installation.installCounter,
            value: count
        )

        if let lastSeenDate {
            gleanWrapper.recordDatetime(
                for: GleanMetrics.Installation.lastSeenDate,
                value: lastSeenDate
            )
        }
    }

    func submit() {
        gleanWrapper.submit(ping: GleanMetrics.Pings.shared.installation)
    }
}
