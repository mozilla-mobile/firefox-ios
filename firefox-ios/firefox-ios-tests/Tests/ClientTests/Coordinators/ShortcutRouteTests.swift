// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

@MainActor
final class ShortcutRouteTests: XCTestCase {
    func testNewTabShortcut() {
        let subject = createSubject()
        let shortcutItem = UIApplicationShortcutItem(type: "com.example.app.NewTab",
                                                     localizedTitle: "New Tab")

        let route = subject.makeRoute(shortcutItem: shortcutItem, tabSetting: .blankPage)

        switch route {
        case .search(let url, let isPrivate, let options):
            XCTAssertNil(url)
            XCTAssertFalse(isPrivate)
            XCTAssertEqual(options, [.focusLocationField])
        default:
            XCTFail("The route should be a search route")
        }
    }

    func testNewPrivateTabShortcut() {
        let subject = createSubject()
        let shortcutItem = UIApplicationShortcutItem(type: "com.example.app.NewPrivateTab",
                                                     localizedTitle: "New Private Tab")

        let route = subject.makeRoute(shortcutItem: shortcutItem, tabSetting: .blankPage)

        switch route {
        case .search(let url, let isPrivate, let options):
            XCTAssertNil(url)
            XCTAssertTrue(isPrivate)
            XCTAssertEqual(options, [.focusLocationField])
        default:
            XCTFail("The route should be a search route")
        }
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

        switch route {
        case .search(let url, let isPrivate, _):
            XCTAssertEqual(url, URL(string: "https://www.example.com")!)
            XCTAssertFalse(isPrivate)
        default:
            XCTFail("The route should be a search route")
        }
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
        switch route {
        case .action(let action):
            XCTAssertEqual(action, .showQRCode)
        default:
            XCTFail("Expected .action(.showQRCode)")
        }
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
