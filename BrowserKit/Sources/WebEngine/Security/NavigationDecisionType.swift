// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The navigation decision given by the Security Manager for a given BrowsingContext
public enum NavigationDecisionType {
    /// The Browsing Context is permitted and will be navigated to
    case allowed

    /// The Browser Context was not permitted, the search will be made as a search term instead
    case refused

    /// The Browser Context permits this URL, but the navigation is handled by the 
    /// Client probably by opening a third-party app
    case clientHandled
}
