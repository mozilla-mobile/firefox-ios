/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import WebKit

let LabelAddressAndSearch = "Address and Search"

extension XCTestCase {
    func tester(file: String = __FILE__, _ line: Int = __LINE__) -> KIFUITestActor {
        return KIFUITestActor(inFile: file, atLine: line, delegate: self)
    }

    func system(file: String = __FILE__, _ line: Int = __LINE__) -> KIFSystemTestActor {
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

    func waitForViewWithAccessibilityHint(hint: String) -> UIView? {
        var view: UIView? = nil
        autoreleasepool {
            waitForAccessibilityElement(nil, view: &view, withElementMatchingPredicate: NSPredicate(format: "accessibilityHint = %@", hint), tappable: false)
        }
        return view
    }

    func viewExistsWithLabel(label: String) -> Bool {
        do {
            try self.tryFindingViewWithAccessibilityLabel(label)
            return true
        } catch {
            return false
        }
    }

    func viewExistsWithLabelPrefixedBy(prefix: String) -> Bool {
        let element = UIApplication.sharedApplication().accessibilityElementMatchingBlock { element in
            return element.accessibilityLabel?.hasPrefix(prefix) ?? false
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
        runBlock { error in
            if (self.hasWebViewElementWithAccessibilityLabel(text)) {
                return KIFTestStepResult.Success
            }

            return KIFTestStepResult.Wait
        }
    }

    /**
     * Sets the text for a WKWebView input element with the given name.
     */
    func enterText(text: String, intoWebViewInputWithName inputName: String) {
        let webView = getWebViewWithKIFHelper()
        var stepResult = KIFTestStepResult.Wait

        let escaped = text.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
        webView.evaluateJavaScript("KIFHelper.enterTextIntoInputWithName(\"\(escaped)\", \"\(inputName)\");") { success, _ in
            stepResult = (success as! Bool) ? KIFTestStepResult.Success : KIFTestStepResult.Failure
        }

        runBlock { error in
            if stepResult == KIFTestStepResult.Failure {
                error.memory = NSError(domain: "KIFHelper", code: 0, userInfo: [NSLocalizedDescriptionKey: "Input element not found in webview: \(escaped)"])
            }
            return stepResult
        }
    }

    /**
     * Clicks a WKWebView element with the given label.
     */
    func tapWebViewElementWithAccessibilityLabel(text: String) {
        let webView = getWebViewWithKIFHelper()
        var stepResult = KIFTestStepResult.Wait

        let escaped = text.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
        webView.evaluateJavaScript("KIFHelper.tapElementWithAccessibilityLabel(\"\(escaped)\")") { success, _ in
            stepResult = (success as! Bool) ? KIFTestStepResult.Success : KIFTestStepResult.Failure
        }

        runBlock { error in
            if stepResult == KIFTestStepResult.Failure {
                error.memory = NSError(domain: "KIFHelper", code: 0, userInfo: [NSLocalizedDescriptionKey: "Accessibility label not found in webview: \(escaped)"])
            }
            return stepResult
        }
    }

    /**
     * Determines whether an element in the page exists.
     */
    func hasWebViewElementWithAccessibilityLabel(text: String) -> Bool {
        let webView = getWebViewWithKIFHelper()
        var stepResult = KIFTestStepResult.Wait
        var found = false

        let escaped = text.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
        webView.evaluateJavaScript("KIFHelper.hasElementWithAccessibilityLabel(\"\(escaped)\")") { success, _ in
            found = success as? Bool ?? false
            stepResult = KIFTestStepResult.Success
        }

        runBlock { _ in return stepResult }

        return found
    }

    private func getWebViewWithKIFHelper() -> WKWebView {
        let webView = waitForViewWithAccessibilityLabel("Web content") as! WKWebView

        // Wait for the web view to stop loading.
        runBlock { _ in
            return webView.loading ? KIFTestStepResult.Wait : KIFTestStepResult.Success
        }

        var stepResult = KIFTestStepResult.Wait

        webView.evaluateJavaScript("typeof KIFHelper") { result, _ in
            if result as! String == "undefined" {
                let bundle = NSBundle(forClass: NavigationTests.self)
                let path = bundle.pathForResource("KIFHelper", ofType: "js")!
                let source = try! NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding)
                webView.evaluateJavaScript(source as String, completionHandler: nil)
            }
            stepResult = KIFTestStepResult.Success
        }

        runBlock { _ in return stepResult }

        return webView
    }

    public func deleteCharacterFromFirstResponser() {
        enterTextIntoCurrentFirstResponder("\u{0008}")
    }
}

class BrowserUtils {
    /// Close all tabs to restore the browser to startup state.
    class func resetToAboutHome(tester: KIFUITestActor) {
        do {
            try tester.tryFindingTappableViewWithAccessibilityLabel("Cancel")
            tester.tapViewWithAccessibilityLabel("Cancel")
        } catch _ {
        }
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        let tabsView = tester.waitForViewWithAccessibilityLabel("Tabs Tray").subviews.first as! UICollectionView

