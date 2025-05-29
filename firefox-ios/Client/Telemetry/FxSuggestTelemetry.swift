// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Glean
import Storage

class FxSuggestTelemetry {
    private enum EventInfo: String {
        case ampSuggestion = "amp-suggestion"
        case wikipediaSuggestion = "wikipedia-suggestion"
        case pingTypeClick = "fxsuggest-click"
        case pingTypeImpression = "fxsuggest-impression"
        case wikipediaAdvertiser = "wikipedia"
    }

    func clickEvent(telemetryInfo: RustFirefoxSuggestionTelemetryInfo, position: Int) {
        // MARK: - FX Suggest
        guard let contextIdString = TelemetryContextualIdentifier.contextId,
              let contextId = UUID(uuidString: contextIdString) else {
            return
        }

        // Record an event for this tap in the `events` ping.
        // These events include the `client_id`.
        let searchResultTapExtra = switch telemetryInfo {
        case .amp: GleanMetrics.Awesomebar.SearchResultTapExtra(type: EventInfo.ampSuggestion.rawValue)
        case .wikipedia: GleanMetrics.Awesomebar.SearchResultTapExtra(type: EventInfo.wikipediaSuggestion.rawValue)
        }
        GleanMetrics.Awesomebar.searchResultTap.record(searchResultTapExtra)

        // Submit a separate `fx-suggest` ping for this tap.
        // These pings do not include the `client_id`.
        GleanMetrics.FxSuggest.contextId.set(contextId)
        GleanMetrics.FxSuggest.pingType.set(EventInfo.pingTypeClick.rawValue)
        GleanMetrics.FxSuggest.isClicked.set(true)
        GleanMetrics.FxSuggest.position.set(Int64(position))
        switch telemetryInfo {
        case let .amp(blockId, advertiser, iabCategory, _, clickReportingURL):
            GleanMetrics.FxSuggest.blockId.set(blockId)
            GleanMetrics.FxSuggest.advertiser.set(advertiser)
            GleanMetrics.FxSuggest.iabCategory.set(iabCategory)
            if let clickReportingURL {
                GleanMetrics.FxSuggest.reportingUrl.set(url: clickReportingURL)
            }
        case .wikipedia:
            GleanMetrics.FxSuggest.advertiser.set(EventInfo.wikipediaAdvertiser.rawValue)
        }
        GleanMetrics.Pings.shared.fxSuggest.submit()
    }

    func impressionEvent(telemetryInfo: RustFirefoxSuggestionTelemetryInfo,
                         position: Int,
                         didTap: Bool,
                         didAbandonSearchSession: Bool) {
        guard let contextIdString = TelemetryContextualIdentifier.contextId,
              let contextId = UUID(uuidString: contextIdString) else {
            return
        }

        // Record an event for this impression in the `events` ping.
        // These events include the `client_id`, and we record them for
        // engaged and abandoned search sessions.
        let searchResultImpressionExtra = switch telemetryInfo {
        case .amp: GleanMetrics.Awesomebar.SearchResultImpressionExtra(type: EventInfo.ampSuggestion.rawValue)
        case .wikipedia: GleanMetrics.Awesomebar.SearchResultImpressionExtra(type: EventInfo.wikipediaSuggestion.rawValue)
        }
        GleanMetrics.Awesomebar.searchResultImpression.record(searchResultImpressionExtra)

        // Submit a separate `fx-suggest` ping for this impression.
        // These pings do not include the `client_id`, and we only submit
        // them for engaged search sessions.
        if didAbandonSearchSession { return }
        GleanMetrics.FxSuggest.contextId.set(contextId)
        GleanMetrics.FxSuggest.pingType.set(EventInfo.pingTypeImpression.rawValue)
        GleanMetrics.FxSuggest.isClicked.set(didTap)
        GleanMetrics.FxSuggest.position.set(Int64(position))
        switch telemetryInfo {
        case let .amp(blockId, advertiser, iabCategory, impressionReportingURL, _):
            GleanMetrics.FxSuggest.blockId.set(blockId)
            GleanMetrics.FxSuggest.advertiser.set(advertiser)
            GleanMetrics.FxSuggest.iabCategory.set(iabCategory)
            if let impressionReportingURL {
                GleanMetrics.FxSuggest.reportingUrl.set(url: impressionReportingURL)
            }
        case .wikipedia:
            GleanMetrics.FxSuggest.advertiser.set(EventInfo.wikipediaAdvertiser.rawValue)
        }
        GleanMetrics.Pings.shared.fxSuggest.submit()
    }
}
