// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Glean
import Shared

enum UsageReason: String, Equatable {
    case active
    case inactive
}

protocol GleanUsageReportingApi {
    func setUsageReason(_ usageReason: UsageReason)
    func submitPing()
    func startTrackingDuration()
    func stopTrackingDuration()
}

class GleanUsageReporting: GleanUsageReportingApi {
    private var id: TimerId?

    func startTrackingDuration() {
        id = GleanMetrics.Usage.duration.start()
    }

    func stopTrackingDuration() {
        if let timerId = id {
            GleanMetrics.Usage.duration.stopAndAccumulate(timerId)
        }
    }

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
    private var isObserving: Bool = false
    private let notificationCenter: NotificationCenter

    init(
        gleanUsageReportingApi: GleanUsageReportingApi = GleanUsageReporting(),
        notificationCenter: NotificationCenter = .default
    ) {
        self.gleanUsageReportingApi = gleanUsageReportingApi
        self.notificationCenter = notificationCenter
    }

    func startObserving() {
        guard !isObserving else { return }
        isObserving = true

        notificationCenter.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        notificationCenter.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    func stopObserving() {
        guard isObserving else { return }
        isObserving = false

        notificationCenter.removeObserver(
            self,
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        notificationCenter.removeObserver(
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
        gleanUsageReportingApi.startTrackingDuration()
        gleanUsageReportingApi.setUsageReason(.active)
        gleanUsageReportingApi.submitPing()
    }

    func handleBackgroundEvent() {
        gleanUsageReportingApi.stopTrackingDuration()
        gleanUsageReportingApi.setUsageReason(.inactive)
        gleanUsageReportingApi.submitPing()
    }
}
