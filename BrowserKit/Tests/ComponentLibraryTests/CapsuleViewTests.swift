// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import XCTest

@testable import ComponentLibrary

@MainActor
final class CapsuleViewTests: XCTestCase {
    func test_cornerRadius_isHalfTheHeight() {
        let subject = CapsuleView()

        subject.frame = CGRect(x: 0, y: 0, width: 120, height: 40)
        subject.layoutIfNeeded()

        XCTAssertEqual(subject.layer.cornerRadius, 20)
    }

    func test_cornerRadius_updatesWhenBoundsChange() {
        let subject = CapsuleView()
        subject.frame = CGRect(x: 0, y: 0, width: 120, height: 40)
        subject.layoutIfNeeded()

        subject.frame = CGRect(x: 0, y: 0, width: 120, height: 60)
        subject.layoutIfNeeded()

        XCTAssertEqual(subject.layer.cornerRadius, 30)
    }
}
