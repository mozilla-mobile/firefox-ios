// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct TermsOfUseTelemetry {
    let termsOfUseVersion: Int64 = 4
    let termsOfUseSurface = "bottom_sheet"

    func termsOfUseBottomSheetDisplayed() {
        let impressionExtra = GleanMetrics.Termsofuse.ImpressionExtra(
            surface: termsOfUseSurface,
            touVersion: String(termsOfUseVersion)
        )
        GleanMetrics.Termsofuse.impression.record(impressionExtra)
    }

    func termsOfUseAcceptButtonTapped() {
        let acceptedExtra = GleanMetrics.Termsofuse.AcceptedExtra(
            surface: termsOfUseSurface,
            touVersion: String(termsOfUseVersion)
        )
        GleanMetrics.Termsofuse.accepted.record(acceptedExtra)
        GleanMetrics.Termsofuse.version.set(termsOfUseVersion)
        GleanMetrics.Termsofuse.date.set(Date())
    }
}
