// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

/// Type-specific information to record in telemetry about a visible search
/// suggestion.
enum SearchViewVisibleSuggestionTelemetryInfo {
    /// Information to record in telemetry about a visible sponsored or
    /// non-sponsored suggestion from Firefox Suggest.
    ///
    /// `position` is the 1-based position of this suggestion relative to the
    /// top of the search results view. `didTap` indicates if the user
    /// tapped on this suggestion.
    case firefoxSuggestion(
        RustFirefoxSuggestionTelemetryInfo,
        position: Int,
        didTap: Bool
    )
}
