// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

/// Protocol each script injected into a WKEngineSession needs to follow.
/// Scripts are injected through the `WKContentScriptManager`
protocol WKContentScript {
    static func name() -> String

    func scriptMessageHandlerNames() -> [String]

    func userContentController(didReceiveMessage message: Any)

    func prepareForDeinit()
}

extension WKContentScript {
    // By default most script don't need a `prepareForDeinit`
    func prepareForDeinit() {}
}
