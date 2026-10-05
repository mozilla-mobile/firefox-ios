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

    func assertShareSheetExists(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(sel.ACTIVITY_LIST_VIEW.element(in: app), timeout: timeout)
    }

    func assertShareSheetDismissed(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToNotExist(sel.ACTIVITY_LIST_VIEW.element(in: app), timeout: timeout)
    }

    /// Asserts the share sheet header names the shared document. The sheet first shows a placeholder with
    /// the full file name ("lorem_ipsum.pdf"), so the extension is ignored when comparing.
    func assertShareSheetDocumentName(_ name: String, timeout: TimeInterval = TIMEOUT) {
        let caption = waitForHeaderCaption(sel.SHARE_SHEET_TOP_CAPTION, index: 0, timeout: timeout) {
            documentName(in: $0) == name
        } ?? ""
        XCTAssertEqual(documentName(in: caption), name, "The share sheet should name the document currently displayed")
    }

    func assertShareSheetDocumentNameIsNot(_ name: String, timeout: TimeInterval = TIMEOUT) {
        let caption = waitForHeaderCaption(sel.SHARE_SHEET_TOP_CAPTION, index: 0, timeout: timeout) ?? ""
        XCTAssertNotEqual(
            documentName(in: caption),
            name,
            "The share sheet should not still name a previously shared document"
        )
    }

    /// Asserts the sheet offers the document as a PDF file rather than as a web page link.
    func assertShareSheetOffersPdfDocument(timeout: TimeInterval = TIMEOUT) {
        let caption = waitForHeaderCaption(sel.SHARE_SHEET_BOTTOM_CAPTION, index: 1, timeout: timeout) {
            $0.contains("PDF")
        } ?? ""
        XCTAssertTrue(
            caption.contains("PDF"),
            "The share sheet should describe the shared item as a PDF document, found: \(caption)"
        )
    }

    /// Strips the file extension: "lorem_ipsum.pdf" becomes "lorem_ipsum".
    private func documentName(in caption: String) -> String {
        return (caption as NSString).deletingPathExtension
    }

    /// Re-reads a header caption until `isExpected` accepts it, because the header starts as a placeholder.
    /// On timeout it returns the last caption read, so the caller's assertion reports what was on screen.
    private func waitForHeaderCaption(
        _ selector: Selector,
        index: Int,
        timeout: TimeInterval,
        until isExpected: (String) -> Bool = { _ in true }
    ) -> String? {
        let deadline = Date().addingTimeInterval(timeout)
        var lastCaption: String?
        repeat {
            lastCaption = readHeaderCaption(selector, index: index) ?? lastCaption
            if let caption = lastCaption, isExpected(caption) { return caption }
            usleep(100_000)
        } while Date() < deadline
        if lastCaption == nil {
            XCTFail("Timed out waiting for share sheet header caption \(index) in \(timeout) seconds")
        }
        return lastCaption
    }

    /// Reads a header caption once. iOS 26 tags captions with `selector`'s identifier; older iOS leaves them
    /// untagged, so fall back to the header's `index`-th labelled leaf (name, then kind and size).
    private func readHeaderCaption(_ selector: Selector, index: Int) -> String? {
        let taggedCaption = selector.element(in: app)
        if taggedCaption.exists { return taggedCaption.label }

        let header = sel.SHARE_SHEET_HEADER.element(in: app)
        guard header.exists, let snapshot = try? header.snapshot() else { return nil }
        let captions = labelledLeaves(of: snapshot)
        return captions.count > index ? captions[index] : nil
    }

    private func labelledLeaves(of snapshot: XCUIElementSnapshot) -> [String] {
        guard !snapshot.children.isEmpty else {
            return snapshot.elementType == .other && !snapshot.label.isEmpty ? [snapshot.label] : []
        }
        return snapshot.children.flatMap { labelledLeaves(of: $0) }
    }

    /// Completing an activity does not always tear the sheet down with it, so close it when it is
    /// still on screen and leave the browser interactive again.
    func dismissShareSheetIfPresented(attempts: Int = 3) {
        let sheet = sel.ACTIVITY_LIST_VIEW.element(in: app)
        for _ in 0..<attempts {
            // The sheet usually closes itself shortly after the activity; tapping its dismiss
            // region mid-teardown races with it, so only step in once it has settled on screen.
            if BaseTestCase().mozWaitForElementToNotExist(sheet, timeout: TIMEOUT, failOnTimeout: false) { return }
            // The sheet can linger in the hierarchy after it has gone; stop once no control is left.
            guard dismissShareSheet() else { return }
        }
    }

    /// Dismisses the system share sheet. The collapsed sheet is a popover carrying only a dismiss
    /// region; a Close button appears once it is expanded, and older iOS shows Done instead, which on
    /// iPad sits behind a popover that needs a forced tap.
    /// Returns whether a dismiss control was found and tapped.
    @discardableResult
    func dismissShareSheet() -> Bool {
        // On iOS 26 the dismiss region is present whether the sheet is collapsed or expanded, and unlike
        // the header's Close button it tears the sheet down in both states.
        let dismissRegion = sel.SHARE_SHEET_DISMISS_REGION.element(in: app)
        let close = sel.SHARE_SHEET_CLOSE_BUTTON.element(in: app)
        // Older iOS centres the region on the sheet itself, so tapping it lands on the sheet instead.
        var controls = [dismissRegion, close]
        if #unavailable(iOS 26) { controls.reverse() }
        for control in controls
        where control.mozWaitForElementToExist(timeout: TIMEOUT_PICKER_PROBE, failOnTimeout: false) {
            control.waitAndTap()
            return true
        }
        let done = sel.SHARE_SHEET_DONE_BUTTON.element(in: app)
        guard done.mozWaitForElementToExist(timeout: TIMEOUT_PICKER_PROBE, failOnTimeout: false) else { return false }
        if BaseTestCase().iPad() {
            done.tap(force: true)
        } else {
            done.waitAndTap()
        }
        return true
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
