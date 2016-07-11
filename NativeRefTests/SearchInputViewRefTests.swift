/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
@testable import Client

class SearchInputViewRefTests: FXSnapshotTestCase {

    let defaultFrame = CGRect(origin: CGPoint.zero, size: CGSize(width: 320, height: 64))
    let compressedFrame = CGRect(origin: CGPoint.zero, size: CGSize(width: 160, height: 64))
    let stretchedFrame = CGRect(origin: CGPoint.zero, size: CGSize(width: 728, height: 64))
    let longText = "superduperverylongusernamethatshouldntfit"

    var view: SearchInputView!

    override func setUp() {
        super.setUp()
        view = SearchInputView(frame: defaultFrame)
    }

    func testDefault() {
        FBSnapshotVerifyView(view)
    }

    func testDefaultTappedView() {
        view.performSelector(#selector(SearchInputView.tappedSearch))
        view.layoutIfNeeded()
        FBSnapshotVerifyView(view)
    }

    func testDefaultShortInputedText() {
        view.performSelector(#selector(SearchInputView.tappedSearch))
        view.layoutIfNeeded()
        view.inputField.text = "username"
        FBSnapshotVerifyView(view)
    }

    func testDefaultLongInputedText() {
        view.performSelector(#selector(SearchInputView.tappedSearch))
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
        view.performSelector(#selector(SearchInputView.tappedSearch))
        view.layoutIfNeeded()
        view.layoutIfNeeded()
        FBSnapshotVerifyView(view)
    }

    func testStretchedWithText() {
        view.frame = stretchedFrame
        view.performSelector(#selector(SearchInputView.tappedSearch))
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
        view.performSelector(#selector(SearchInputView.tappedSearch))
        view.layoutIfNeeded()
        FBSnapshotVerifyView(view)
    }

    func testCompressedWithText() {
        view.frame = compressedFrame
        view.performSelector(#selector(SearchInputView.tappedSearch))
        view.layoutIfNeeded()
        view.inputField.text = longText
        FBSnapshotVerifyView(view)
    }
}

