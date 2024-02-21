// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

// MARK: WKNavigationActionMock
class WKNavigationActionMock: WKNavigationAction {
    var overridenTargetFrame: WKFrameInfoMock?

    override var targetFrame: WKFrameInfo? {
        return overridenTargetFrame
    }
}

// MARK: WKFrameInfoMock
class WKFrameInfoMock: WKFrameInfo {
    let overridenSecurityOrigin: WKSecurityOrigin
    let overridenWebView: WKWebView?
    let overridenTargetFrame: Bool

    init(webView: WKWebViewMock? = nil, frameURL: URL? = nil, isMainFrame: Bool? = false) {
        overridenSecurityOrigin = WKSecurityOriginMock.new(frameURL)
        overridenWebView = webView
        overridenTargetFrame = isMainFrame ?? false
    }

    override var isMainFrame: Bool {
        return overridenTargetFrame
    }

    override var securityOrigin: WKSecurityOrigin {
        return overridenSecurityOrigin
    }

    override var webView: WKWebView? {
        return overridenWebView
    }
}

// MARK: WKSecurityOriginMock
class WKSecurityOriginMock: WKSecurityOrigin {
    var overridenProtocol: String!
    var overridenHost: String!
    var overridenPort: Int!

    class func new(_ url: URL?) -> WKSecurityOriginMock {
        // Dynamically allocate a WKSecurityOriginMock instance because 
        // the initializer for WKSecurityOrigin is unavailable
        //  https://github.com/WebKit/WebKit/blob/52222cf447b7215dd9bcddee659884f704001827/Source/WebKit/UIProcess/API/Cocoa/WKSecurityOrigin.h#L40
        guard let instance = self.perform(NSSelectorFromString("alloc"))?.takeUnretainedValue()
                as? WKSecurityOriginMock
        else {
            fatalError("Could not allocate WKSecurityOriginMock instance")
        }
        instance.overridenProtocol = url?.scheme ?? ""
        instance.overridenHost = url?.host ?? ""
        instance.overridenPort = url?.port ?? 0
        return instance
    }

    override var `protocol`: String { overridenProtocol }
    override var host: String { overridenHost }
    override var port: Int { overridenPort }
}

// MARK: WKWebViewMock
class WKWebViewMock: WKWebView {
    var overridenURL: URL

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
}

// MARK: - WKScriptMessageMock
class WKScriptMessageMock: WKScriptMessage {
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
