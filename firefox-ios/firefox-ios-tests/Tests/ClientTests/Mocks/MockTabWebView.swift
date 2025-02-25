// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit
import Common
import Shared
@testable import Client

final class MockTabWebView: TabWebView {
    var loadCalled = 0
    var loadedRequest: URLRequest?
    var goBackCalled = 0
    var goForwardCalled = 0
    var reloadFromOriginCalled = 0
    var stopLoadingCalled = 0
    var mockTitle: String?
    var loadedURL: URL?

    override var title: String? {
        return mockTitle
    }

    override var url: URL? {
        return loadedURL
    }

    override init(frame: CGRect, configuration: WKWebViewConfiguration, windowUUID: WindowUUID) {
        super.init(frame: frame, configuration: configuration, windowUUID: windowUUID)
    }

    init(tab: Tab) {
        super.init(frame: .zero, configuration: WKWebViewConfiguration(), windowUUID: .XCTestDefaultUUID)
        // Simulating the observer setup is required to use this mock because in production
        // the observers are set up in Tab.createWebView() which we don't call during test
        // and the observers are removed every time we call Tab.deinit(), so an error occurs
        // if we don't first set up the observers manually here.
        simulateObserverSetup(target: tab)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func simulateObserverSetup(target: NSObject) {
        addObserver(target, forKeyPath: KVOConstants.URL.rawValue, options: .new, context: nil)
        addObserver(target, forKeyPath: KVOConstants.title.rawValue, options: .new, context: nil)
        addObserver(target, forKeyPath: KVOConstants.hasOnlySecureContent.rawValue, context: nil)
    }

    override func load(_ request: URLRequest) -> WKNavigation? {
        loadCalled += 1
        loadedRequest = request
        loadedURL = request.url
        return nil
    }

    override func reloadFromOrigin() -> WKNavigation? {
        reloadFromOriginCalled += 1
        return nil
    }

    override func goBack() -> WKNavigation? {
        goBackCalled += 1
        return nil
    }

    override func goForward() -> WKNavigation? {
        goForwardCalled += 1
        return nil
    }

    override func stopLoading() {
        stopLoadingCalled += 1
    }
}
