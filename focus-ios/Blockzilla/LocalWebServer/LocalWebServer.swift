/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import GCDWebServers

private let LocalResources = ["rights", "licenses", "gpl"]

class LocalWebServer {
    static let sharedInstance = LocalWebServer(port: 6573)

    private let server = GCDWebServer()
    private let port: UInt
    private let base: String

    init(port: UInt) {
        self.port = port
        base = "http://localhost:\(port)"
    }

    func start() {
        LocalResources.forEach { resource in
            let path = NSBundle.mainBundle().pathForResource(resource, ofType: "html")
            server.addGETHandlerForPath("/\(resource).html", filePath: path, isAttachment: false, cacheAge: UInt.max, allowRangeRequests: true)
        }

        let stylesPath = NSBundle.mainBundle().pathForResource("style", ofType: "css")
        server.addGETHandlerForPath("/style.css", filePath: stylesPath, isAttachment: false, cacheAge: UInt.max, allowRangeRequests: true)

        server.startWithPort(port, bonjourName: nil)
    }

    func URLForPath(path: String) -> NSURL! {
        return NSURL(string: "\(base)\(path)")
    }
}