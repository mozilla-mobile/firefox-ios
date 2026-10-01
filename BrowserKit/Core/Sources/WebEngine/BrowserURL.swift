// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

/// An `BrowserURL` is the required URL type to load inside an `EngineSession`.
/// This basically forces anyone trying to load a URL inside the web engine to consider `BrowsingContext`.
public struct BrowserURL {
    let url: URL

    public init?(browsingContext: BrowsingContext,
                 securityManager: SecurityManager = DefaultSecurityManager(),
                 logger: Logger = DefaultLogger.shared) {
        guard securityManager.canNavigateWith(browsingContext: browsingContext) == .allowed
        else {
            logger.log("BrowserURL couldn't be created with current context", level: .info, category: .webview)
            return nil
        }

        self.url = browsingContext.url
    }
}
