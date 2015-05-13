/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

extension XCTestCase {
    func tester(_ file: String = __FILE__, _ line: Int = __LINE__) -> KIFUITestActor {
        return KIFUITestActor(inFile: file, atLine: line, delegate: self)
    }

    func system(_ file: String = __FILE__, _ line: Int = __LINE__) -> KIFSystemTestActor {
        return KIFSystemTestActor(inFile: file, atLine: line, delegate: self)
    }
}

extension KIFUITestActor {
    /**
     * Finding views by accessibility label doesn't currently work with WKWebView:
     *     https://github.com/kif-framework/KIF/issues/460
     * As a workaround, inject a KIFHelper class that iterates the document and finds
     * elements with the given textContent or title.
     */
    func waitForWebViewElementWithAccessibilityLabel(text: String) {
        let webView = waitForViewWithAccessibilityLabel("Web content") as! WKWebView

        // Wait for the webView to stop loading.
        runBlock({ _ in
            return webView.loading ? KIFTestStepResult.Wait : KIFTestStepResult.Success
        })

        lazilyInjectKIFHelper(webView)

        var stepResult = KIFTestStepResult.Wait

        let escaped = text.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
        webView.evaluateJavaScript("KIFHelper.selectElementWithAccessibilityLabel(\"\(escaped)\");", completionHandler: { (result: AnyObject!, error: NSError!) in
            stepResult = result as! Bool ? KIFTestStepResult.Success : KIFTestStepResult.Failure
        })

        runBlock({ (error: NSErrorPointer) in
            if stepResult == KIFTestStepResult.Failure {
                error.memory = NSError(domain: "KIFHelper", code: 0, userInfo: [NSLocalizedDescriptionKey: "Accessibility label not found in webview: \(escaped)"])
            }
            return stepResult
        })
    }

    private func lazilyInjectKIFHelper(webView: WKWebView) {
        var stepResult = KIFTestStepResult.Wait

        webView.evaluateJavaScript("typeof KIFHelper;", completionHandler: { (result: AnyObject!, error: NSError!) in
            if result as! String == "undefined" {
                let bundle = NSBundle(forClass: NavigationTests.self)
                let path = bundle.pathForResource("KIFHelper", ofType: "js")!
                let source = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil)!
                webView.evaluateJavaScript(source as String, completionHandler: nil)
            }
            stepResult = KIFTestStepResult.Success
        })

        runBlock({ _ in
            return stepResult
        })
    }

    // TODO: Click element, etc.
}

class BrowserUtils {
    /// Close all tabs and open a single about:home tab to restore the browser to startup state.
    class func resetToAboutHome(tester: KIFUITestActor) {
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        let tabsView = tester.waitForViewWithAccessibilityLabel("Tabs Tray").subviews.first as! UICollectionView
        while tabsView.numberOfItemsInSection(0) > 0 {
            let cell = tabsView.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0))!
            tester.swipeViewWithAccessibilityLabel(cell.accessibilityLabel, inDirection: KIFSwipeDirection.Left)
            tester.waitForAbsenceOfViewWithAccessibilityLabel(cell.accessibilityLabel)
        }
        tester.tapViewWithAccessibilityLabel("Add Tab")
    }
}

class SimplePageServer {
    class func getPageData(name: String, ext: String = "html") -> String {
        var pageDataPath = NSBundle(forClass: self).pathForResource(name, ofType: ext)!
        return NSString(contentsOfFile: pageDataPath, encoding: NSUTF8StringEncoding, error: nil)! as String
    }

    class func start() -> String {
        let webServer: GCDWebServer = GCDWebServer()

        webServer.addHandlerForMethod("GET", path: "/image.png", requestClass: GCDWebServerRequest.self) { (request) -> GCDWebServerResponse! in
            let img = UIImagePNGRepresentation(UIImage(named: "back"))
            return GCDWebServerDataResponse(data: img, contentType: "image/png")
        }

        webServer.addHandlerForMethod("GET", path: "/noTitle.html", requestClass: GCDWebServerRequest.self) { (request) -> GCDWebServerResponse! in
            return GCDWebServerDataResponse(HTML: self.getPageData("noTitle"))
        }

        webServer.addHandlerForMethod("GET", path: "/numberedPage.html", requestClass: GCDWebServerRequest.self) { (request) -> GCDWebServerResponse! in
            var pageData = self.getPageData("numberedPage")

            let page = (request.query["page"] as! String).toInt()!
            pageData = pageData.stringByReplacingOccurrencesOfString("{page}", withString: page.description)

            return GCDWebServerDataResponse(HTML: pageData as String)
        }

        webServer.addHandlerForMethod("GET", path: "/readerContent.html", requestClass: GCDWebServerRequest.self) { (request) -> GCDWebServerResponse! in
            return GCDWebServerDataResponse(HTML: self.getPageData("readerContent"))
        }

        if !webServer.startWithPort(0, bonjourName: nil) {
            XCTFail("Can't start the GCDWebServer")
        }

        let webRoot = "http://localhost:\(webServer.port)"
        return webRoot
    }
}
