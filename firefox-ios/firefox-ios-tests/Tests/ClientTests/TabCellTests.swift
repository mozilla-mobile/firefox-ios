// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import XCTest

@testable import Client

@MainActor
class TabCellTests: XCTestCase {
    var cellDelegate: MockTabCellDelegate!
    var profile: MockProfile!

    override func setUp() async throws {
        try await super.setUp()
        cellDelegate = MockTabCellDelegate()
        profile = makeProfile()
    }

    override func tearDown() async throws {
        cellDelegate = nil
        profile = nil

        try await super.tearDown()
    }

    func testTabCellDeinit() {
        let subject = TabCell(frame: .zero)
        trackForMemoryLeaks(subject)
    }

    func testConfigureTabAXLabel() {
        let cell = TabCell(frame: .zero)
        let state = createDefaultState()
        cell.configure(with: state, theme: nil, delegate: cellDelegate, a11yId: "", newTabTitle: nil)
        XCTAssert(cell.accessibilityLabel!.contains(state.tabTitle))
    }

    func testConfigureTabAXHint() {
        let cell = TabCell(frame: .zero)
        let state = createDefaultState()
        cell.configure(with: state, theme: nil, delegate: cellDelegate, a11yId: "", newTabTitle: nil)
        XCTAssertEqual(cell.accessibilityHint!,
                       .TabsTray.TabTraySwipeToCloseAccessibilityHint)
    }

    func testConfigureTabSelectedState() {
        let cell = TabCell(frame: .zero)
        let state = createDefaultState()
        cell.configure(with: state, theme: nil, delegate: cellDelegate, a11yId: "", newTabTitle: nil)
        XCTAssertEqual(cell.isSelectedTab,
                       state.isSelected)
    }

    func testSelectedGroupGradient_tabCellRedrawsAfterResizeAndClearsOnReuse() throws {
        let subject = TabCell(frame: CGRect(x: 0, y: 0, width: 160, height: 220))
        trackForMemoryLeaks(subject)
        subject.configure(with: createDefaultState(isSelected: true),
                          theme: NovaLightTheme(),
                          delegate: cellDelegate,
                          a11yId: "tab",
                          newTabTitle: nil,
                          selectedGroupColor: .red,
                          selectedGroupGradient: Gradient(colors: [.red, .blue]))
        subject.layoutIfNeeded()
        let initialBorder = try XCTUnwrap(subject.layer.borderColor)
        XCTAssertEqual(initialBorder.colorSpace?.model, .pattern)

        subject.frame.size.width = 240
        subject.setNeedsLayout()
        subject.layoutIfNeeded()

        XCTAssertNotEqual(subject.layer.borderColor, initialBorder)
        subject.prepareForReuse()
        subject.configure(with: createDefaultState(isSelected: true),
                          theme: LightTheme(),
                          delegate: cellDelegate,
                          a11yId: "reusedTab",
                          newTabTitle: nil)
        subject.layoutIfNeeded()
        XCTAssertEqual(subject.layer.borderColor, LightTheme().colors.borderAccent.cgColor)
    }

    func testSelectedGroupGradient_experimentCellRedrawsAfterResizeAndClearsOnReuse() throws {
        let subject = ExperimentTabCell(frame: CGRect(x: 0, y: 0, width: 160, height: 220))
        trackForMemoryLeaks(subject)
        subject.configure(with: createDefaultState(isSelected: true),
                          theme: NovaLightTheme(),
                          delegate: cellDelegate,
                          a11yId: "tab",
                          newTabTitle: nil,
                          selectedGroupColor: .red,
                          selectedGroupGradient: Gradient(colors: [.red, .blue]))
        subject.layoutIfNeeded()
        let initialBorder = try XCTUnwrap(subject.backgroundHolder.layer.sublayers?.first {
            $0.name == ExperimentTabCell.UX.borderLayerName
        } as? CAShapeLayer)
        let initialColor = try XCTUnwrap(initialBorder.strokeColor)
        XCTAssertEqual(initialColor.colorSpace?.model, .pattern)

        subject.frame.size.width = 240
        subject.setNeedsLayout()
        subject.layoutIfNeeded()

        XCTAssertNotEqual(initialBorder.strokeColor, initialColor)
        subject.prepareForReuse()
        subject.configure(with: createDefaultState(isSelected: true),
                          theme: LightTheme(),
                          delegate: cellDelegate,
                          a11yId: "reusedTab",
                          newTabTitle: nil)
        subject.layoutIfNeeded()
        let reusedBorder = try XCTUnwrap(subject.backgroundHolder.layer.sublayers?.first {
            $0.name == ExperimentTabCell.UX.borderLayerName
        } as? CAShapeLayer)
        XCTAssertEqual(reusedBorder.strokeColor, LightTheme().colors.borderAccent.cgColor)
    }

    private func createDefaultState(isSelected: Bool = false) -> TabModel {
        let tabUUID = "0022-22D3"
        return TabModel(tabUUID: tabUUID,
                        isSelected: isSelected,
                        isPrivate: false,
                        isFxHomeTab: false,
                        tabTitle: "Firefox Browser",
                        url: URL(string: "https://www.mozilla.org/en-US/firefox/")!,
                        screenshot: nil,
                        hasHomeScreenshot: false,
                        hasScreenshotOnDisk: false)
    }
}

class MockTabCellDelegate: TabCellDelegate {
    var tabCellClosedCounter = 0

    func tabCellDidClose(for tabUUID: String) {
        tabCellClosedCounter += 1
    }
}
