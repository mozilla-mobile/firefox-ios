// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The navigation decision given by the Security Manager for a given BrowsingContext
public enum NavigationDecisionType {
    /// The Browsing Context is permitted
    case allowed

    /// The Browser Context was not permitted
    case refused

    /// The Browsing Context needs the user input before we can navigate to it
    case needsUserInput
}
