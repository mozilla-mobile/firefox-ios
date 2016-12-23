/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import GCDWebServers
import Shared
import XCTest

class SimplePageServer {
    class func getPageData(name: String, ext: String = "html") -> String {
        let pageDataPath = NSBundle(forClass: self).pathForResource(name, ofType: ext)!
        return (try! NSString(contentsOfFile: pageDataPath, encoding: NSUTF8StringEncoding)) as String
    }

    class func start() -> String {
        let webServer: GCDWebServer = GCDWebServer()

        webServer.addHandlerForMethod("GET", path: "/image.png", requestClass: GCDWebServerRequest.self) { (request) -> GCDWebServerResponse! in
            let img = UIImagePNGRepresentation(UIImage(named: "back")!)
            return GCDWebServerDataResponse(data: img, contentType: "image/png")
        }

        for page in ["findPage", "noTitle", "readablePage", "JSPrompt"] {
            webServer.addHandlerForMethod("GET", path: "/\(page).html", requestClass: GCDWebServerRequest.self) { (request) -> GCDWebServerResponse! in
                return GCDWebServerDataResponse(HTML: self.getPageData(page))
            }
        }

        // we may create more than one of these but we need to give them uniquie accessibility ids in the tab manager so we'll pass in a page number
        webServer.addHandlerForMethod("GET", path: "/scrollablePage.html", requestClass: GCDWebServerRequest.self) { (request) -> GCDWebServerResponse! in
            var pageData = self.getPageData("scrollablePage")
            let page = Int((request.query["page"] as! String))!
            pageData = pageData.stringByReplacingOccurrencesOfString("{page}", withString: page.description)
            return GCDWebServerDataResponse(HTML: pageData as String)
        }

        webServer.addHandlerForMethod("GET", path: "/numberedPage.html", requestClass: GCDWebServerRequest.self) { (request) -> GCDWebServerResponse! in
            var pageData = self.getPageData("numberedPage")

            let page = Int((request.query["page"] as! String))!
            pageData = pageData.stringByReplacingOccurrencesOfString("{page}", withString: page.description)

            return GCDWebServerDataResponse(HTML: pageData as String)
        }

        webServer.addHandlerForMethod("GET", path: "/readerContent.html", requestClass: GCDWebServerRequest.self) { (request) -> GCDWebServerResponse! in
            return GCDWebServerDataResponse(HTML: self.getPageData("readerContent"))
        }

        webServer.addHandlerForMethod("GET", path: "/loginForm.html", requestClass: GCDWebServerRequest.self) { _ in
            return GCDWebServerDataResponse(HTML: self.getPageData("loginForm"))
        }

        webServer.addHandlerForMethod("GET", path: "/localhostLoad.html", requestClass: GCDWebServerRequest.self) { _ in
            return GCDWebServerDataResponse(HTML: self.getPageData("localhostLoad"))
        }

        webServer.addHandlerForMethod("GET", path: "/auth.html", requestClass: GCDWebServerRequest.self) { (request: GCDWebServerRequest!) in
            // "user:pass", Base64-encoded.
            let expectedAuth = "Basic dXNlcjpwYXNz"

            let response: GCDWebServerDataResponse
            if request.headers["Authorization"] as? String == expectedAuth && request.query["logout"] == nil {
                response = GCDWebServerDataResponse(HTML: "<html><body>logged in</body></html>")
            } else {
                // Request credentials if the user isn't logged in.
                response = GCDWebServerDataResponse(HTML: "<html><body>auth fail</body></html>")
                response.statusCode = 401
                response.setValue("Basic realm=\"test\"", forAdditionalHeader: "WWW-Authenticate")
            }

            return response
        }

        if !webServer.startWithPort(0, bonjourName: nil) {
            XCTFail("Can't start the GCDWebServer")
        }

        // We use 127.0.0.1 explicitly here, rather than localhost, in order to avoid our
        // history exclusion code (Bug 1188626).
        let webRoot = "http://127.0.0.1:\(webServer.port)"
        return webRoot
    }
}
