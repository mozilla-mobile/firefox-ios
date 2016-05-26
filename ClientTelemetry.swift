/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

private let PrefKeySearches = "Telemetry.Searches"

class SearchTelemetry {
    // For data consistency, the strings used here are identical to the ones reported in Android.
    enum Source: String {
        case URLBar = "actionbar"
        case QuickSearch = "listitem"
        case Suggestion = "suggestion"
    }

    private init() {}

    class func makeEvent(engine engine: OpenSearchEngine, source: Source) -> TelemetryEvent {
        let engineID = engine.engineID ?? "other"
        return SearchTelemetryEvent(engineWithSource: "\(engineID).\(source.rawValue)")
    }

    class func getData(prefs: Prefs) -> [String: Int]? {
        return prefs.dictionaryForKey(PrefKeySearches) as? [String: Int]
    }

    class func resetCount(prefs: Prefs) {
        prefs.removeObjectForKey(PrefKeySearches)
    }
}

private class SearchTelemetryEvent: TelemetryEvent {
    private let engineWithSource: String

    init(engineWithSource: String) {
        self.engineWithSource = engineWithSource
    }

    func record(prefs: Prefs) {
        var searches = SearchTelemetry.getData(prefs) ?? [:]
        searches[engineWithSource] = (searches[engineWithSource] ?? 0) + 1
        prefs.setObject(searches, forKey: PrefKeySearches)
    }
}