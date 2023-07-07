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
        // iOS 14.3 is required here because of a webkit bug in lower iOS versions with this API
        if #available(iOS 14.3, *) {
            self.evaluateJavaScript(javascript, in: nil, in: .defaultClient, completionHandler: { _ in })
        } else {
            self.evaluateJavaScript(javascript)
        }
    }

    /// This calls different WebKit evaluateJavaScript functions depending on iOS version with a completion that passes a tuple with optional data or an optional error
    ///  - If iOS14 or higher, evaluates Javascript in a .defaultClient sandboxed content world
    ///  - If below iOS14, evaluates Javascript without sandboxed environment
    /// - Parameters:
    ///     - javascript: String representing javascript to be evaluated
    ///     - completion: Tuple containing optional data and an optional error
    public func evaluateJavascriptInDefaultContentWorld(_ javascript: String, _ frame: WKFrameInfo? = nil, _ completion: @escaping (Any?, Error?) -> Void) {
        // iOS 14.3 is required here because of a webkit bug in lower iOS versions with this API
        if #available(iOS 14.3, *) {
            self.evaluateJavaScript(javascript, in: frame, in: .defaultClient) { result in
                switch result {
                case .success(let value):
                    completion(value, nil)
                case .failure(let error):
                    completion(nil, error)
                }
            }
        } else {
            self.evaluateJavaScript(javascript) { data, error  in
                completion(data, error)
            }
        }
    }
}

extension WKUserContentController {
    public func addInDefaultContentWorld(scriptMessageHandler: WKScriptMessageHandler, name: String) {
        // iOS 14.3 is required here because of a webkit bug in lower iOS versions with this API
        if #available(iOS 14.3, *) {
            add(scriptMessageHandler, contentWorld: .defaultClient, name: name)
        } else {
            add(scriptMessageHandler, name: name)
        }
    }

    public func addInPageContentWorld(scriptMessageHandler: WKScriptMessageHandler, name: String) {
        // iOS 14.3 is required here because of a webkit bug in lower iOS versions with this API
        if #available(iOS 14.3, *) {
            add(scriptMessageHandler, contentWorld: .page, name: name)
        } else {
            add(scriptMessageHandler, name: name)
        }
    }
}

extension WKUserScript {
    public class func createInDefaultContentWorld(source: String, injectionTime: WKUserScriptInjectionTime, forMainFrameOnly: Bool) -> WKUserScript {
        // iOS 14.3 is required here because of a webkit bug in lower iOS versions with this API
        if #available(iOS 14.3, *) {
            return WKUserScript(source: source, injectionTime: injectionTime, forMainFrameOnly: forMainFrameOnly, in: .defaultClient)
        } else {
            return WKUserScript(source: source, injectionTime: injectionTime, forMainFrameOnly: forMainFrameOnly)
        }
    }

    public class func createInPageContentWorld(source: String, injectionTime: WKUserScriptInjectionTime, forMainFrameOnly: Bool) -> WKUserScript {
        // iOS 14.3 is required here because of a webkit bug in lower iOS versions with this API
        if #available(iOS 14.3, *) {
            return WKUserScript(source: source, injectionTime: injectionTime, forMainFrameOnly: forMainFrameOnly, in: .page)
        } else {
            return WKUserScript(source: source, injectionTime: injectionTime, forMainFrameOnly: forMainFrameOnly)
        }
    }
}
