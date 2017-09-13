/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import UIKit
import SwiftyJSON
import Telemetry

private let PrefKeyProfileDate = "PrefKeyProfileDate"
private let PrefKeyPingCount = "PrefKeyPingCount"
private let PrefKeyModel = "PrefKeyModel"

// See https://gecko.readthedocs.org/en/latest/toolkit/components/telemetry/telemetry/core-ping.html
private let PingVersion = 7

class CorePing: TelemetryPing {
    let payload: JSON
    let prefs: Prefs

    init(profile: Profile) {
        self.prefs = profile.prefs

        let version = ProcessInfo.processInfo.operatingSystemVersion
        let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"

        let pingCount = profile.prefs.intForKey(PrefKeyPingCount) ?? 0
        profile.prefs.setInt(pingCount + 1, forKey: PrefKeyPingCount)

        let profileDate: Int
        if let date = profile.prefs.intForKey(PrefKeyProfileDate) {
            profileDate = Int(date)
        } else if let attributes = try? FileManager.default.attributesOfItem(atPath: profile.files.rootPath as String),
                  let date = attributes[FileAttributeKey.creationDate] as? NSDate {
            let seconds = date.timeIntervalSince1970
            profileDate = Int(UInt64(seconds) * OneSecondInMilliseconds / OneDayInMilliseconds)
            profile.prefs.setInt(Int32(profileDate), forKey: PrefKeyProfileDate)
        } else {
            profileDate = 0
        }

        let model: String
        if let modelString = profile.prefs.stringForKey(PrefKeyModel) {
            model = modelString
        } else {
            var sysinfo = utsname()
            uname(&sysinfo)
            let rawModel = NSString(bytes: &sysinfo.machine, length: Int(_SYS_NAMELEN), encoding: String.Encoding.ascii.rawValue)!
            model = rawModel.trimmingCharacters(in: NSCharacterSet.controlCharacters)
            profile.prefs.setString(model, forKey: PrefKeyModel)
        }

        let locale = Bundle.main.preferredLocalizations.first!.replacingOccurrences(of: "_", with: "-")
        let defaultEngine = profile.searchEngines.defaultEngine

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let date = formatter.string(from: NSDate() as Date)

        let timezoneOffset = NSTimeZone.local.secondsFromGMT() / 60

        let usageCount = UsageTelemetry.getCount(prefs)
        let usageTime = UsageTelemetry.getTime(prefs)
        UsageTelemetry.reset(prefs)

        var out: [String: Any] = [
            "v": PingVersion,
            "clientId": profile.clientID,
            "seq": Int(pingCount),
            "locale": locale,
            "os": "iOS",
            "osversion": versionString,
            "device": "Apple-" + model,
            "arch": "arm",
            "profileDate": profileDate,
            "defaultSearch": defaultEngine.engineID as Any,
            "created": date,
            "tz": timezoneOffset,
            "sessions": usageCount,
            "durations": usageTime,
        ]

        if let searches = SearchTelemetry.getData(profile.prefs) {
            out["searches"] = searches
            SearchTelemetry.resetCount(profile.prefs)
        }

        if let newTabChoice = self.prefs.stringForKey(NewTabAccessors.PrefKey) {
            out["defaultNewTabExperience"] = newTabChoice as AnyObject?
        }

        if let chosenEmailClient = self.prefs.stringForKey(PrefsKeys.KeyMailToOption) {
            out["defaultMailClient"] = chosenEmailClient as AnyObject?
        }

        payload = JSON(out)
    }
}
