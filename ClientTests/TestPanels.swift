/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import XCTest

class TestPanels: ProfileTest {
    func testPanels() {
        withTestProfile { profile -> Void in
            self.validatePrefs(profile, expectOrder: nil, expectEnabled: nil);
            
            var panels = Panels(profile: profile)
            XCTAssertEqual(panels.count, 4, "Right number of panels found");
            
            // Test moving an item
            var a = panels[0];
            var b = panels[1];
            self.expectNotification("Moving an item should notify us") { () -> Void in
                panels.moveItem(1, to: 0);
            }
            self.validatePrefs(profile, expectOrder: ["Bookmarks", "Tabs", "History", "Reader"],
                expectEnabled: [true, true, true, true, true]);
            
            XCTAssertNotEqual(a!.title, panels[0]!.title, "Original panel is not in place any more")
            XCTAssertEqual(a!.title, panels[1]!.title, "Original panel was moved")
            XCTAssertEqual(b!.title, panels[0]!.title, "Second panel was moved")
            self.expectNotification("Moving an item should notify us") { () -> Void in
                panels.moveItem(1, to: 0);
            }
            self.validatePrefs(profile, expectOrder: ["Tabs", "Bookmarks", "History", "Reader"],
                expectEnabled: [true, true, true, true, true]);
            
            // Tests enabling/disabling items
            var enabledPanels = panels.enabledItems;
            XCTAssertEqual(enabledPanels.count, 4, "Right number of enabled panels found");
            self.expectNotification("Disabling a panel should fire a notification") { () -> Void in
                panels.enablePanelAt(false, position: 0);
            }
            self.validatePrefs(profile, expectOrder: ["Tabs", "Bookmarks", "History", "Reader"],
                expectEnabled: [false, true, true, true, true]);
            
            XCTAssertEqual(enabledPanels.count, 4, "Right number of enabled panels found"); // Still holding a old reference
            enabledPanels = panels.enabledItems;
            XCTAssertEqual(enabledPanels.count, 3, "Right number of enabled panels found");
            XCTAssertEqual(panels.count, 4, "Total panels shouldn't change");
            self.expectNotification("Enabling a panel should fire a notification") { () -> Void in
                panels.enablePanelAt(true, position: 0);
            }
            self.validatePrefs(profile, expectOrder: ["Tabs", "Bookmarks", "History", "Reader"],
                expectEnabled: [true, true, true, true, true]);
        }
    }

    private func expectNotification(description: String, method: () -> Void) {
        var expectation = expectationWithDescription(description)
        var fulfilled = false
        var token :AnyObject?
        token = NSNotificationCenter.defaultCenter().addObserverForName(PanelsNotificationName, object: nil, queue: nil) { notif in
            if (token != nil) {
                fulfilled = true
                NSNotificationCenter.defaultCenter().removeObserver(token!)
                expectation.fulfill()
            } else {
                XCTAssert(false, "notification before observer was even added?")
            }
        }

        method()
        waitForExpectationsWithTimeout(10.0, handler:nil)
        XCTAssertTrue(fulfilled, "Received notification of change")
    }
    
    private func validatePrefs<T : AnyObject>(prefs: ProfilePrefs, data: [T]?, key: String) {
        if var data2 = prefs.arrayForKey(key) as? [T] {
            if (data != nil) {
                XCTAssertTrue(true, "Should find \(key) prefs");
            } else {
                XCTAssertTrue(false, "Should not find \(key) prefs but did");
            }
        } else {
            if (data != nil) {
                XCTAssertTrue(false, "Should find \(key) prefs but didn't");
            } else {
                XCTAssertTrue(true, "Should not find \(key) prefs");
            }
        }
    }
    
    private func validatePrefs(profile: Profile, expectOrder: [String]?, expectEnabled: [Bool]?) {
        let prefs = profile.prefs
        validatePrefs(prefs, data: expectOrder, key: "PANELS_ORDER");
        validatePrefs(prefs, data: expectEnabled, key: "PANELS_ENABLED");
    }
}
