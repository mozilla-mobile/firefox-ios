// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit
import Foundation

extension WKUserScript {
    class func createInDefaultContentWorld(
        source: String,
        injectionTime: WKUserScriptInjectionTime,
        forMainFrameOnly: Bool
    ) -> WKUserScript {
        return WKUserScript(
            source: source,
            injectionTime: injectionTime,
            forMainFrameOnly: forMainFrameOnly,
            in: .defaultClient
        )
    }

    class func createInPageContentWorld(
        source: String,
        injectionTime: WKUserScriptInjectionTime,
        forMainFrameOnly: Bool
    ) -> WKUserScript {
        return WKUserScript(
            source: source,
            injectionTime: injectionTime,
            forMainFrameOnly: forMainFrameOnly,
            in: .page
        )
    }
}
