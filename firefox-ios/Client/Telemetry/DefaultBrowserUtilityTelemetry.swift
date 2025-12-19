// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct DefaultBrowserUtilityTelemetry {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func recordAppIsDefaultBrowser(_ isDefaultBrowser: Bool) {
        gleanWrapper.setBoolean(for: GleanMetrics.App.defaultBrowser, value: isDefaultBrowser)
    }

    func recordIsUserChoiceScreenAcquisition(_ isChoiceScreenAcquisition: Bool) {
        gleanWrapper.setBoolean(for: GleanMetrics.App.choiceScreenAcquisition, value: isChoiceScreenAcquisition)
    }

    func recordDefaultBrowserAPIError(
        errorDescription: String,
        retryDate: Date?,
        lastProvidedDate: Date?,
        apiQueryCount: Int?
    ) {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let extra = GleanMetrics.App.DefaultBrowserApiErrorExtra(
            apiQueryCount: apiQueryCount.map { Int32($0) },
            errorDescription: errorDescription,
            lastProvidedDate: lastProvidedDate.map { dateFormatter.string(from: $0) },
            retryDate: retryDate.map { dateFormatter.string(from: $0) }
        )

        gleanWrapper.recordEvent(for: GleanMetrics.App.defaultBrowserApiError, extras: extra)
    }
}
