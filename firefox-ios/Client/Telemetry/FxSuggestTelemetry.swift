// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Glean
import Storage

struct FxSuggestTelemetry {
    enum EventInfo: String {
        case ampSuggestion = "amp-suggestion"
        case wikipediaSuggestion = "wikipedia-suggestion"
        case pingTypeClick = "fxsuggest-click"
        case pingTypeImpression = "fxsuggest-impression"
        case wikipediaAdvertiser = "wikipedia"
    }

    private let systemRegion: String
    private let gleanWrapper: GleanWrapper

    init(locale: LocaleProvider = SystemLocaleProvider(),
         gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.systemRegion = locale.regionCode()
        self.gleanWrapper = gleanWrapper
    }

    func clickEvent(telemetryInfo: RustFirefoxSuggestionTelemetryInfo, position: Int) {
        guard let contextIdString = TelemetryContextualIdentifier.contextId,
              let contextId = UUID(uuidString: contextIdString) else {
            assertionFailure("Contextual identifier should be set")
            return
        }

        // Record an event for this tap in the `events` ping.
        // These events include the `client_id`.
        let searchResultTapExtra = switch telemetryInfo {
        case .amp: GleanMetrics.Awesomebar.SearchResultTapExtra(type: EventInfo.ampSuggestion.rawValue)
        case .wikipedia: GleanMetrics.Awesomebar.SearchResultTapExtra(type: EventInfo.wikipediaSuggestion.rawValue)
        }
        gleanWrapper.recordEvent(for: GleanMetrics.Awesomebar.searchResultTap,
                                 extras: searchResultTapExtra)

        // Submit a separate `fx-suggest` ping for this tap.
        // These pings do not include the `client_id`.
        gleanWrapper.recordUUID(for: GleanMetrics.FxSuggest.contextId,
                                value: contextId)
        gleanWrapper.recordString(for: GleanMetrics.FxSuggest.pingType,
                                  value: EventInfo.pingTypeClick.rawValue)
        gleanWrapper.setBoolean(for: GleanMetrics.FxSuggest.isClicked,
                                value: true)
        gleanWrapper.recordQuantity(for: GleanMetrics.FxSuggest.position,
                                    value: Int64(position))
        gleanWrapper.recordString(for: GleanMetrics.FxSuggest.country,
                                  value: systemRegion)

        switch telemetryInfo {
        case let .amp(blockId, advertiser, iabCategory, _, clickReportingURL):
            gleanWrapper.recordQuantity(for: GleanMetrics.FxSuggest.blockId,
                                        value: blockId)
            gleanWrapper.recordString(for: GleanMetrics.FxSuggest.advertiser,
                                      value: advertiser)
            gleanWrapper.recordString(for: GleanMetrics.FxSuggest.iabCategory,
                                      value: iabCategory)

            if let clickReportingURL {
                gleanWrapper.recordUrl(for: GleanMetrics.FxSuggest.reportingUrl,
                                       value: clickReportingURL)
            }
        case .wikipedia:
            gleanWrapper.recordString(for: GleanMetrics.FxSuggest.advertiser,
                                      value: EventInfo.wikipediaAdvertiser.rawValue)
        }
        gleanWrapper.submit(ping: GleanMetrics.Pings.shared.fxSuggest)
    }

    func impressionEvent(telemetryInfo: RustFirefoxSuggestionTelemetryInfo,
                         position: Int,
                         didTap: Bool,
                         didAbandonSearchSession: Bool) {
        guard let contextIdString = TelemetryContextualIdentifier.contextId,
              let contextId = UUID(uuidString: contextIdString) else {
            assertionFailure("Contextual identifier should be set")
            return
        }

        // Record an event for this impression in the `events` ping.
        // These events include the `client_id`, and we record them for
        // engaged and abandoned search sessions.
        let searchResultImpressionExtra = switch telemetryInfo {
        case .amp: GleanMetrics.Awesomebar.SearchResultImpressionExtra(type: EventInfo.ampSuggestion.rawValue)
        case .wikipedia: GleanMetrics.Awesomebar.SearchResultImpressionExtra(type: EventInfo.wikipediaSuggestion.rawValue)
        }
        gleanWrapper.recordEvent(for: GleanMetrics.Awesomebar.searchResultImpression,
                                 extras: searchResultImpressionExtra)

        // Submit a separate `fx-suggest` ping for this impression.
        // These pings do not include the `client_id`, and we only submit
        // them for engaged search sessions.
        if didAbandonSearchSession { return }
        gleanWrapper.recordUUID(for: GleanMetrics.FxSuggest.contextId,
                                value: contextId)
        gleanWrapper.recordString(for: GleanMetrics.FxSuggest.pingType,
                                  value: EventInfo.pingTypeImpression.rawValue)
        gleanWrapper.setBoolean(for: GleanMetrics.FxSuggest.isClicked,
                                value: didTap)
        gleanWrapper.recordQuantity(for: GleanMetrics.FxSuggest.position,
                                    value: Int64(position))
        gleanWrapper.recordString(for: GleanMetrics.FxSuggest.country,
                                  value: systemRegion)

        switch telemetryInfo {
        case let .amp(blockId, advertiser, iabCategory, impressionReportingURL, _):
            gleanWrapper.recordQuantity(for: GleanMetrics.FxSuggest.blockId,
                                        value: blockId)
            gleanWrapper.recordString(for: GleanMetrics.FxSuggest.advertiser,
                                      value: advertiser)
            gleanWrapper.recordString(for: GleanMetrics.FxSuggest.iabCategory,
                                      value: iabCategory)

            if let impressionReportingURL {
                gleanWrapper.recordUrl(for: GleanMetrics.FxSuggest.reportingUrl,
                                       value: impressionReportingURL)
            }
        case .wikipedia:
            gleanWrapper.recordString(for: GleanMetrics.FxSuggest.advertiser,
                                      value: EventInfo.wikipediaAdvertiser.rawValue)
        }

        gleanWrapper.submit(ping: GleanMetrics.Pings.shared.fxSuggest)
    }
}
