/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
@testable import Client

class SearchInputViewRefTests: FBSnapshotTestCase {

    let defaultFrame = CGRect(origin: CGPointZero, size: CGSize(width: 320, height: 64))
    let compressedFrame = CGRect(origin: CGPointZero, size: CGSize(width: 160, height: 64))
    let stretchedFrame = CGRect(origin: CGPointZero, size: CGSize(width: 728, height: 64))
    let longText = "superduperverylongusernamethatshouldntfit"

    var view: SearchInputView!

    override func setUp() {
        super.setUp()
        if let shouldRecord = NSProcessInfo.processInfo().environment["RECORD_SNAPSHOTS"] where shouldRecord == "YES" {
            recordMode = true
        }
        view = SearchInputView(frame: defaultFrame)
    }

    func testDefault() {
        FBSnapshotVerifyView(view)
    }

    func testDefaultTappedView() {
        view.performSelector("SELtappedSearch")
        view.layoutIfNeeded()
        FBSnapshotVerifyView(view)
    }

    func testDefaultShortInputedText() {
        view.performSelector("SELtappedSearch")
        view.layoutIfNeeded()
        view.inputField.text = "username"
        FBSnapshotVerifyView(view)
    }

    func testDefaultLongInputedText() {
        view.performSelector("SELtappedSearch")
        view.layoutIfNeeded()
        view.inputField.text = longText
        view.inputField.becomeFirstResponder()
        FBSnapshotVerifyView(view)
    }

    func testStretched() {
        view.frame = stretchedFrame
        view.layoutIfNeeded()
        FBSnapshotVerifyView(view)
    }

    func testStretchedTapped() {
        view.frame = stretchedFrame
        view.performSelector("SELtappedSearch")
        view.layoutIfNeeded()
        FBSnapshotVerifyView(view)
    }

    func testStretchedWithText() {
        view.frame = stretchedFrame
        view.performSelector("SELtappedSearch")
        view.layoutIfNeeded()
        view.inputField.text = longText
        FBSnapshotVerifyView(view)
    }

    func testCompressed() {
        view.frame = compressedFrame
        view.layoutIfNeeded()
        FBSnapshotVerifyView(view)
    }

    func testCompressedTapped() {
        view.frame = compressedFrame
        view.performSelector("SELtappedSearch")
        view.layoutIfNeeded()
        FBSnapshotVerifyView(view)
    }

    func testCompressedWithText() {
        view.frame = compressedFrame
        view.performSelector("SELtappedSearch")
        view.layoutIfNeeded()
        view.inputField.text = longText
        FBSnapshotVerifyView(view)
    }
}

