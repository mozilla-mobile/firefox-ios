// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Constants use to monitor WKEngineWebView changes with KVO
enum WKEngineKVOConstants: String, CaseIterable {
    case loading
    case estimatedProgress
    case URL
    case title
    case canGoBack
    case canGoForward
    case contentSize
    case hasOnlySecureContent
}
