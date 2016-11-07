/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import GCDWebServers

private let LocalResources = ["rights-focus", "rights-klar", "licenses", "gpl"]

class LocalWebServer {
    static let sharedInstance = LocalWebServer(port: 6573)

    fileprivate let server = GCDWebServer()
    fileprivate let port: UInt
    fileprivate let base: String

    init(port: UInt) {
        self.port = port
        base = "http://localhost:\(port)"
    }

    func start() {
        LocalResources.forEach { resource in
            let path = Bundle.main.path(forResource: resource, ofType: "html")
            server?.addGETHandler(forPath: "/\(resource).html", filePath: path, isAttachment: false, cacheAge: UInt.max, allowRangeRequests: true)
        }

        let stylesPath = Bundle.main.path(forResource: "style", ofType: "css")
        server?.addGETHandler(forPath: "/style.css", filePath: stylesPath, isAttachment: false, cacheAge: UInt.max, allowRangeRequests: true)

        server?.start(withPort: port, bonjourName: nil)
    }

    func URLForPath(_ path: String) -> URL! {
        return URL(string: "\(base)\(path)")
    }
}
