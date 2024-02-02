// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The SecurityManager takes in a BrowsingContext to determine if it's safe or not to navigate to a certain URL
public protocol SecurityManager {
    func canNavigateWith(browsingContext: BrowsingContext) -> NavigationDecisionType
}

public class DefaultSecurityManager: SecurityManager {
    public func canNavigateWith(browsingContext: BrowsingContext) -> NavigationDecisionType {
        return .allowed // Laurie
    }
}
