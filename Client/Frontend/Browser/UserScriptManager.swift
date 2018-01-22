/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit

class UserScriptManager {
    init(tab: Tab) {
        // All Frames (.atDocumentStart)
        if let path = Bundle.main.path(forResource: "AllFramesAtDocumentStart", ofType: "js"),
            let source = try? NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String {
            let userScript = WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false)
            tab.webView?.configuration.userContentController.addUserScript(userScript)
        }

        // All Frames (.atDocumentEnd)
        if let path = Bundle.main.path(forResource: "AllFramesAtDocumentEnd", ofType: "js"),
            let source = try? NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String {
            let userScript = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
            tab.webView?.configuration.userContentController.addUserScript(userScript)
        }

        // Main Frame (.atDocumentStart)
         if let path = Bundle.main.path(forResource: "MainFrameAtDocumentStart", ofType: "js"),
             let source = try? NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String {
             let userScript = WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
             tab.webView?.configuration.userContentController.addUserScript(userScript)
         }

        // Main Frame (.atDocumentEnd)
         if let path = Bundle.main.path(forResource: "MainFrameAtDocumentEnd", ofType: "js"),
             let source = try? NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String {
             let userScript = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
             tab.webView?.configuration.userContentController.addUserScript(userScript)
         }
    }
}
