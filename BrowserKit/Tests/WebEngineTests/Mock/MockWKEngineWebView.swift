// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import WebKit
@testable import WebEngine

class MockWKEngineWebView: WKEngineWebView {
    var configuration = WKWebViewConfiguration()
    var interactionState: Any?
    var scrollView = UIScrollView()
    var url: URL?
    var navigationDelegate: WKNavigationDelegate?
    var allowsBackForwardNavigationGestures = true
    var allowsLinkPreview = true
    var backgroundColor: UIColor? = .black
    var isInspectable = true

    // MARK: Test properties
    var loadCalled = 0
    var loadFileURLCalled = 0
    var reloadFromOriginCalled = 0
    var replaceLocationCalled = 0
    var stopLoadingCalled = 0
    var goBackCalled = 0
    var goForwardCalled = 0
    var removeAllUserScriptsCalled = 0
    var removeFromSuperviewCalled = 0
    var addObserverCalled = 0
    var removeObserverCalled = 0

    var loadFileReadAccessURL: URL?

    required init?(frame: CGRect,
                   configurationProvider: WKEngineConfigurationProvider) {}

    func load(_ request: URLRequest) -> WKNavigation? {
        url = request.url
        loadCalled += 1
        return nil
    }

    func loadFileURL(_ URL: URL, allowingReadAccessTo readAccessURL: URL) -> WKNavigation? {
        url = URL
        loadFileReadAccessURL = readAccessURL
        loadFileURLCalled += 1
        return nil
    }

    func reloadFromOrigin() -> WKNavigation? {
        reloadFromOriginCalled += 1
        return nil
    }

    func replaceLocation(with url: URL) {
        self.url = url
        replaceLocationCalled += 1
    }

    func stopLoading() {
        stopLoadingCalled += 1
    }

    func goBack() -> WKNavigation? {
        goBackCalled += 1
        return nil
    }

    func goForward() -> WKNavigation? {
        goForwardCalled += 1
        return nil
    }

    func removeAllUserScripts() {
        removeAllUserScriptsCalled += 1
    }

    func removeFromSuperview() {
        removeFromSuperviewCalled += 1
    }

    func addObserver(_ observer: NSObject,
                     forKeyPath keyPath: String,
                     options: NSKeyValueObservingOptions,
                     context: UnsafeMutableRawPointer?) {
        addObserverCalled += 1
    }

    func removeObserver(_ observer: NSObject,
                        forKeyPath keyPath: String) {
        removeObserverCalled += 1
    }
}
