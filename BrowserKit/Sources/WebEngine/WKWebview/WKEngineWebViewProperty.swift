// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Properties of the `WKWebView` with their current value, used to notify change in the `WKWebView` state.
enum WKEngineWebViewProperty: Equatable {
    case loading(Bool)
    case estimatedProgress(Double)
    case URL(URL?)
    case title(String)
    case canGoBack(Bool)
    case canGoForward(Bool)
    case contentSize(CGSize)
    case hasOnlySecureContent(Bool)
    case isFullScreen(Bool)
}
