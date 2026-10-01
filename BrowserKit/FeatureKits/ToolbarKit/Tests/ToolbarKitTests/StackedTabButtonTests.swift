// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import ToolbarKit

@MainActor
final class StackedTabButtonTests: XCTestCase {
    private var button: StackedTabButton!
    private var previousImage: UIImage!
    private var nextImage: UIImage!

    override func setUp() async throws {
        try await super.setUp()
        button = StackedTabButton()
        previousImage = UIImage(systemName: "square.stack")
        nextImage = UIImage(systemName: "square.stack.fill")
    }

    override func tearDown() async throws {
        button = nil
        previousImage = nil
        nextImage = nil
        try await super.tearDown()
    }

    // MARK: - Screenshot Handling
    func testConfigure_withBothScreenshots_setsImages() {
        button.configure(element: makeElement(previousTabScreenshot: previousImage, nextTabScreenshot: nextImage))

        XCTAssertEqual(button.topImageView.image, nextImage)
        XCTAssertEqual(button.bottomImageView.image, previousImage)
    }

    func testConfigure_withNilScreenshots_clearsImages() {
        button.configure(element: makeElement())

        XCTAssertNil(button.topImageView.image)
        XCTAssertNil(button.bottomImageView.image)
    }

    // MARK: - Gradient Opacity
    func testConfigure_withScreenshots_hidesGradients() {
        button.configure(element: makeElement(previousTabScreenshot: previousImage, nextTabScreenshot: nextImage))

        XCTAssertEqual(button.topImageViewGradient.opacity, 0)
        XCTAssertEqual(button.bottomImageViewGradient.opacity, 0)
    }

    func testConfigure_withNilScreenshots_showsGradients() {
        button.configure(element: makeElement())

        XCTAssertEqual(button.topImageViewGradient.opacity, 1)
        XCTAssertEqual(button.bottomImageViewGradient.opacity, 1)
    }

    // MARK: - Helper
    private func makeElement(
        previousTabScreenshot: UIImage? = nil,
        nextTabScreenshot: UIImage? = nil
    ) -> ToolbarElement {
        return ToolbarElement(
            isEnabled: true,
            a11yLabel: "Tabs",
            a11yHint: nil,
            a11yId: "testId",
            hasLongPressAction: false,
            previousTabScreenshot: previousTabScreenshot,
            nextTabScreenshot: nextTabScreenshot,
            onSelected: nil
        )
    }
}
