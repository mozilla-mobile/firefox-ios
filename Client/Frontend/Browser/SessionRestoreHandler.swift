/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

/**
 * Handles the page request to about/sessionrestore to restore a crashed session. The page then handles the restoration of the
 * state of the tabs via javascript embedded in the html file and via redirecting the links using the error page custom redirect.
 */
struct SessionRestoreHandler {
    static func register(webServer: WebServer) {
        // Register the handler that accepts /about/sessionrestore?history=...&currentpage=... requests.
        webServer.registerHandlerForMethod("GET", module: "about", resource: "sessionrestore") { (request: GCDWebServerRequest!) -> GCDWebServerResponse! in
            if let sessionRestorePath = NSBundle.mainBundle().pathForResource("SessionRestore", ofType: "html") {
                do {
                    let sessionRestoreString = try NSMutableString(contentsOfFile: sessionRestorePath, encoding: NSUTF8StringEncoding)
                    return GCDWebServerDataResponse(HTML: sessionRestoreString as String)
                } catch _ {
                }
            }
            return GCDWebServerResponse(statusCode: 404)
        }
    }
}