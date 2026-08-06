// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Glean
import MozillaAppServices

/// Bridges `RemoteSettingsService` uptake events to Glean.
final class RemoteSettingsGleanTelemetry: RemoteSettingsTelemetry {
    private let logger: Logger
    private let gleanWrapper: GleanWrapper

    init(logger: Logger = DefaultLogger.shared, gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.logger = logger
        self.gleanWrapper = gleanWrapper
    }

    func reportUptake(extras: UptakeEventExtras) {
        let extra = GleanMetrics.RemoteSettings.UptakeRemotesettingsExtra(
            age: extras.age,
            duration: extras.duration,
            errorname: extras.errorName,
            source: extras.source,
            timestamp: extras.timestamp,
            trigger: extras.trigger,
            value: extras.value
        )
        gleanWrapper.recordEvent(for: GleanMetrics.RemoteSettings.uptakeRemotesettings, extras: extra)
        let uptakeInfo = "value: \(extras.value ?? "nil"), source: \(extras.source ?? "nil"), "
            + "trigger: \(extras.trigger ?? "nil"), duration: \(extras.duration ?? "nil"), "
            + "errorName: \(extras.errorName ?? "nil")"
        logger.log(
            "Remote Settings uptake - \(uptakeInfo)",
            level: .debug,
            category: .remoteSettings
        )
    }
}
