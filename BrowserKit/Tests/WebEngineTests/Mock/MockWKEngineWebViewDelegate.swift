// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
@testable import WebEngine

class MockWKEngineWebViewDelegate: WKEngineWebViewDelegate {
    var loadingChangedCalled = 0
    var progressChangedCalled = 0
    var urlChangedCalled = 0
    var titleChangedCalled = 0
    var canGoBackChangedCalled = 0
    var canGoForwardChangedCalled = 0
    var hasOnlySecureBrowserChangedCalled = 0
    var handleContentSizeChangeCalled = 0

    func tabWebView(_ webView: WKEngineWebView, findInPageSelection: String) {}
    
    func tabWebView(_ webView: WKEngineWebView, searchSelection: String) {}
    
    func tabWebViewInputAccessoryView(_ webView: WKEngineWebView) -> EngineInputAccessoryView {
        return .default
    }
    
    func loadingChanged(loading: Bool) {
        loadingChangedCalled += 1
    }
    
    func progressChanged() {
        progressChangedCalled += 1
    }
    
    func urlChanged() {
        urlChangedCalled += 1
    }
    
    func titleChanged(title: String) {
        titleChangedCalled += 1
    }
    
    func canGoBackChanged(canGoBack: Bool) {
        canGoBackChangedCalled += 1
    }
    
    func canGoForwardChanged(canGoForward: Bool) {
        canGoForwardChangedCalled += 1
    }
    
    func hasOnlySecureBrowserChanged() {
        hasOnlySecureBrowserChangedCalled += 1
    }

    func handleContentSizeChange(newSize: CGSize) {
        handleContentSizeChangeCalled += 1
    }
}
