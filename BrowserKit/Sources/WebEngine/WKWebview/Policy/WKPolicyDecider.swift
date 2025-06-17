// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

/// An object that decides the policy for a navigation request by `WebKit`'s delegate methods.
public protocol WKPolicyDecider {
    /// The next decider in the chain, that can eventually respond with a `WKPolicy`
    /// when this decider is not able to handle it.
    var nextDecider: WKPolicyDecider? { get set }

    func policyForNavigation(action: NavigationAction) -> WKPolicy

    func policyForNavigation(response: NavigationResponse) -> WKPolicy

    func policyForPopupNavigation(action: NavigationAction) -> WKPolicy
}

public protocol NavigationAction {
    var url: URL? { get }
    var request: URLRequest { get }
    var navigationType: WKNavigationType { get }

    var sourceFrameInfo: FrameInfo { get }
    var targetFrameInfo: FrameInfo? { get }
}

public protocol NavigationResponse {
    var url: URL? { get }
    var response: URLResponse { get }
    var isForMainFrame: Bool { get }
}

extension WKNavigationAction: NavigationAction {
    public var sourceFrameInfo: any FrameInfo {
        return sourceFrame
    }

    public var targetFrameInfo: (any FrameInfo)? {
        return targetFrame
    }

    public var url: URL? {
        return request.url
    }
}

extension WKNavigationResponse: NavigationResponse {
    public var url: URL? {
        return response.url
    }
}

public protocol FrameInfo {
    var isMainFrame: Bool { get }
    var request: URLRequest { get }
}

extension WKFrameInfo: FrameInfo {
}
