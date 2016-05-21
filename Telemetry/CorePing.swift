/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import UIKit

private let PrefKeyProfileDate = "PrefKeyProfileDate"
private let PrefKeyPingCount = "PrefKeyPingCount"
private let PrefKeyClientID = "PrefKeyClientID"
private let PrefKeyModel = "PrefKeyModel"

// See https://gecko.readthedocs.org/en/latest/toolkit/components/telemetry/telemetry/core-ping.html
private let PingVersion = 3

class CorePing: TelemetryPing {
    let payload: JSON

    init(profile: Profile) {
        let version = NSProcessInfo.processInfo().operatingSystemVersion
        let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"

        let pingCount = profile.prefs.intForKey(PrefKeyPingCount) ?? 0
        profile.prefs.setInt(pingCount + 1, forKey: PrefKeyPingCount)

        let profileDate: Int
        if let date = profile.prefs.intForKey(PrefKeyProfileDate) {
            profileDate = Int(date)
        } else if let attributes = try? NSFileManager.defaultManager().attributesOfItemAtPath(profile.files.rootPath as String),
                  let date = attributes[NSFileCreationDate] as? NSDate {
            let seconds = date.timeIntervalSince1970
            profileDate = Int(UInt64(seconds) * OneSecondInMilliseconds / OneDayInMilliseconds)
            profile.prefs.setInt(Int32(profileDate), forKey: PrefKeyProfileDate)
        } else {
            profileDate = 0
        }

        let clientID: String
        if let id = profile.prefs.stringForKey(PrefKeyClientID) {
            clientID = id
        } else {
            clientID = NSUUID().UUIDString
            profile.prefs.setString(clientID, forKey: PrefKeyClientID)
        }

        let model: String
        if let modelString = profile.prefs.stringForKey(PrefKeyModel) {
            model = modelString
        } else {
            var sysinfo = utsname()
            uname(&sysinfo)
            let rawModel = NSString(bytes: &sysinfo.machine, length: Int(_SYS_NAMELEN), encoding: NSASCIIStringEncoding)!
            model = rawModel.stringByTrimmingCharactersInSet(NSCharacterSet.controlCharacterSet())
            profile.prefs.setString(model, forKey: PrefKeyModel)
        }

        let locale = NSBundle.mainBundle().preferredLocalizations.first!.stringByReplacingOccurrencesOfString("_", withString: "-")
        let defaultEngine = profile.searchEngines.defaultEngine

        let engineId = defaultEngine.isCustomEngine ?  JSON.null : defaultEngine.engineId

        let out: [String: AnyObject] = [
            "v": PingVersion,
            "clientId": clientID,
            "seq": Int(pingCount),
            "locale": locale,
            "os": "iOS",
            "osversion": versionString,
            "device": "Apple-" + model,
            "arch": "arm",
            "profileDate": profileDate,
            "defaultSearch": engineId
        ]

        payload = JSON(out)
    }
}