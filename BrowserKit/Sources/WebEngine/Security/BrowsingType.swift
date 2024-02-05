// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

/// The BrowsingType determines what type of BrowsingContext we are in
public enum BrowsingType {
    /// External navigation refers to external deep links, such as `firefox://open-url` scheme
    case externalNavigation

    /// Internal navigation refers to navigation triggered internally by the user through entering a 
    /// URL in the URL bar manually for instance.
    case internalNavigation

    /// Redirection navigation refers to calls through the navigation delegation `WKNavigationDelegate`
    /// This should not never be called by the Client
    case redirectionNavigation(type: WKNavigationType)
}
