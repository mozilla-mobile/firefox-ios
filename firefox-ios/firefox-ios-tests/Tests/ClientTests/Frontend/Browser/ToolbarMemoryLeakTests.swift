// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
final class ToolbarMemoryLeakTests: XCTestCase {
    func testAddressToolbarContainer_addToParent_doesNotRetainParent() {
        let parent = UIStackView()
        let subject = AddressToolbarContainer()

        subject.addToParent(parent: parent)

        trackForMemoryLeaks(parent)
        trackForMemoryLeaks(subject)
    }

    func testReaderModeBarView_addToParent_doesNotRetainParent() {
        let parent = UIStackView()
        let subject = ReaderModeBarView(frame: .zero)

        subject.addToParent(parent: parent)

        trackForMemoryLeaks(parent)
        trackForMemoryLeaks(subject)
    }
}
