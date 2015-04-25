/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

/// Set of tests that wait for weak references to views to be cleared. Technically, this is
/// non-deterministic and there are no guarantees the references will be set to nil. In practice,
/// though, the references are consistently cleared, which should be good enough for testing.
class ViewMemoryLeakTests: KIFTestCase, UITextFieldDelegate {
    private var webRoot: String!

    override func setUp() {
        webRoot = SimplePageServer.start()
    }

    override func tearDown() {
        // Go back to about:home to reset the UI state between tests.
        tester().tapViewWithAccessibilityLabel("URL")
        let url = "about:home\n"
        tester().clearTextFromAndThenEnterText(url, intoViewWithAccessibilityLabel: "Address and Search")
    }

    func testAboutHomeDisposed() {
        // about:home is already active on startup; grab a reference to it.
        let browserViewController = UIApplication.sharedApplication().keyWindow!.rootViewController!
        weak var aboutHomeController = getChildViewController(browserViewController, childClass: "HomePanelViewController")

        // Change the page to make about:home go away.
        tester().tapViewWithAccessibilityLabel("URL")
        let url = "\(webRoot)/?page=1"
        tester().clearTextFromAndThenEnterText("\(url)\n", intoViewWithAccessibilityLabel: "Address and Search")

        tester().runBlock { _ in
            return (aboutHomeController == nil) ? KIFTestStepResult.Success : KIFTestStepResult.Wait
        }
        XCTAssertNil(aboutHomeController, "about:home controller disposed")
    }

    func testSearchViewControllerDisposed() {
        // Type the URL to make the search controller appear.
        tester().tapViewWithAccessibilityLabel("URL")
        let url = "\(webRoot)/?page=1"
        tester().clearTextFromAndThenEnterText(url, intoViewWithAccessibilityLabel: "Address and Search")
        let browserViewController = UIApplication.sharedApplication().keyWindow!.rootViewController!
        weak var searchViewController = getChildViewController(browserViewController, childClass: "SearchViewController")
        XCTAssertNotNil(searchViewController, "Got search controller reference")

        // Submit to close about:home and the search controller.
        tester().enterTextIntoCurrentFirstResponder("\n")

        tester().runBlock { _ in
            return (searchViewController == nil) ? KIFTestStepResult.Success : KIFTestStepResult.Wait
        }
        XCTAssertNil(searchViewController, "Search controller disposed")
    }

    func testTabTrayDisposed() {
        let browserViewController = UIApplication.sharedApplication().keyWindow!.rootViewController!

        // Enter the tab tray.
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        tester().waitForViewWithAccessibilityLabel("Tabs Tray")
        weak var tabTrayController = browserViewController.presentedViewController
        weak var tabCell = tester().waitForTappableViewWithAccessibilityLabel("about:home")
        XCTAssertNotNil(tabTrayController, "Got tab tray reference")
        XCTAssertNotNil(tabCell, "Got tab cell reference")

        // Leave the tab tray.
        tester().tapViewWithAccessibilityLabel("about:home")

        tester().runBlock { _ in
            return (tabTrayController == nil) ? KIFTestStepResult.Success : KIFTestStepResult.Wait
        }
        XCTAssertNil(tabTrayController, "Tab tray controller disposed")

        tester().runBlock { _ in
            return (tabCell == nil) ? KIFTestStepResult.Success : KIFTestStepResult.Wait
        }
        XCTAssertNil(tabCell, "Tab tray cell disposed")
    }

    private func getChildViewController(parent: UIViewController, childClass: String) -> UIViewController {
        let childControllers = parent.childViewControllers.filter { child in
            let description = NSString(string: child.description)
            return description.containsString(childClass)
        }
        XCTAssertEqual(childControllers.count, 1, "Found 1 child controller of type: \(childClass)")
        return childControllers.first as! UIViewController
    }
}
