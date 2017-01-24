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

extension SystemUtils {
    // This should be run on first run of the application. 
    // It shouldn't be run from an extension.
    // Its function is to write a lock file that is only accessible from the application, 
    // and not accessible from extension when the device is locked. Thus, we can tell if an extension is being run
    // when the device is locked.
    public static func onFirstRun() {
        guard let lockFileURL = lockedDeviceURL,
                lockFile = lockFileURL.path else {
                    return
        }

        let fm = NSFileManager.defaultManager()
        if fm.fileExistsAtPath(lockFile) {
            return
        }
        let contents = "Device is unlocked".dataUsingEncoding(NSUTF8StringEncoding)
        fm.createFileAtPath(lockFile, contents: contents, attributes: [NSFileProtectionKey : NSFileProtectionComplete])
    }

    private static var lockedDeviceURL: NSURL? {
        guard let groupIdentifier = AppInfo.sharedContainerIdentifier() else {
            return nil
        }
        let directoryURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(groupIdentifier)
        return directoryURL?.URLByAppendingPathComponent("security.dummy")
    }

    public static func isDeviceLocked() -> Bool {
        guard let lockFileURL = lockedDeviceURL else {
            return true
        }
        do {
            let _ = try NSData(contentsOfURL: lockFileURL, options: .DataReadingMappedIfSafe)
            return false
        } catch let err as NSError {
            return err.code == 257
        } catch _ {
            return true
        }
    }
}