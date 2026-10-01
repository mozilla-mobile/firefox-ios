// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

protocol ContentScriptDelegate: AnyObject {
    func contentScriptDidSendEvent(_ event: ScriptEvent)
}

/// An Event triggered from an injected script into a `WKWebView`
enum ScriptEvent: Equatable {
    case fieldFocusChanged(Bool)
    case trackedAdsFoundOnPage(provider: String, urls: [String])
    case trackedAdsClickedOnPage(provider: String)
}
