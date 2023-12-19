// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

/// Abstraction on top of `WKWebViewConfiguration`
protocol WKEngineConfiguration {
    var userContentController: WKUserContentController { get set }
    var allowsInlineMediaPlayback: Bool { get set }
}

extension WKWebViewConfiguration: WKEngineConfiguration {}
