// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Glean

enum UsageReason: String {
    case active = "active"
    case inactive = "inactive"
}

protocol GleanUsageReportingApi {
    func setUsageReason(_ usageReason: UsageReason)
    func setDuration(_ durationMillis: Int64)
    func submitPing()
}

class GleanUsageReporting: GleanUsageReportingApi {

    private let numberOfNanosInAMilli: Int64 = 1000

    func setUsageReason(_ usageReason: UsageReason) {
        GleanMetrics.Usage.reason.set(usageReason.rawValue)
    }

    func setDuration(_ durationMillis: Int64) {
        GleanMetrics.Usage.duration.setRawNanos(durationMillis * numberOfNanosInAMilli)
    }

    func submitPing() {
        setUsageConstantValues()
        GleanMetrics.Pings.shared.usageReporting.submit()
    }

    private func setUsageConstantValues() {
        GleanMetrics.Usage.os.set("iOS")
        GleanMetrics.Usage.osVersion.set(UIDevice.current.systemVersion)
        GleanMetrics.Usage.appDisplayVersion.set(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
        GleanMetrics.Usage.appBuild.set(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "")
    }
}

class GleanLifecycleObserver {

    private let gleanUsageReportingApi: GleanUsageReportingApi
    private let currentTimeProvider: () -> Int64
    private var durationStartMs: Int64?

    init(
        gleanUsageReportingApi: GleanUsageReportingApi = GleanUsageReporting(),
        currentTimeProvider: @escaping () -> Int64 = { Int64(Date().timeIntervalSince1970 * 1000) }
    ) {
        self.gleanUsageReportingApi = gleanUsageReportingApi
        self.currentTimeProvider = currentTimeProvider

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    @objc private func appWillEnterForeground(notification: NSNotification) {
        handleForegroundEvent()
    }

    @objc private func appDidEnterBackground(notification: NSNotification) {
        handleBackgroundEvent()
    }

    func handleForegroundEvent() {
        durationStartMs = currentTimeProvider()
        gleanUsageReportingApi.setUsageReason(.active)
        gleanUsageReportingApi.submitPing()
    }

    func handleBackgroundEvent() {
        if let startMs = durationStartMs {
            gleanUsageReportingApi.setDuration(currentTimeProvider() - startMs)
        }
        gleanUsageReportingApi.setUsageReason(.inactive)
        gleanUsageReportingApi.submitPing()
    }
}
