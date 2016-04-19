/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import GCDWebServers

/// Handles requests to /snapshottest for hacks we need from Xcode UI tests
struct SnapshotTestHandler {
    static func register(webServer: WebServer) {
        webServer.registerHandlerForMethod("GET", module: "snapshottest", resource: "hidekeyboard") { _ in
            dispatch_async(dispatch_get_main_queue(),{
                UIApplication.sharedApplication().sendAction("resignFirstResponder", to:nil, from:nil, forEvent:nil)
            })
            return GCDWebServerResponse(statusCode: 200)
        }
    }
}