/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
@testable import Client

class URLToolbarRefTests: FXSnapshotTestCase {
    let defaultFrame = CGRect(origin: CGPointZero, size: CGSize(width: 320, height: 44))
    let ipadPortrait = CGRect(origin: CGPointZero, size: CGSize(width: 728, height: 44))

    var toolbar: URLToolbar!

    override func setUp() {
        super.setUp()
        toolbar = URLToolbar(frame: defaultFrame)
    }

    func testDefaultLayout() {
        toolbar.setNeedsLayout()
        toolbar.layoutIfNeeded()
        FBSnapshotVerifyView(toolbar)
    }

    func testDefaultLayout_iPadPortrait() {
        toolbar = URLToolbar(frame: ipadPortrait)
        toolbar.curveRightButtons = [ToolbarButton()]
        toolbar.insideRightButtons = [.shareButton()]
        toolbar.insideLeftButtons = [.backButton(), .forwardButton(), .reloadButton()]

        toolbar.setNeedsLayout()
        toolbar.layoutIfNeeded()
        FBSnapshotVerifyView(toolbar)
    }

    func testPanelIconLayout_iPadPortrait() {
        toolbar = URLToolbar(frame: ipadPortrait)
        toolbar.insideRightButtons = [
            .topSitesPanelButton(),
            .bookmarksPanelButton(),
            .historyPanelButton(),
            .syncedTabsPanelButton(),
            .readingListPanelButton()
        ]
        toolbar.rightToolbarSpacing = 20

        toolbar.setNeedsLayout()
        toolbar.layoutIfNeeded()
        FBSnapshotVerifyView(toolbar)
    }
}
