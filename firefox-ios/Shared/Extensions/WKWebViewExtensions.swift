// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

extension WKWebView {
    /// This calls different WebKit evaluateJavaScript functions depending on iOS version
    ///  - If iOS14 or higher, evaluates Javascript in a .defaultClient sandboxed content world
    ///  - If below iOS14, evaluates Javascript without sandboxed environment
    /// - Parameters:
    ///     - javascript: String representing javascript to be evaluated
    public func evaluateJavascriptInDefaultContentWorld(_ javascript: String) {
        self.evaluateJavaScript(javascript, in: nil, in: .defaultClient, completionHandler: { _ in })
    }

    /// This calls different WebKit evaluateJavaScript functions depending on iOS version with a completion that passes a tuple with optional data or an optional error
    ///  - If iOS14 or higher, evaluates Javascript in a .defaultClient sandboxed content world
    ///  - If below iOS14, evaluates Javascript without sandboxed environment
    /// - Parameters:
    ///     - javascript: String representing javascript to be evaluated
    ///     - completion: Tuple containing optional data and an optional error
    public func evaluateJavascriptInDefaultContentWorld(_ javascript: String, _ frame: WKFrameInfo? = nil, _ completion: @escaping (Any?, Error?) -> Void) {
        self.evaluateJavaScript(javascript, in: frame, in: .defaultClient) { result in
            switch result {
            case .success(let value):
                completion(value, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
}

extension WKUserContentController {
    public func addInDefaultContentWorld(scriptMessageHandler: WKScriptMessageHandler, name: String) {
        add(scriptMessageHandler, contentWorld: .defaultClient, name: name)
    }

    public func addInPageContentWorld(scriptMessageHandler: WKScriptMessageHandler, name: String) {
        add(scriptMessageHandler, contentWorld: .page, name: name)
    }
}

extension WKUserScript {
    public class func createInDefaultContentWorld(source: String, injectionTime: WKUserScriptInjectionTime, forMainFrameOnly: Bool) -> WKUserScript {
        return WKUserScript(source: source, injectionTime: injectionTime, forMainFrameOnly: forMainFrameOnly, in: .defaultClient)
    }

    public class func createInPageContentWorld(source: String, injectionTime: WKUserScriptInjectionTime, forMainFrameOnly: Bool) -> WKUserScript {
        return WKUserScript(source: source, injectionTime: injectionTime, forMainFrameOnly: forMainFrameOnly, in: .page)
    }
}
