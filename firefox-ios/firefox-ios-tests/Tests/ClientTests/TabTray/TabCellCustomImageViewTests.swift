// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class TabCellCustomImageTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        await DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    @MainActor
    func testUpdateContentsRect_SquareImageInSquareView() {
        let size = CGSize(width: 100, height: 100)
        let subject = createSubject()
        subject.frame = CGRect(origin: .zero, size: size)
        subject.image = createTestImage(size: size)

        subject.layoutSubviews()

        XCTAssertEqual(subject.layer.contentsRect.height, 1.0, accuracy: 0.001)
        XCTAssertEqual(subject.layer.contentsRect.origin.y, 0, "Image should be alligned from top")
    }

    // MARK: - Helper
    private func createTestImage(size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }

    // MARK: - Subject
    @MainActor
    private func createSubject() -> TabCellCustomImage {
        let subject = TabCellCustomImage()
        trackForMemoryLeaks(subject)
        return subject
    }
}
