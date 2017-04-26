/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Telemetry

private let PrefKeySearches = "Telemetry.Searches"
private let PrefKeyUsageTime = "Telemetry.UsageTime"
private let PrefKeyUsageCount = "Telemetry.UsageCount"

class SearchTelemetry {
    // For data consistency, the strings used here are identical to the ones reported in Android.
    enum Source: String {
        case URLBar = "actionbar"
        case QuickSearch = "listitem"
        case Suggestion = "suggestion"
    }

    fileprivate init() {}

    class func makeEvent(_ engine: OpenSearchEngine, source: Source) -> TelemetryEvent {
        let engineID = engine.engineID ?? "other"
        return SearchTelemetryEvent(engineWithSource: "\(engineID).\(source.rawValue)")
    }

    class func getData(_ prefs: Prefs) -> [String: Int]? {
        return prefs.dictionaryForKey(PrefKeySearches) as? [String: Int]
    }

    class func resetCount(_ prefs: Prefs) {
        prefs.removeObjectForKey(PrefKeySearches)
    }
}

private class SearchTelemetryEvent: TelemetryEvent {
    fileprivate let engineWithSource: String

    init(engineWithSource: String) {
        self.engineWithSource = engineWithSource
    }

    func record(_ prefs: Prefs) {
        var searches = SearchTelemetry.getData(prefs) ?? [:]
        searches[engineWithSource] = (searches[engineWithSource] ?? 0) + 1
        prefs.setObject(searches, forKey: PrefKeySearches)
    }
}

class UsageTelemetry {
    fileprivate init() {}

    class func makeEvent(_ usageInterval: Int) -> TelemetryEvent {
        return UsageTelemetryEvent(usageInterval: usageInterval)
    }

    class func getCount(_ prefs: Prefs) -> Int {
        return Int(prefs.intForKey(PrefKeyUsageCount) ?? 0)
    }

    class func getTime(_ prefs: Prefs) -> Int {
        return Int(prefs.intForKey(PrefKeyUsageTime) ?? 0)
    }

    class func reset(_ prefs: Prefs) {
        prefs.setInt(0, forKey: PrefKeyUsageCount)
        prefs.setInt(0, forKey: PrefKeyUsageTime)
    }
}

private class UsageTelemetryEvent: TelemetryEvent {
    fileprivate let usageInterval: Int

    init(usageInterval: Int) {
        self.usageInterval = usageInterval
    }

    func record(_ prefs: Prefs) {
        let count = Int32(UsageTelemetry.getCount(prefs) + 1)
        prefs.setInt(count, forKey: PrefKeyUsageCount)

        let time = Int32(UsageTelemetry.getTime(prefs) + usageInterval)
        prefs.setInt(time, forKey: PrefKeyUsageTime)
    }
}
