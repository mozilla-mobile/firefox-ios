// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct GoogleLensSearchState {
    let source: GoogleLensTelemetry.Source
    let searchTimerId: GleanTimerId?
    var httpStatusCode: Int?

    init(source: GoogleLensTelemetry.Source,
         searchTimerId: GleanTimerId? = nil,
         httpStatusCode: Int? = nil) {
        self.source = source
        self.searchTimerId = searchTimerId
        self.httpStatusCode = httpStatusCode
    }
}

struct GoogleLensTelemetry: Sendable {
    enum Source: String {
        case camera
        case photoPicker
        case contextMenu
    }

    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func googleLensEnabled(_ enabled: Bool) {
        gleanWrapper.setBoolean(for: GleanMetrics.UserSearch.googleLensEnabled, value: enabled)
    }

    func searchCompleted(source: Source, succeeded: Bool, httpStatusCode: Int?) {
        let extra = GleanMetrics.GoogleLens.SearchCompletedExtra(
            httpStatus: httpStatusCode.map(Int32.init),
            source: source.rawValue,
            succeeded: succeeded
        )
        gleanWrapper.recordEvent(for: GleanMetrics.GoogleLens.searchCompleted, extras: extra)
    }

    func startSearchTimer(source: Source) -> GleanTimerId {
        return gleanWrapper.startTiming(for: searchTimeMetric(for: source))
    }

    func cancelSearchTimer(source: Source, timerId: GleanTimerId) {
        gleanWrapper.cancelTiming(for: searchTimeMetric(for: source),
                                  timerId: timerId)
    }

    func stopSearchTimer(source: Source, timerId: GleanTimerId) {
        gleanWrapper.stopAndAccumulateTiming(for: searchTimeMetric(for: source),
                                             timerId: timerId)
    }

    private func searchTimeMetric(for source: Source) -> TimingDistributionMetricType {
        switch source {
        case .camera, .photoPicker:
            return GleanMetrics.GoogleLens.toolbarButtonSearchTime
        case .contextMenu:
            return GleanMetrics.GoogleLens.webpageImageSearchTime
        }
    }
}
