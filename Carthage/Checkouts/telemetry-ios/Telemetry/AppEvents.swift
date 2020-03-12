/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
import UIKit

class AppEvents {
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(AppEvents.appWillResignActive(notification:)), name: UIApplication.willResignActiveNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(AppEvents.appDidEnterBackground(notification:)), name: UIApplication.didEnterBackgroundNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(AppEvents.appDidBecomeActive(notification:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc func appWillResignActive(notification: NSNotification) {
        if Telemetry.default.hasPingType(CorePingBuilder.PingType) {
            Telemetry.default.recordSessionEnd()
        }

        Telemetry.default.forEachPingType { pingType in
            Telemetry.default.queue(pingType: pingType)
        }
    }

    private func upload() {
        Telemetry.default.forEachPingType { pingType in
            Telemetry.default.scheduleUpload(pingType: pingType)
        }
    }

    @objc func appDidEnterBackground(notification: NSNotification) {
        if [ScheduleUpload.backgrounded, ScheduleUpload.both].contains(Telemetry.default.configuration.scheduleUpload) {
            upload()
        }
    }

    @objc func appDidBecomeActive(notification: NSNotification) {
        if Telemetry.default.hasPingType(CorePingBuilder.PingType) {
            Telemetry.default.recordSessionStart()
        }

        if [ScheduleUpload.foregrounded, ScheduleUpload.both].contains(Telemetry.default.configuration.scheduleUpload) {
            upload()
        }
    }
}



