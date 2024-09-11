// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class ShortcutRouteTests: XCTestCase {
    func testNewTabShortcut() {
        let subject = createSubject()
        let shortcutItem = UIApplicationShortcutItem(type: "com.example.app.NewTab",
                                                     localizedTitle: "New Tab")

        let route = subject.makeRoute(shortcutItem: shortcutItem, tabSetting: .blankPage)

        XCTAssertEqual(route, .search(url: nil, isPrivate: false, options: [.focusLocationField]))
    }

    func testNewPrivateTabShortcut() {
        let subject = createSubject()
        let shortcutItem = UIApplicationShortcutItem(type: "com.example.app.NewPrivateTab",
                                                     localizedTitle: "New Private Tab")

        let route = subject.makeRoute(shortcutItem: shortcutItem, tabSetting: .blankPage)

        XCTAssertEqual(route, .search(url: nil, isPrivate: true, options: [.focusLocationField]))
    }

    func testOpenLastBookmarkShortcutWithValidUrl() {
        let subject = createSubject()
        let userInfo = [QuickActionInfos.tabURLKey: "https://www.example.com" as NSSecureCoding]
        let shortcutItem = UIApplicationShortcutItem(type: "com.example.app.OpenLastBookmark",
                                                     localizedTitle: "Open Last Bookmark",
                                                     localizedSubtitle: nil,
                                                     icon: nil,
                                                     userInfo: userInfo)

        let route = subject.makeRoute(shortcutItem: shortcutItem, tabSetting: .blankPage)

        XCTAssertEqual(route, .search(url: URL(string: "https://www.example.com"),
                                      isPrivate: false,
                                      options: [.switchToNormalMode]))
    }

    // FXIOS-8107: Disabled test as history highlights has been disabled to fix app hangs / slowness
    // Reloads for notification
    func testOpenLastBookmarkShortcutWithInvalidUrl() {
        let subject = createSubject()
        let userInfo = [QuickActionInfos.tabURLKey: "not a url" as NSSecureCoding]
        let shortcutItem = UIApplicationShortcutItem(type: "com.example.app.OpenLastBookmark",
                                                     localizedTitle: "Open Last Bookmark",
                                                     localizedSubtitle: nil,
                                                     icon: nil,
                                                     userInfo: userInfo)

        let route = subject.makeRoute(shortcutItem: shortcutItem, tabSetting: .blankPage)

        XCTAssertNil(route)
    }

    func testQRCodeShortcut() {
        let subject = createSubject()
        let shortcutItem = UIApplicationShortcutItem(type: "com.example.app.QRCode",
                                                     localizedTitle: "QR Code")
        let route = subject.makeRoute(shortcutItem: shortcutItem, tabSetting: .blankPage)
        XCTAssertEqual(route, .action(action: .showQRCode))
    }

    func testInvalidShortcut() {
        let subject = createSubject()
        let shortcutItem = UIApplicationShortcutItem(type: "invalid shortcut",
                                                     localizedTitle: "Invalid Shortcut")

        let route = subject.makeRoute(shortcutItem: shortcutItem, tabSetting: .blankPage)

        XCTAssertNil(route)
    }

    // MARK: - Helper

    func createSubject() -> RouteBuilder {
        let subject = RouteBuilder()
        subject.configure(isPrivate: false, prefs: MockProfile().prefs)
        trackForMemoryLeaks(subject)
        return subject
    }
}
