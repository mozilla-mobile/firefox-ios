// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

// MARK: MockWKWebView
class MockWKWebView: WKWebView {
    var overridenURL: URL
    var didLoad: (() -> Void)?

    init(_ url: URL) {
        self.overridenURL = url
        super.init(frame: .zero, configuration: WKWebViewConfiguration())
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    override var url: URL {
        return overridenURL
    }

    // Simulate async load behavior
    override func load(_ request: URLRequest) -> WKNavigation? {
        DispatchQueue.main.async {
            self.overridenURL = request.url ?? self.overridenURL
            self.didLoad?()
        }
        return nil
    }
}

// MARK: - WKScriptMessageMock
class MockWKScriptMessage: WKScriptMessage {
    let overridenBody: Any
    let overridenName: String
    let overridenFrameInfo: WKFrameInfo

    init(name: String, body: Any, frameInfo: WKFrameInfo) {
        overridenBody = body
        overridenName = name
        overridenFrameInfo = frameInfo
    }

    override var body: Any {
        return overridenBody
    }

    override var name: String {
        return overridenName
    }

    override var frameInfo: WKFrameInfo {
        return overridenFrameInfo
    }
}

// MARK: - MockWKURLSchemeTask

/// Minimal fake WKURLSchemeTask used to capture callbacks.
final class MockWKURLSchemeTask: NSObject, WKURLSchemeTask {
    private let _request: URLRequest
    var request: URLRequest { _request }

    init(request: URLRequest) {
        self._request = request
    }

    private(set) var receivedResponses: [URLResponse] = []
    private(set) var receivedBodies: [Data] = []
    private(set) var finishCallCount = 0
    private(set) var failedErrors: [Error] = []

    var onResponse: (() -> Void)?
    var onBody: (() -> Void)?
    var onFinish: (() -> Void)?
    var onFail: (() -> Void)?

    func didReceive(_ response: URLResponse) {
        receivedResponses.append(response)
        onResponse?()
    }

    func didReceive(_ data: Data) {
        receivedBodies.append(data)
        onBody?()
    }

    func didFinish() {
        finishCallCount += 1
        onFinish?()
    }

    func didFailWithError(_ error: Error) {
        failedErrors.append(error)
        onFail?()
    }
}
