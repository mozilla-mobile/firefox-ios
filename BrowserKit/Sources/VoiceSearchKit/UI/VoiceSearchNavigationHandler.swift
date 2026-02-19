// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Identifies the possible navigation types for `VoiceSearchViewController`
public enum VoiceSearchNavigationType: Equatable {
    /// Navigates to the specified URL.
    case url(URL)
    /// Performs a search with the specified query string.
    case searchResult(String)
}

/// Handles navigation for the `VoiceSearchViewController`
@MainActor
public protocol VoiceSearchNavigationHandler: AnyObject {
    /// Dismisses the voice search interface and optionally performs a navigation action.
    ///
    /// - Parameter navigationType: The navigation action to perform after dismissal.
    ///   Pass `nil` when dismissing via the close button without navigation.
    func dismissVoiceSearch(with navigationType: VoiceSearchNavigationType?)
}
