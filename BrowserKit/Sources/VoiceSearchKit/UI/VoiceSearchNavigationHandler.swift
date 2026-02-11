// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Handles navigation for the `VoiceSearchViewController`
@MainActor
public protocol VoiceSearchNavigationHandler: AnyObject {
    func dismissVoiceSearch()

    func navigateToURL(_ url: URL)

    func navigateToSearchResult(_ query: String)
}
