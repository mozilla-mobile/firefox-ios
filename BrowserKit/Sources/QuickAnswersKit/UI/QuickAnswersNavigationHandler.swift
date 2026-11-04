// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Identifies the possible navigation types for `QuickAnswersViewController`
public enum QuickAnswersNavigationType: Equatable {
    /// Navigates to the specified URL.
    case url(URL)
    /// Performs a search with the specified query string.
    case searchResult(String)
    /// Opens the specified URL in a new tab, which is selected.
    case newTab(URL, isPrivate: Bool)
}

/// Handles navigation for the `QuickAnswersViewController`
@MainActor
public protocol QuickAnswersNavigationHandler: AnyObject {
    /// Dismisses the interface and optionally performs a navigation action.
    ///
    /// - Parameter navigationType: The navigation action to perform after dismissal.
    ///   Pass `nil` when dismissing via the close button without navigation.
    func dismissQuickAnswers(with navigationType: QuickAnswersNavigationType?)

    /// Called instead of `dismissQuickAnswers(with:)` when a snapshot was saved so the user can return to the answer.
    func parkQuickAnswers(with navigationType: QuickAnswersNavigationType)

    /// Bookmarks a citation, staying in Quick Answers.
    func bookmarkCitation(url: URL, title: String)
}
