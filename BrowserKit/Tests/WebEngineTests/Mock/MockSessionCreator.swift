// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit
import WebEngine

class MockPopupThrottler: PopupThrottler {
    var canShowAlertCalled = 0
    var stubCanShowAlert = true
    var willShowAlertCalled = 0

    func canShowAlert(type: PopupType) -> Bool {
        canShowAlertCalled += 1
        return stubCanShowAlert
    }

    func willShowAlert(type: PopupType) {
        willShowAlertCalled += 1
    }
}

class MockWKJavaScriptAlertStore: WKJavaScriptAlertStore {
    var cancelQueuedAlertsCalled = 0
    var queueJavascriptAlertPromptCalled = 0
    var dequeueJavascriptAlertPromptCalled = 0
    var stubDequeueJavascriptAlertPrompt: (any WKJavaScriptAlertInfo)?
    var hasJavascriptAlertPromptCalled = 0
    var stubHasJavascriptAlertPrompt = false
    var popupThrottler: PopupThrottler

    init(popupThrottler: PopupThrottler) {
        self.popupThrottler = popupThrottler
    }

    func cancelQueuedAlerts() {
        cancelQueuedAlertsCalled += 1
    }

    func queueJavascriptAlertPrompt(_ alert: any WKJavaScriptAlertInfo) {
        queueJavascriptAlertPromptCalled += 1
    }

    func dequeueJavascriptAlertPrompt() -> (any WKJavaScriptAlertInfo)? {
        dequeueJavascriptAlertPromptCalled += 1
        return stubDequeueJavascriptAlertPrompt
    }

    func hasJavascriptAlertPrompt() -> Bool {
        hasJavascriptAlertPromptCalled += 1
        return stubHasJavascriptAlertPrompt
    }
}

class MockSessionCreator: WKEngineClientBridge {
    var createPopupSessionCalled = 0
    var alertStoreCalled = 0
    var isSessionActiveCalled = 0
    var stubIsSessionActive = true
    var currentActiveStoreCalled = 0
    var stubStore: WKJavaScriptAlertStore?

    func createPopupSession(configuration: WKWebViewConfiguration, parent: WKWebView) -> WKWebView? {
        createPopupSessionCalled += 1
        return parent
    }

    func alertStore(for webView: WKWebView) -> (any WKJavaScriptAlertStore)? {
        alertStoreCalled += 1
        return stubStore
    }

    func isSessionActive(for webView: WKWebView) -> Bool {
        isSessionActiveCalled += 1
        return stubIsSessionActive
    }

    func currentActiveStore() -> (any WKJavaScriptAlertStore)? {
        currentActiveStoreCalled += 1
        return stubStore
    }
}
