// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Glean
import Shared

enum UsageReason: String {
    case active
    case inactive
}

protocol GleanUsageReportingApi {
    func setUsageReason(_ usageReason: UsageReason)
    func submitPing()
}

class GleanUsageReporting: GleanUsageReportingApi {
    func setUsageReason(_ usageReason: UsageReason) {
        GleanMetrics.Usage.reason.set(usageReason.rawValue)
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
        GleanMetrics.Usage.appChannel.set(AppConstants.buildChannel.rawValue)
        if let date = InstallationUtils.inferredDateInstalledOn {
            GleanMetrics.Usage.firstRunDate.set(date)
        }
    }
}

class GleanLifecycleObserver {
    private let gleanUsageReportingApi: GleanUsageReportingApi
    private var id: TimerId?
    private var isObserving = false

    init(gleanUsageReportingApi: GleanUsageReportingApi = GleanUsageReporting()) {
        self.gleanUsageReportingApi = gleanUsageReportingApi
    }

    func startObserving() {
        guard !isObserving else { return }
        isObserving = true

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

    func stopObserving() {
        guard isObserving else { return }
        isObserving = false

        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    @objc
    private func appWillEnterForeground(notification: NSNotification) {
        handleForegroundEvent()
    }

    @objc
    private func appDidEnterBackground(notification: NSNotification) {
        handleBackgroundEvent()
    }

    func handleForegroundEvent() {
        id = GleanMetrics.Usage.duration.start()
        gleanUsageReportingApi.setUsageReason(.active)
        gleanUsageReportingApi.submitPing()
    }

    func handleBackgroundEvent() {
        id.map(GleanMetrics.Usage.duration.stopAndAccumulate)
        gleanUsageReportingApi.setUsageReason(.inactive)
        gleanUsageReportingApi.submitPing()
    }
}
