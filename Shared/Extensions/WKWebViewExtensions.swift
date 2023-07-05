// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

enum JavascriptError: Error {
  case invalid
}

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

    /// Generates a JavaScript function call string.
    /// - Parameters:
    ///   - functionName: The name of the JavaScript function to call.
    ///   - args: An array of arguments to pass to the JavaScript function. Each argument can be of any type.
    ///   - escapeArgs: A Boolean value indicating whether to escape string arguments for HTML entities.
    /// - Returns: A tuple containing the JavaScript function call string and an optional error.
    func generateJSFunctionString(functionName: String,
                                  args: [Any?],
                                  escapeArgs: Bool = true) -> (javascript: String, error: Error?) {
        var sanitizedArgs = [String]()
        // Iterate through each argument in the provided array
        for arg in args {
            if let arg = arg {
                do {
                    if let arg = arg as? String {
                        // If the argument is a string, optionally escape it for HTML entities
                        sanitizedArgs.append(escapeArgs ? "'\(arg.htmlEntityEncodedString)'" : "\(arg)")
                    } else {
                        // If the argument is not a string, serialize it as JSON
                        let data = try JSONSerialization.data(withJSONObject: arg,
                                                              options: [.fragmentsAllowed])
                        if let str = String(data: data, encoding: .utf8) {
                            sanitizedArgs.append(str)
                        } else {
                            throw JavascriptError.invalid
                        }
                    }
                } catch {
                    return ("", error)
                }
            } else {
                // If the argument is nil, add "null" as the argument value
                sanitizedArgs.append("null")
            }
        }

        // Check if the number of sanitized arguments matches the original number of arguments
        if args.count != sanitizedArgs.count {
            assertionFailure("Javascript parsing failed.")
            return ("", JavascriptError.invalid)
        }

        // Generate the JavaScript function call string with sanitized arguments
        return ("\(functionName)(\(sanitizedArgs.joined(separator: ", ")))", nil)
    }

    func evaluateSafeJavaScriptInDefaultContentWorld(functionName: String,
                                                     args: [Any] = [],
                                                     frame: WKFrameInfo? = nil,
                                                     escapeArgs: Bool = true,
                                                     asFunction: Bool = true,
                                                     _ completion: @escaping (Any?, Error?) -> Void) {
        var javascript = functionName

        if asFunction {
            let js = generateJSFunctionString(functionName: functionName, args: args, escapeArgs: escapeArgs)
            if js.error != nil {
                completion(nil, js.error)
                return
            }
            javascript = js.javascript
        }

        DispatchQueue.main.async {
            self.evaluateJavascriptInDefaultContentWorld(javascript, frame, completion)
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
