// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
@testable import WebEngine

class MockNavigationAction: NavigationAction {
    var sourceFrameInfo: any FrameInfo {
        MockFrameInfo(isMainFrame: isMainFrame, request: request)
    }
    var targetFrameInfo: (any FrameInfo)? {
        MockFrameInfo(isMainFrame: isMainFrame, request: request)
    }
    var navigationType: WKNavigationType
    let url: URL?
    private let isMainFrame: Bool

    var request: URLRequest {
        return URLRequest(url: url!)
    }

    init(url: URL,
         isMainFrame: Bool = true,
         navigationType: WKNavigationType = .other) {
        self.url = url
        self.navigationType = navigationType
        self.isMainFrame = isMainFrame
    }
}

class MockFrameInfo: FrameInfo {
    var isMainFrame: Bool
    var request: URLRequest

    init(isMainFrame: Bool,
         request: URLRequest) {
        self.isMainFrame = isMainFrame
        self.request = request
    }
}
