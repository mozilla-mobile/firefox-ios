// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// An `EngineURL` is the required URL type to load inside an `EngineSession`.
/// This basically forces anyone trying to load a URL inside the web engine to consider `BrowsingContext`.
public struct EngineURL {
    let url: URL

    init?(browsingContext: BrowsingContext,
          securityManager: SecurityManager = DefaultSecurityManager()) {
        guard securityManager.canNavigateWith(browsingContext: browsingContext) == .allowed else { return nil }

        guard let url = URL(string: browsingContext.url) else { return nil }

        self.url = url
    }
}
