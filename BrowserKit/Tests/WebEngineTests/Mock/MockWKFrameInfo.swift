//
//  MockWKFrameInfo.swift
//  BrowserKit
//
//  Created by Daniel Dervishi on 2025-02-25.
//
import Foundation
import WebKit
@testable import WebEngine

class MockWKFrameInfo: WKFrameInfo {
    let overridenWebView: WKWebView?
    let overridenIsMainFrame: Bool

    init(webView: MockWKWebView? = nil, isMainFrame: Bool = true) {
        overridenWebView = webView
        overridenIsMainFrame = isMainFrame
    }

    override var isMainFrame: Bool {
        return isMainFrame
    }

    override var webView: WKWebView? {
        return overridenWebView
    }
}
