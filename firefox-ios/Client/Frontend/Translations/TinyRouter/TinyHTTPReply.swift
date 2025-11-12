// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A tiny container for data to send back as a response (e.g. for WKWebView scheme handler).
public struct TinyHTTPReply {
    /// Optional prebuilt response (status line + headers).
    let httpResponse: HTTPURLResponse?
    /// Raw bytes to return to the webview.
    let body: Data
}
