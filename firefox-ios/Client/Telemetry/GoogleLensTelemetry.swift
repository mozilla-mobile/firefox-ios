// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct GoogleLensSearchState {
    let source: GoogleLensTelemetry.Source
    var httpStatusCode: Int?

    init(source: GoogleLensTelemetry.Source, httpStatusCode: Int? = nil) {
        self.source = source
        self.httpStatusCode = httpStatusCode
    }
}

struct GoogleLensTelemetry {
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
}
