/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger
import ShimWK

private let log = Logger.browserLogger

class MetadataParserHelper: TabHelper {
    private weak var tab: Tab?
    private let profile: Profile

    class func name() -> String {
        return "MetadataParserHelper"
    }

    required init(tab: Tab, profile: Profile) {
        self.tab = tab
        self.profile = profile

        if let libraryPath = NSBundle.mainBundle().pathForResource("page-metadata-parser.bundle", ofType: "js"),
           let parserWrapperPath = NSBundle.mainBundle().pathForResource("MetadataParser", ofType: "js"),
           librarySource = try? NSString(contentsOfFile: libraryPath, encoding: NSUTF8StringEncoding) as String,
           parserWrapperSource = try? NSString(contentsOfFile: parserWrapperPath, encoding: NSUTF8StringEncoding) as String {

            // Load in the page-metadata-parser library first so our wrapper can reference it
            let libraryUserScript = ShimWKUserScript(source: librarySource, injectionTime: .AtDocumentEnd, forMainFrameOnly: false)
            tab.webView!.configuration.userContentController.addUserScript(libraryUserScript)

            // Load in our ShimWKUserScript wrapper on top of the library second
            let parserWrapperUserScript = ShimWKUserScript(source: parserWrapperSource, injectionTime: .AtDocumentEnd, forMainFrameOnly: false)
            tab.webView!.configuration.userContentController.addUserScript(parserWrapperUserScript)
        }
    }

    func scriptMessageHandlerName() -> String? {
        return "metadataMessageHandler"
    }

    func userContentController(userContentController: ShimWKUserContentController, didReceiveScriptMessage message: ShimWKScriptMessage) {
        guard let dict = message.body as? [String: AnyObject],
              let url = (dict["url"] as? String)?.asURL else {
            return
        }

        // Pull out what we need and pass to a notification
        var userInfo = [String: AnyObject]()
        userInfo["isPrivate"] = tab?.isPrivate ?? true
        userInfo["metadata_url"] = url
        userInfo["metadata_title"] = dict["title"] as? String
        userInfo["metadata_description"] = dict["description"] as? String
        userInfo["metadata_image_url"] = (dict["image_url"] as? String)?.asURL
        userInfo["metadata_type"] = dict["type"] as? String
        userInfo["metadata_icon_url"] = (dict["icon_url"] as? String)?.asURL

        NSNotificationCenter.defaultCenter().postNotificationName(NotificationOnPageMetadataFetched, object: nil, userInfo: userInfo)
    }
}
