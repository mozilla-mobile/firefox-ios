// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

/// Represents one endpoint of a `WebViewBridge`.
/// This is an abstraction so it’s easy to test and not have to use a real `WKWebView` in tests.
/// NOTE: This is main actor because on production code this will be dealing with real webviews.
@MainActor
protocol BridgeEndpoint: AnyObject {
    var handlerName: String { get }
    /// Sends a JSON string to this endpoint's JavaScript context.
    func send(json: String)
    /// Called by a `Bridge` to attach `WKScriptMessageHandler`.
    /// For tests, this will be a no-op..
    func registerScriptHandler(_ handler: WKScriptMessageHandler)
    /// Called by a `Bridge`  to remove a `WKScriptMessageHandler`.
    /// For tests, this will be a no-op..
    func unregisterScriptHandler()
}
