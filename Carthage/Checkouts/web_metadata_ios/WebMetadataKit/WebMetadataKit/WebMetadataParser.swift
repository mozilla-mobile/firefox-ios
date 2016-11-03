/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

public class WebMetadataParser {
    private let libraryUserScript: WKUserScript
    private let parserWrapperUserScript: WKUserScript

    public init?() {
        let bundle = NSBundle(forClass: WebMetadataParser.self)
        guard let libraryPath = bundle.pathForResource("page-metadata-parser.bundle", ofType: "js"),
           let parserWrapperPath = bundle.pathForResource("WebMetadataParser", ofType: "js"),
           librarySource = try? NSString(contentsOfFile: libraryPath, encoding: NSUTF8StringEncoding) as String,
           parserWrapperSource = try? NSString(contentsOfFile: parserWrapperPath, encoding: NSUTF8StringEncoding) as String else {
            return nil
        }

        libraryUserScript = WKUserScript(source: librarySource, injectionTime: .AtDocumentEnd, forMainFrameOnly: false)
        parserWrapperUserScript = WKUserScript(source: parserWrapperSource, injectionTime: .AtDocumentEnd, forMainFrameOnly: false)
    }

    public func addUserScriptsIntoWebView(webView: WKWebView) {
        webView.configuration.userContentController.addUserScript(libraryUserScript)
        webView.configuration.userContentController.addUserScript(parserWrapperUserScript)
    }
}
