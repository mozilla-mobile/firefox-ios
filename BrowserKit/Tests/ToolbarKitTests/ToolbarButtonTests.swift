// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import ToolbarKit

@MainActor
final class ToolbarButtonTests: XCTestCase {
    private var button: ToolbarButton!

    override func setUp() async throws {
        try await super.setUp()
        button = ToolbarButton()
    }

    override func tearDown() async throws {
        button = nil
        try await super.tearDown()
    }

    // MARK: - Configuration Caching Tests
    func testConfigureWithSameElement_SkipsReconfiguration() {
        let element = createToolbarElement(iconName: "icon1", a11yLabel: "Test")

        button.configure(element: element)
        // Modify button state to track if reconfiguration happens.
        button.accessibilityLabel = "Modified"
        button.configure(element: element)

        // The configuration should be skipped, leaving the modified state.
        XCTAssertEqual(button.accessibilityLabel, "Modified", "Configuration should be skipped when element hasn't changed.")
    }

    func testConfigureWithDifferentEnabled_ReconfiguresButton() {
        let enabledElement = createToolbarElement(iconName: "icon1", isEnabled: true, a11yLabel: "Test")
        let disabledElement = createToolbarElement(iconName: "icon1", isEnabled: false, a11yLabel: "Test")

        button.configure(element: enabledElement)
        let firstEnabledState = button.isEnabled
        button.configure(element: disabledElement)
        let secondEnabledState = button.isEnabled

        XCTAssertTrue(firstEnabledState)
        XCTAssertFalse(secondEnabledState)
    }

    func testConfigureWithDifferentSelected_ReconfiguresButton() {
        let unselectedElement = createToolbarElement(iconName: "icon1", isSelected: false, a11yLabel: "Test")
        let selectedElement = createToolbarElement(iconName: "icon1", isSelected: true, a11yLabel: "Test")

        button.configure(element: unselectedElement)
        let firstSelectedState = button.isSelected
        button.configure(element: selectedElement)
        let secondSelectedState = button.isSelected

        XCTAssertFalse(firstSelectedState)
        XCTAssertTrue(secondSelectedState)
    }

    func testConfigureWithDifferentTitle_ReconfiguresButton() {
        let element1 = createToolbarElement(iconName: "icon1", title: "Title1", a11yLabel: "Test")
        let element2 = createToolbarElement(iconName: "icon1", title: "Title2", a11yLabel: "Test")

        button.configure(element: element1)
        let firstTitle = button.configuration?.title
        button.configure(element: element2)
        let secondTitle = button.configuration?.title

        XCTAssertEqual(firstTitle, "Title1")
        XCTAssertEqual(secondTitle, "Title2")
    }

    func testConfigureMultipleTimes_WithSameElement_OnlyConfiguresOnce() {
        let element = createToolbarElement(iconName: "icon1", a11yLabel: "Test")

        button.configure(element: element)
        // Modify button state to track if reconfiguration happens.
        button.accessibilityLabel = "Modified"
        button.configure(element: element)
        button.configure(element: element)
        button.configure(element: element)

        // The label should remain modified (proving no reconfiguration).
        XCTAssertEqual(button.accessibilityLabel, "Modified", "Multiple configurations with same element should be skipped.")
    }

    func testConfigureWithLoadingState_ReconfiguresWhenLoadingChanges() {
        let loadingConfig1 = LoadingConfig(isLoading: false, a11yLabel: "Not Loading")
        let loadingConfig2 = LoadingConfig(isLoading: true, a11yLabel: "Loading")

        let element1 = createToolbarElement(iconName: "icon1", loadingConfig: loadingConfig1, a11yLabel: "Test")
        let element2 = createToolbarElement(iconName: "icon1", loadingConfig: loadingConfig2, a11yLabel: "Test")

        button.configure(element: element1)
        button.configure(element: element2)

        // The button should be reconfigured (we can verify by checking subviews for spinner).
        let hasSpinner = button.subviews.contains { $0 is UIActivityIndicatorView }
        XCTAssertTrue(hasSpinner, "Loading state change should trigger reconfiguration.")
    }

    // MARK: - Helper Methods
    private func createToolbarElement(
        iconName: String? = nil,
        title: String? = nil,
        badgeImageName: String? = nil,
        maskImageName: String? = nil,
        loadingConfig: LoadingConfig? = nil,
        numberOfTabs: Int? = nil,
        isEnabled: Bool = true,
        isSelected: Bool = false,
        hasCustomColor: Bool = false,
        a11yLabel: String,
        a11yHint: String? = nil,
        a11yId: String = "testId",
        hasLongPressAction: Bool = false,
        onSelected: ((UIButton) -> Void)? = nil,
        onLongPress: ((UIButton) -> Void)? = nil
    ) -> ToolbarElement {
        return ToolbarElement(
            iconName: iconName,
            title: title,
            badgeImageName: badgeImageName,
            maskImageName: maskImageName,
            loadingConfig: loadingConfig,
            numberOfTabs: numberOfTabs,
            isEnabled: isEnabled,
            isSelected: isSelected,
            hasCustomColor: hasCustomColor,
            a11yLabel: a11yLabel,
            a11yHint: a11yHint,
            a11yId: a11yId,
            hasLongPressAction: hasLongPressAction,
            onSelected: onSelected,
            onLongPress: onLongPress
        )
    }
}
