/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import WebKit

let LabelAddressAndSearch = "Address and Search"

extension XCTestCase {
    func tester(_ file: String = __FILE__, _ line: Int = __LINE__) -> KIFUITestActor {
        return KIFUITestActor(inFile: file, atLine: line, delegate: self)
    }

    func system(_ file: String = __FILE__, _ line: Int = __LINE__) -> KIFSystemTestActor {
        return KIFSystemTestActor(inFile: file, atLine: line, delegate: self)
    }
}

extension KIFUITestActor {
    /// Looks for a view with the given accessibility hint.
    func tryFindingViewWithAccessibilityHint(hint: String) -> Bool {
        let element = UIApplication.sharedApplication().accessibilityElementMatchingBlock { element in
            return element.accessibilityHint == hint
        }

        return element != nil
    }

    /// Waits for and returns a view with the given accessibility value.
    func waitForViewWithAccessibilityValue(value: String) -> UIView {
        var element: UIAccessibilityElement!

        runBlock { _ in
            element = UIApplication.sharedApplication().accessibilityElementMatchingBlock { element in
                return element.accessibilityValue == value
            }

            return (element == nil) ? KIFTestStepResult.Wait : KIFTestStepResult.Success
        }

        return UIAccessibilityElement.viewContainingAccessibilityElement(element)
    }

    /// Wait for and returns a view with the given accessibility label as an
    /// attributed string. See the comment in ReadingListPanel.swift about
    /// using attributed strings as labels. (It lets us set the pitch)
    func waitForViewWithAttributedAccessibilityLabel(label: NSAttributedString) -> UIView {
        var element: UIAccessibilityElement!

        runBlock { _ in
            element = UIApplication.sharedApplication().accessibilityElementMatchingBlock { element in
                if let elementLabel = element.valueForKey("accessibilityLabel") as? NSAttributedString {
                    return elementLabel.isEqualToAttributedString(label)
                }
                return false
            }
            
            return (element == nil) ? KIFTestStepResult.Wait : KIFTestStepResult.Success
        }

        return UIAccessibilityElement.viewContainingAccessibilityElement(element)
    }

    /// There appears to be a KIF bug where waitForViewWithAccessibilityLabel returns the parent
    /// UITableView instead of the UITableViewCell with the given label.
    /// As a workaround, retry until KIF gives us a cell.
    /// Open issue: https://github.com/kif-framework/KIF/issues/336
    func waitForCellWithAccessibilityLabel(label: String) -> UITableViewCell {
        var cell: UITableViewCell!

        runBlock { _ in
            let view = self.waitForViewWithAccessibilityLabel(label)
            cell = view as? UITableViewCell
            return (cell == nil) ? KIFTestStepResult.Wait : KIFTestStepResult.Success
        }

        return cell
    }

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

    public func deleteCharacterFromFirstResponser() {
        enterTextIntoCurrentFirstResponder("\u{0008}")
    }

    // TODO: Click element, etc.
}

