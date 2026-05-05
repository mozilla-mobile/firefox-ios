// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class PhotonActionSheetScreen {
    private let app: XCUIApplication
    private let sel: PhotonActionSheetSelectorsSet

    init(app: XCUIApplication, selectors: PhotonActionSheetSelectorsSet = PhotonActionSheetSelectors()) {
        self.app = app
        self.sel = selectors
    }

    private func assertShareViewLoaded(timeout: TimeInterval = TIMEOUT) {
        let shareViewNavBar = sel.PHOTON_ACTION_SHEET_SHARE_VIEW.element(in: app)
        BaseTestCase().mozWaitForElementToExist(shareViewNavBar, timeout: timeout)
    }

    func assertPhotonActionSheetExists(timeout: TimeInterval = TIMEOUT) {
        if #unavailable(iOS 16) {
            BaseTestCase().waitForElementsToExist(
                [
                    sel.PHOTON_ACTION_SHEET_NAVIGATION_BAR.element(in: app),
                    sel.PHOTON_ACTION_SHEET_COPY_BUTTON.element(in: app)
                ]
            )
        } else {
            let activityListView = sel.ACTIVITY_LIST_VIEW.element(in: app)
            BaseTestCase().waitForElementsToExist(
                [
                    activityListView.otherElements[sel.PHOTON_ACTION_SHEET_WEBSITE_TITLE.value],
                    activityListView.otherElements[sel.PHOTON_ACTION_SHEET_WEBSITE_URL.value],
                    sel.PHOTON_ACTION_SHEET_COPY_BUTTON.element(in: app)
                ]
            )
        }
    }

    func tapFennecIcon() {
        var fennecElement = sel.PHOTON_ACTION_SHEET_FENNEC_ICON.element(in: app)
        // This is not ideal but only way to get the element on iPhone 8
        // for iPhone 11, that would be boundBy: 2
        if #unavailable(iOS 17) {
            fennecElement = app.collectionViews.scrollViews.cells
                .matching(identifier: "XCElementSnapshotPrivilegedValuePlaceholder").element(boundBy: 1)
        }
        fennecElement.waitAndTap()
        // Wait for ShareView to load after tapping Fennec
        assertShareViewLoaded()
    }

    func assertShareViewExists(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().waitForElementsToExist(
            [
                sel.SHARE_VIEW_OPEN_IN_FIREFOX.element(in: app),
                sel.SHARE_VIEW_LOAD_IN_BACKGROUND.element(in: app),
                sel.SHARE_VIEW_BOOKMARK_THIS_PAGE.element(in: app),
                sel.SHARE_VIEW_ADD_TO_READING_LIST.element(in: app),
                sel.SHARE_VIEW_SEND_TO_DEVICE.element(in: app)
            ]
        )
    }
}
