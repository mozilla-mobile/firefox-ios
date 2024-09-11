// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class LegacyTabPeekPreviewActionBuilderTests: XCTestCase {
    var builder: LegacyTabPeekPreviewActionBuilder!

    override func setUp() {
        super.setUp()
        builder = LegacyTabPeekPreviewActionBuilder()
    }

    override func tearDown() {
        super.tearDown()
        builder = nil
    }

    func test_count_afterBuilderIsInstantiated_shouldBeZero() {
        let result = builder.count

        XCTAssertEqual(result, 0)
    }

    func test_addBookmark_afterAdded_shouldContainsInActions() {
        builder.addBookmark { _, __ in }

        let action = builder.build().first ?? UIPreviewAction()
        XCTAssertEqual(action.title, String.TabPeekAddToBookmarks)
    }

    func test_addSendToDeviceTitle_afterAdded_shouldContainsInActions() {
        builder.addSendToDeviceTitle { _, __ in }

        let action = builder.build().first ?? UIPreviewAction()
        XCTAssertEqual(action.title, String.LegacyAppMenu.TouchActions.SendToDeviceTitle)
    }

    func test_addCopyUrl_afterAdded_shouldContainsInActions() {
        builder.addCopyUrl { _, __ in }

        let action = builder.build().first ?? UIPreviewAction()
        XCTAssertEqual(action.title, String.TabPeekCopyUrl)
    }

    func test_addCloseTab_afterAdded_shouldContainsInActions() {
        builder.addCloseTab { _, __ in }

        let action = builder.build().first ?? UIPreviewAction()
        XCTAssertEqual(action.title, String.TabPeekCloseTab)
    }

    func test_build_afterAddedAllActions_shouldContains4Actions() {
        builder.addBookmark { _, __ in }
        builder.addSendToDeviceTitle { _, __ in }
        builder.addCopyUrl { _, __ in }
        builder.addCloseTab { _, __ in }

        let actions = builder.build()

        XCTAssertEqual(actions.count, 4)
    }
}
