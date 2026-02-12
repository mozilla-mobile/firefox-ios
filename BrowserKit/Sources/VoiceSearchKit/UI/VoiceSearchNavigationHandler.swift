// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Identifies the possible navigation types for `VoiceSearchViewController`
public enum VoiceSearchNavigationType: Equatable {
    /// An option that species an `URL` to navigate to.
    case navigateToURL(URL)
    /// An option that species a search result to navigate to.
    /// The parameter is a `String` which represents the query to search.
    case navigateToSearchResult(String)
}

/// Handles navigation for the `VoiceSearchViewController`
@MainActor
public protocol VoiceSearchNavigationHandler: AnyObject {
    /// Dismisses the `VoiceSearchViewController` with an optional `VoiceSearchNavigationType`.
    ///
    /// When the `navigationType` is nil the dismiss of the controller is done via the close button.
    /// Otherwise the user pressed a search result which is of type `VoiceSearchNavigationType`.
    func dismissVoiceSearch(with navigationType: VoiceSearchNavigationType?)
}
