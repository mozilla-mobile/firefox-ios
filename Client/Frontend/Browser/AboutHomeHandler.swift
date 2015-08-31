/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * Handles the page request to about/home/ so that the page loads and does not throw an error (404) on initialization
 */
struct AboutHomeHandler {
    static func register(webServer: WebServer) {
        webServer.registerHandlerForMethod("GET", module: "about", resource: "home") { (request: GCDWebServerRequest!) -> GCDWebServerResponse! in
            return GCDWebServerResponse(statusCode: 200)
        }
    }
}

struct AboutLicenseHandler {
    static func register(webServer: WebServer) {
        webServer.registerHandlerForMethod("GET", module: "about", resource: "license") { (request: GCDWebServerRequest!) -> GCDWebServerResponse! in
            let path = NSBundle.mainBundle().pathForResource("Licenses", ofType: "html")
            do {
                let html = try NSString(contentsOfFile: path!, encoding: NSUTF8StringEncoding) as String
                return GCDWebServerDataResponse(HTML: html)
            } catch {
                print("Unable to register webserver \(error)")
            }
            return GCDWebServerResponse(statusCode: 200)
        }

        webServer.registerHandlerForMethod("GET", module: "about", resource: "rights") { (request: GCDWebServerRequest!) -> GCDWebServerResponse! in
            let path = NSBundle.mainBundle().pathForResource("aboutRights", ofType: "xhtml")!
            var xhtml = try! NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding)

            // Inject aboutRights.dtd definitions
            var dtdPath = NSBundle.mainBundle().pathForResource("aboutRights", ofType: "dtd")!
            var data = try! NSString(contentsOfFile: dtdPath, encoding: NSUTF8StringEncoding) as String
            xhtml = xhtml.stringByReplacingOccurrencesOfString("{aboutRightsDTD}", withString: data)

            // Inject brand.dtd definitions
            dtdPath = NSBundle.mainBundle().pathForResource("brand", ofType: "dtd")!
            data = try! NSString(contentsOfFile: dtdPath, encoding: NSUTF8StringEncoding) as String
            xhtml = xhtml.stringByReplacingOccurrencesOfString("{brandDTD}", withString: data)

            return GCDWebServerDataResponse(XHTML: xhtml as String)
        }

        webServer.registerHandlerForMethod("GET", module: "about", resource: "about.css", handler: { (request) -> GCDWebServerResponse! in
            let path = NSBundle.mainBundle().pathForResource("about", ofType: "css")!
            return GCDWebServerDataResponse(data: NSData(contentsOfFile: path), contentType: "text/css")
        })
    }
}

extension GCDWebServerDataResponse {
    convenience init(XHTML: String) {
        let data = XHTML.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        self.init(data: data, contentType: "application/xhtml+xml; charset=utf-8")
    }
}