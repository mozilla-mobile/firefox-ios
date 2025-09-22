// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol WKJavscriptAlertStore: Actor {
    func add(_ alert: WKJavaScriptAlertInfo)
    func popFirst() -> WKJavaScriptAlertInfo?
}

actor DefaultJavscriptAlertStore: WKJavscriptAlertStore {
    private var alerts: [WKJavaScriptAlertInfo] = []
    
    func add(_ alert: WKJavaScriptAlertInfo) {
        alerts.append(alert)
    }
    
    func popFirst() -> WKJavaScriptAlertInfo? {
        return alerts.popLast()
    }
}
