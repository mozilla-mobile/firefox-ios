/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest
import Storage
@testable import Client

class LoginTableViewCellRefTests: FBSnapshotTestCase {
    let defaultFrame = CGRect(origin: CGPointZero, size: CGSize(width: 320, height: 64))
    let compressedFrame = CGRect(origin: CGPointZero, size: CGSize(width: 160, height: 64))
    let stretchedFrame = CGRect(origin: CGPointZero, size: CGSize(width: 728, height: 64))

    var cell: LoginTableViewCell!
    let mockLogin = Login.createWithHostname("alphabet.com", username: "myawesomeusername@email.com", password: "hunter2")

    override func setUp() {
        super.setUp()
        if NSProcessInfo.processInfo().environment["RECORD_SNAPSHOTS"] == "YES" {
            recordMode = true
        }
        cell = LoginTableViewCell(frame: defaultFrame)
    }

    func testDefaultCellLayout() {
        cell.updateCellWithLogin(mockLogin)
        cell.layoutIfNeeded()
        FBSnapshotVerifyView(cell!)
    }

    func testCellNoIconBothLabelsLayout() {
        cell.style = .NoIconAndBothLabels
        cell.updateCellWithLogin(mockLogin)
        cell.layoutIfNeeded()
        FBSnapshotVerifyView(cell!)
    }

    func testCellIconAndDescriptionLayout() {
        cell.style = .IconAndDescriptionLabel
        cell.updateCellWithLogin(mockLogin)
        cell.layoutIfNeeded()
        FBSnapshotVerifyView(cell!)
    }

    func testCellIconAndBothLabelsLayout() {
        cell.style = .IconAndBothLabels
        cell.updateCellWithLogin(mockLogin)
        cell.layoutIfNeeded()
        FBSnapshotVerifyView(cell!)
    }

    func testCompressedDefaultCellLayout() {
        cell.frame = compressedFrame
        cell.updateCellWithLogin(mockLogin)
        cell.layoutIfNeeded()
        FBSnapshotVerifyView(cell!)
    }

    func testCompressedNoIconBothLabelsLayout() {
        cell.frame = compressedFrame
        cell.style = .NoIconAndBothLabels
        cell.updateCellWithLogin(mockLogin)
        cell.layoutIfNeeded()
        FBSnapshotVerifyView(cell!)
    }

    func testCompressedIconAndDescriptionLayout() {
        cell.frame = compressedFrame
        cell.style = .IconAndDescriptionLabel
        cell.updateCellWithLogin(mockLogin)
        cell.layoutIfNeeded()
        FBSnapshotVerifyView(cell!)
    }

    func testCompressedIconAndBothLabelsLayout() {
        cell.frame = compressedFrame
        cell.style = .IconAndBothLabels
        cell.updateCellWithLogin(mockLogin)
        cell.layoutIfNeeded()
        FBSnapshotVerifyView(cell!)
    }

    func testStretchedDefaultCellLayout() {
        cell.frame = stretchedFrame
        cell.updateCellWithLogin(mockLogin)
        cell.layoutIfNeeded()
        FBSnapshotVerifyView(cell!)
    }

    func testStretchedNoIconBothLabelsLayout() {
        cell.frame = stretchedFrame
        cell.style = .NoIconAndBothLabels
        cell.updateCellWithLogin(mockLogin)
        cell.layoutIfNeeded()
        FBSnapshotVerifyView(cell!)
    }

    func testStretchedIconAndDescriptionLayout() {
        cell.frame = stretchedFrame
        cell.style = .IconAndDescriptionLabel
        cell.updateCellWithLogin(mockLogin)
        cell.layoutIfNeeded()
        FBSnapshotVerifyView(cell!)
    }

    func testStretchedIconAndBothLabelsLayout() {
        cell.frame = stretchedFrame
        cell.style = .IconAndBothLabels
        cell.updateCellWithLogin(mockLogin)
        cell.layoutIfNeeded()
        FBSnapshotVerifyView(cell!)
    }
}