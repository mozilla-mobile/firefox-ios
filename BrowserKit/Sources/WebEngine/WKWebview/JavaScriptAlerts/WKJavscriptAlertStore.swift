// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@MainActor
public protocol WKJavscriptAlertStore {
    var popupThrottler: WKPopupThrottler { get }

    func cancelQueuedAlerts()

    func queueJavascriptAlertPrompt(_ alert: WKJavaScriptAlertInfo)

    func dequeueJavascriptAlertPrompt() -> WKJavaScriptAlertInfo?

    func hasJavascriptAlertPrompt() -> Bool
}
