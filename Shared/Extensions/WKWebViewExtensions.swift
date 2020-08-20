/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

extension WKWebView {
    
    public func evaluateJavascriptInDefaultContentWorld(_ javascript: String) {
        if #available(iOS 14.0, *) {
            self.evaluateJavaScript(javascript, in: nil, in: .defaultClient, completionHandler: { _ in })
        } else {
            self.evaluateJavaScript(javascript)
        }
    }
    
    public func evaluateJavascriptInDefaultContentWorld(_ javascript: String, completion: @escaping ((Any?, Error?) -> Void)) {
        if #available(iOS 14.0, *) {
            self.evaluateJavaScript(javascript, in: nil, in: .defaultClient) { result in
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