class BrowserUtils {
    /// Close all tabs to restore the browser to startup state.
    class func resetToAboutHome(tester: KIFUITestActor) {
        if tester.tryFindingTappableViewWithAccessibilityLabel("Cancel", error: nil) {
            tester.tapViewWithAccessibilityLabel("Cancel")
        }
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        let tabsView = tester.waitForViewWithAccessibilityLabel("Tabs Tray").subviews.first as! UICollectionView
        while tabsView.numberOfItemsInSection(0) > 1 {
            let cell = tabsView.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0))!
            tester.swipeViewWithAccessibilityLabel(cell.accessibilityLabel, inDirection: KIFSwipeDirection.Left)
            tester.waitForAbsenceOfViewWithAccessibilityLabel(cell.accessibilityLabel)
        }

        // When the last tab is closed, the tabs tray will automatically be closed
        // since a new about:home tab will be selected.
        if let cell = tabsView.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0)) {
            tester.swipeViewWithAccessibilityLabel(cell.accessibilityLabel, inDirection: KIFSwipeDirection.Left)
            tester.waitForTappableViewWithAccessibilityLabel("Show Tabs")
        }
    }

    /// Injects a URL and title into the browser's history database.
    class func addHistoryEntry(title: String, url: NSURL) {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        var info = [NSObject: AnyObject]()
        info["url"] = url
        info["title"] = title
        info["visitType"] = VisitType.Link.rawValue
        notificationCenter.postNotificationName("LocationChange", object: self, userInfo: info)
    }

    private class func clearHistoryItemAtIndex(index: NSIndexPath, tester: KIFUITestActor) {
        if let row = tester.waitForCellAtIndexPath(index, inTableViewWithAccessibilityIdentifier: "History List") {
            tester.swipeViewWithAccessibilityLabel(row.accessibilityLabel, value: row.accessibilityValue, inDirection: KIFSwipeDirection.Left)
            tester.tapViewWithAccessibilityLabel("Remove")
        }
    }

    class func clearHistoryItems(tester: KIFUITestActor, numberOfTests: Int = -1) {
        resetToAboutHome(tester)
        tester.tapViewWithAccessibilityLabel("History")

        let historyTable = tester.waitForViewWithAccessibilityIdentifier("History List") as! UITableView
        if numberOfTests == -1 {
            for section in 0 ..< historyTable.numberOfSections() {
                for rowIdx in 0 ..< historyTable.numberOfRowsInSection(0) {
                    clearHistoryItemAtIndex(NSIndexPath(forRow: 0, inSection: 0), tester: tester)
                }
            }
        } else {
            var index = 0
            for section in 0 ..< historyTable.numberOfSections() {
                for rowIdx in 0 ..< historyTable.numberOfRowsInSection(0) {
                    clearHistoryItemAtIndex(NSIndexPath(forRow: 0, inSection: 0), tester: tester)
//                    index++
                    if ++index == numberOfTests {
                        return
                    }
                }
            }
        }
        tester.tapViewWithAccessibilityLabel("Top sites")
    }

    class func ensureAutocompletionResult(tester: KIFUITestActor, textField: UITextField, prefix: String, completion: String) {
        // searches are async (and debounced), so we have to wait for the results to appear.
        tester.waitForViewWithAccessibilityValue(prefix + completion)

        var range = NSRange()
        var attribute: AnyObject?
        let textLength = count(textField.text)

        attribute = textField.attributedText!.attribute(NSBackgroundColorAttributeName, atIndex: 0, effectiveRange: &range)

        if attribute != nil {
            // If the background attribute exists for the first character, the entire string is highlighted.
            XCTAssertEqual(prefix, "")
            XCTAssertEqual(completion, textField.text)
            return
        }

        let prefixLength = range.length

        attribute = textField.attributedText!.attribute(NSBackgroundColorAttributeName, atIndex: textLength - 1, effectiveRange: &range)

        if attribute == nil {
            // If the background attribute exists for the last character, the entire string is not highlighted.
            XCTAssertEqual(prefix, textField.text)
            XCTAssertEqual(completion, "")
            return
        }

        let completionStartIndex = advance(textField.text.startIndex, prefixLength)
        let actualPrefix = textField.text.substringToIndex(completionStartIndex)
        let actualCompletion = textField.text.substringFromIndex(completionStartIndex)

        XCTAssertEqual(prefix, actualPrefix, "Expected prefix matches actual prefix")
        XCTAssertEqual(completion, actualCompletion, "Expected completion matches actual completion")
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

        for page in ["noTitle", "readablePage"] {
            webServer.addHandlerForMethod("GET", path: "/\(page).html", requestClass: GCDWebServerRequest.self) { (request) -> GCDWebServerResponse! in
                return GCDWebServerDataResponse(HTML: self.getPageData(page))
            }
        }

        // we may create more than one of these but we need to give them uniquie accessibility ids in the tab manager so we'll pass in a page number
        webServer.addHandlerForMethod("GET", path: "/scrollablePage.html", requestClass: GCDWebServerRequest.self) { (request) -> GCDWebServerResponse! in
            var pageData = self.getPageData("scrollablePage")
            let page = (request.query["page"] as! String).toInt()!
            pageData = pageData.stringByReplacingOccurrencesOfString("{page}", withString: page.description)
            return GCDWebServerDataResponse(HTML: pageData as String)
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

        // We use 127.0.0.1 explicitly here, rather than localhost, in order to avoid our
        // history exclusion code (Bug 1188626).
        let webRoot = "http://127.0.0.1:\(webServer.port)"
        return webRoot
    }
}
