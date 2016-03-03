/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/**
 *  System helper methods written in Swift.
 */
public struct SystemUtils {

    /**
     Returns an accurate version of the system uptime even while the device is asleep.
     http://stackoverflow.com/questions/12488481/getting-ios-system-uptime-that-doesnt-pause-when-asleep

     - returns: Time interval since last reboot.
     */
    public static func systemUptime() -> NSTimeInterval {
        var boottime = timeval()
        var mib = [CTL_KERN, KERN_BOOTTIME]
        var size = strideof(timeval)
        var now = time_t()
        time(&now)

        sysctl(&mib, u_int(mib.count), &boottime, &size, nil, 0)
        let tv_sec: time_t = withUnsafePointer(&boottime.tv_sec) { $0.memory }
        return NSTimeInterval(now - tv_sec)
    }
}