        // Clear all private tabs if we're running iOS 9
        if #available(iOS 9, *) {
            // Switch to Private Mode if we're not in it already.
            do {
                try tester.tryFindingTappableViewWithAccessibilityLabel("Private Mode", value: "Off", traits: UIAccessibilityTraitButton)
                tester.tapViewWithAccessibilityLabel("Private Mode")
            } catch _ {}

            while tabsView.numberOfItemsInSection(0) > 0 {
                let cell = tabsView.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0))!
                tester.swipeViewWithAccessibilityLabel(cell.accessibilityLabel, inDirection: KIFSwipeDirection.Left)
                tester.waitForAbsenceOfViewWithAccessibilityLabel(cell.accessibilityLabel)
            }
            tester.tapViewWithAccessibilityLabel("Private Mode")
        }

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
        notificationCenter.postNotificationName("OnLocationChange", object: self, userInfo: info)
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
        var index = 0
        for _ in 0 ..< historyTable.numberOfSections {
            for _ in 0 ..< historyTable.numberOfRowsInSection(0) {
                clearHistoryItemAtIndex(NSIndexPath(forRow: 0, inSection: 0), tester: tester)
                if numberOfTests > -1 && ++index == numberOfTests {
                    return
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
        let textLength = textField.text!.characters.count

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

        let completionStartIndex = textField.text!.startIndex.advancedBy(prefixLength)
        let actualPrefix = textField.text!.substringToIndex(completionStartIndex)
        let actualCompletion = textField.text!.substringFromIndex(completionStartIndex)

        XCTAssertEqual(prefix, actualPrefix, "Expected prefix matches actual prefix")
        XCTAssertEqual(completion, actualCompletion, "Expected completion matches actual completion")
    }
}

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

class SearchUtils {
    static func navigateToSearchSettings(tester: KIFUITestActor, engine: String = "Yahoo") {
        tester.tapViewWithAccessibilityLabel("Show Tabs")
        tester.waitForViewWithAccessibilityLabel("Tabs Tray")
        tester.tapViewWithAccessibilityLabel("Settings")
        tester.waitForViewWithAccessibilityLabel("Settings")
        tester.tapViewWithAccessibilityLabel("Search, \(engine)")
        tester.waitForViewWithAccessibilityIdentifier("Search")
    }

    static func navigateFromSearchSettings(tester: KIFUITestActor) {
        tester.tapViewWithAccessibilityLabel("Settings")
        tester.tapViewWithAccessibilityLabel("Done")
        tester.tapViewWithAccessibilityLabel("home")
    }

    // Given that we're at the Search Settings sheet, select the named search engine as the default.
    // Afterwards, we're still at the Search Settings sheet.
    static func selectDefaultSearchEngineName(tester: KIFUITestActor, engineName: String) {
        tester.tapViewWithAccessibilityLabel("Default Search Engine", traits: UIAccessibilityTraitButton)
        tester.waitForViewWithAccessibilityLabel("Default Search Engine")
        tester.tapViewWithAccessibilityLabel(engineName)
        tester.waitForViewWithAccessibilityLabel("Search")
    }

    // Given that we're at the Search Settings sheet, return the default search engine's name.
    static func getDefaultSearchEngineName(tester: KIFUITestActor) -> String {
        let view = tester.waitForCellWithAccessibilityLabel("Default Search Engine")
        return view.accessibilityValue!
    }
}

class DynamicFontUtils {
    // Need to leave time for the notification to propagate
    static func bumpDynamicFontSize(tester: KIFUITestActor) {
        let value = UIContentSizeCategoryAccessibilityExtraLarge
        UIApplication.sharedApplication().setValue(value, forKey: "preferredContentSizeCategory")
        tester.waitForTimeInterval(0.3)
    }

    static func lowerDynamicFontSize(tester: KIFUITestActor) {
        let value = UIContentSizeCategoryExtraSmall
        UIApplication.sharedApplication().setValue(value, forKey: "preferredContentSizeCategory")
        tester.waitForTimeInterval(0.3)
    }

    static func restoreDynamicFontSize(tester: KIFUITestActor) {
        let value = UIContentSizeCategoryMedium
        UIApplication.sharedApplication().setValue(value, forKey: "preferredContentSizeCategory")
        tester.waitForTimeInterval(0.3)
    }
}
