// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import WebKit
@testable import WebEngine

class MockWKEngineWebView: UIView, WKEngineWebView {
    var delegate: WKEngineWebViewDelegate?
    var uiDelegate: WKUIDelegate?
    var navigationDelegate: WKNavigationDelegate?

    var engineConfiguration: WKEngineConfiguration
    var interactionState: Any?
    var engineScrollView: WKScrollView! = MockEngineScrollView()
    var url: URL?
    var title: String?
    var hasOnlySecureContent = false
    var allowsBackForwardNavigationGestures = true
    var allowsLinkPreview = true
    var isInspectable = true

    var estimatedProgress: Double = 0
    var canGoBack = false
    var canGoForward = false

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
    var evaluateJavaScriptCalled = 0
    var savedJavaScript: String?
    var javascriptResult: (Result<Any, Error>)?
    var pageZoom: CGFloat = 1.0

    var loadFileReadAccessURL: URL?

    required init?(frame: CGRect,
                   configurationProvider: WKEngineConfigurationProvider) {
        self.engineConfiguration = configurationProvider.createConfiguration()
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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

    override func removeFromSuperview() {
        removeFromSuperviewCalled += 1
    }

    override func addObserver(_ observer: NSObject,
                              forKeyPath keyPath: String,
                              options: NSKeyValueObservingOptions,
                              context: UnsafeMutableRawPointer?) {
        addObserverCalled += 1
    }

    override func removeObserver(_ observer: NSObject,
                                 forKeyPath keyPath: String) {
        removeObserverCalled += 1
    }

    func evaluateJavaScript(_ javaScript: String,
                            in frame: WKFrameInfo?,
                            in contentWorld: WKContentWorld,
                            completionHandler: ((Result<Any, Error>) -> Void)?) {
        evaluateJavaScriptCalled += 1
        savedJavaScript = javaScript

        if let javascriptResult {
            completionHandler?(javascriptResult)
        }
    }

    override func value(forKey key: String) -> Any? {
        if key == "viewScale" {
            return self.pageZoom
        }
        return super.value(forKey: key)
    }

    override func setValue(_ value: Any?, forKey key: String) {
        if key == "viewScale", let zoomValue = value as? CGFloat {
            self.pageZoom = zoomValue
            return
        }
        super.setValue(value, forKey: key)
    }
}
