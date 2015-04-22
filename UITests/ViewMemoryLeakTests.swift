/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

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

    func testAboutHome() {
        let browserViewController = UIApplication.sharedApplication().keyWindow!.rootViewController!
        XCTAssertEqual(browserViewController.childViewControllers.count, 1, "about:home controller active")

        // about:home is already active on startup; grab a reference to it.
        weak var aboutHomeController = browserViewController.childViewControllers.first as? UIViewController
        XCTAssertNotNil(aboutHomeController, "Got search controller reference")

        // Change the page to make about:home go away.
        tester().tapViewWithAccessibilityLabel("URL")
        let url = "\(webRoot)/?page=1"
        tester().clearTextFromAndThenEnterText("\(url)\n", intoViewWithAccessibilityLabel: "Address and Search")

        tester().runBlock { _ in
            return (aboutHomeController == nil) ? KIFTestStepResult.Success : KIFTestStepResult.Wait
        }
        XCTAssertNil(aboutHomeController, "about:home controller disposed")
    }

    func testSearchViewController() {
        let browserViewController = UIApplication.sharedApplication().keyWindow!.rootViewController!
        XCTAssertEqual(browserViewController.childViewControllers.count, 1, "about:home controller active")

        // Type the URL to make the search controller appear.
        tester().tapViewWithAccessibilityLabel("URL")
        let url = "\(webRoot)/?page=1"
        tester().clearTextFromAndThenEnterText(url, intoViewWithAccessibilityLabel: "Address and Search")
        XCTAssertEqual(browserViewController.childViewControllers.count, 2, "about:home and search controllers active")
        weak var searchViewController = browserViewController.childViewControllers[1] as? UIViewController
        XCTAssertNotNil(searchViewController, "Got search controller reference")

        // Submit to close about:home and the search controller.
        tester().enterTextIntoCurrentFirstResponder("\n")

        tester().runBlock { _ in
            return (searchViewController == nil) ? KIFTestStepResult.Success : KIFTestStepResult.Wait
        }
        XCTAssertNil(searchViewController, "Search controller disposed")
    }

    func testTabTray() {
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
}
