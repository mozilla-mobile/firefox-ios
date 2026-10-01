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

    /// This evaluates the provided JS in the specified content world
    /// - Parameters:
    ///     - javascript: String representing javascript to be evaluated
    ///     - contentWorld: The content world in which to evaluate the script
    public func evaluateJavascriptInCustomContentWorld(_ javascript: String, in contentWorld: WKContentWorld) {
        self.evaluateJavaScript(javascript, in: nil, in: contentWorld, completionHandler: { _ in })
    }

    /// This calls different WebKit evaluateJavaScript functions depending on iOS version with
    /// a completion that passes a tuple with optional data or an optional error
    ///  - If iOS14 or higher, evaluates Javascript in a .defaultClient sandboxed content world
    ///  - If below iOS14, evaluates Javascript without sandboxed environment
    /// - Parameters:
    ///     - javascript: String representing javascript to be evaluated
    ///     - completion: Tuple containing optional data and an optional error
    public func evaluateJavascriptInDefaultContentWorld(
        _ javascript: String,
        _ frame: WKFrameInfo? = nil,
        _ completion: @MainActor @escaping (Any?, Error?) -> Void
    ) {
        self.evaluateJavaScript(javascript, in: frame, in: .defaultClient) { result in
            switch result {
            case .success(let value):
                completion(value, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }

    /// Use JS to redirect the page without adding a history entry
    public func replaceLocation(with url: URL) {
        let apostropheEncoded = "%27"
        let safeUrl = url.absoluteString.replacingOccurrences(of: "'", with: apostropheEncoded)
        evaluateJavascriptInDefaultContentWorld("location.replace('\(safeUrl)')")
    }

    /// - Parameters:
    ///     - script: String representing javascript to be evaluated
    ///     - arguments: A dictionary of the arguments to pass to the function call
    ///     - completion: Result containing any? data and an error
    public func callAsyncJavaScriptInDefaultContentWorld(_ script: String,
                                                         arguments: [String: Any],
                                                         completion: @escaping (Result<Any?, Error>) -> Void ) {
        self.callAsyncJavaScript(script,
                                 arguments: arguments,
                                 in: nil,
                                 in: .defaultClient) { result in
            switch result {
            case .success(let value):
                completion(.success(value))
            case .failure(let error):
                completion(.failure(error))
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

    public func addInCustomContentWorld(scriptMessageHandler: WKScriptMessageHandler, name: String) {
        add(scriptMessageHandler, contentWorld: .world(name: name), name: name)
    }
}

extension WKUserScript {
    public class func createInDefaultContentWorld(
        source: String,
        injectionTime: WKUserScriptInjectionTime,
        forMainFrameOnly: Bool
    ) -> WKUserScript {
        return WKUserScript(
            source: source,
            injectionTime: injectionTime,
            forMainFrameOnly: forMainFrameOnly,
            in: .defaultClient
        )
    }

    public class func createInPageContentWorld(
        source: String,
        injectionTime: WKUserScriptInjectionTime,
        forMainFrameOnly: Bool
    ) -> WKUserScript {
        return WKUserScript(
            source: source,
            injectionTime: injectionTime,
            forMainFrameOnly: forMainFrameOnly,
            in: .page
        )
    }
}
