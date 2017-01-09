/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import GCDWebServers
import XCTest

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

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

class BaseTestCase: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        let app = XCUIApplication()
        restart(app)
    }

    override func tearDown() {
        XCUIApplication().terminate()
        super.tearDown()
    }

    func restart(app: XCUIApplication) {
        app.terminate()
        app.launchArguments.append(LaunchArguments.Test)
        app.launchArguments.append(LaunchArguments.ClearProfile)
        app.launch()
        sleep(1)
    }
    
    //If it is a first run, first run window should be gone
    func dismissFirstRunUI() {
        let firstRunUI = XCUIApplication().buttons["Start Browsing"]
        
        if (firstRunUI.exists) {
            firstRunUI.tap()
        }
    }
    
    func waitforExistence(element: XCUIElement) {
        let exists = NSPredicate(format: "exists == true")
        
        expectationForPredicate(exists, evaluatedWithObject: element, handler: nil)
        waitForExpectationsWithTimeout(20, handler: nil)
    }
    
    func waitforNoExistence(element: XCUIElement) {
        let exists = NSPredicate(format: "exists != true")
        
        expectationForPredicate(exists, evaluatedWithObject: element, handler: nil)
        waitForExpectationsWithTimeout(20, handler: nil)
    }
    
    func waitForValueContains(element: XCUIElement, value: String) {
        let predicateText = "value CONTAINS " + "'" + value + "'"
        let valueCheck = NSPredicate(format: predicateText)
        
        expectationForPredicate(valueCheck, evaluatedWithObject: element, handler: nil)
        waitForExpectationsWithTimeout(20, handler: nil)
    }

    func loadWebPage(url: String, waitForLoadToFinish: Bool = true) {
        let loaded = NSPredicate(format: "value BEGINSWITH '100'")

        let app = XCUIApplication()

        UIPasteboard.generalPasteboard().string = url
        app.textFields["url"].pressForDuration(2.0)
        app.sheets.elementBoundByIndex(0).buttons.elementBoundByIndex(0).tap()

        if waitForLoadToFinish {
            let finishLoadingTimeout: NSTimeInterval = 30
            
            let progressIndicator = app.progressIndicators.elementBoundByIndex(0)
            expectationForPredicate(loaded, evaluatedWithObject: progressIndicator, handler: nil)
            waitForExpectationsWithTimeout(finishLoadingTimeout, handler: nil)
        }
    }

}

extension BaseTestCase {
    func tabTrayButton(forApp app: XCUIApplication) -> XCUIElement {
        return app.buttons["TopTabsViewController.tabsButton"].exists ? app.buttons["TopTabsViewController.tabsButton"] : app.buttons["URLBarView.tabsButton"]
    }
}

extension XCUIElement {
    func tap(force force: Bool) {
        // There appears to be a bug with tapping elements sometimes, despite them being on-screen and tappable, due to hittable being false.
        // See: http://stackoverflow.com/a/33534187/1248491
        if hittable {
            tap()
        } else if force {
            coordinateWithNormalizedOffset(CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }
}
