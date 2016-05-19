/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
@testable import Client

class ErrorToastRefTests: FXSnapshotTestCase {
    let defaultFrame = CGRect(origin: CGPointZero, size: CGSize(width: 320, height: 64))
    let compressedFrame = CGRect(origin: CGPointZero, size: CGSize(width: 160, height: 64))
    let stretchedFrame = CGRect(origin: CGPointZero, size: CGSize(width: 728, height: 64))

    var toast: ErrorToast!

    override func setUp() {
        super.setUp()
        toast = ErrorToast(frame: CGRectZero)
    }

    func testDefaultCellLayout() {
        toast.textLabel.text = "Incorrect passcode. Try again."
        toast.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
        toast.frame = CGRect(origin: CGPointZero, size: toast.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize))
        toast.layoutIfNeeded()
        FBSnapshotVerifyView(toast!)
    }
}
