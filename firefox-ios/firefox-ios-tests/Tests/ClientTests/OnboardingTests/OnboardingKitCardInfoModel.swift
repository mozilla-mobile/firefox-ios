// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import UIKit
import OnboardingKit
@testable import Client

class OnboardingKitCardInfoModelTests: XCTestCase {
    func testDefaultSelectedButton_EmptyButtonsArray() {
        let model = createModel(multipleChoiceButtons: [])

        XCTAssertNil(model.defaultSelectedButton, "Should return nil when no buttons are available")
    }

    func testDefaultSelectedButton_VersionedLayout_PrioritizesToolbarBottom() {
        let buttons = [
            createMockMultipleChoiceButton(action: .toolbarTop),     // Priority 2
            createMockMultipleChoiceButton(action: .toolbarBottom) // Priority 1 (highest)
        ]
        let model = createModel(multipleChoiceButtons: buttons)

        // Should return toolbarBottom due to highest priority (1)
        XCTAssertEqual(model.defaultSelectedButton?.action, .toolbarBottom)
    }

    func testDefaultSelectedButton_VersionedLayout_PrioritizesToolbarTop_WhenBottomNotAvailable() {
        let buttons = [
            createMockMultipleChoiceButton(action: .themeDark),
            createMockMultipleChoiceButton(action: .toolbarTop),     // Priority 2
            createMockMultipleChoiceButton(action: .themeLight)
        ]
        let model = createModel(multipleChoiceButtons: buttons)

        // Should return toolbarTop as it's the only selectable option
        XCTAssertEqual(model.defaultSelectedButton?.action, .toolbarTop)
    }

    func testDefaultSelectedButton_VersionedLayout_NoSelectableButtons_ReturnsFirst() {
        let buttons = [
            createMockMultipleChoiceButton(action: .themeDark),
            createMockMultipleChoiceButton(action: .themeLight)
        ]
        let model = createModel(multipleChoiceButtons: buttons)

        // When no buttons have default selection, should return first button
        XCTAssertEqual(model.defaultSelectedButton?.action, .themeDark)
    }

    func testDefaultSelectedButton_VersionedLayout_OnlyToolbarBottom() {
        let buttons = [
            createMockMultipleChoiceButton(action: .toolbarBottom)
        ]
        let model = createModel(multipleChoiceButtons: buttons)

        XCTAssertEqual(model.defaultSelectedButton?.action, .toolbarBottom)
    }

    func testDefaultSelectedButton_VersionedLayout_OnlyToolbarTop() {
        let buttons = [
            createMockMultipleChoiceButton(action: .toolbarTop)
        ]
        let model = createModel(multipleChoiceButtons: buttons)

        XCTAssertEqual(model.defaultSelectedButton?.action, .toolbarTop)
    }

    func testDefaultSelectedButton_VersionedLayout_MultipleToolbarBottomButtons() {
        let buttons = [
            createMockMultipleChoiceButton(action: .toolbarBottom), // First with priority 1
            createMockMultipleChoiceButton(action: .toolbarTop),    // Priority 2
            createMockMultipleChoiceButton(action: .toolbarBottom)  // Second with priority 1
        ]
        let model = createModel(multipleChoiceButtons: buttons)

        // Should return the first toolbarBottom button (both have same priority)
        XCTAssertEqual(model.defaultSelectedButton?.action, .toolbarBottom)
    }

    // MARK: - Edge Cases

    func testDefaultSelectedButton_SingleNonSelectableButton() {
        let buttons = [
            createMockMultipleChoiceButton(action: .themeDark)
        ]
        let model = createModel(multipleChoiceButtons: buttons)

        // Should return the only available button
        XCTAssertEqual(model.defaultSelectedButton?.action, .themeDark)
    }

    func testDefaultSelectedButton_OrderMatters() {
        let buttons = [
            createMockMultipleChoiceButton(action: .toolbarTop),    // Priority 2
            createMockMultipleChoiceButton(action: .toolbarBottom) // Priority 1
        ]
        let model = createModel(multipleChoiceButtons: buttons)

        // Should return toolbarBottom despite being second in array
        XCTAssertEqual(model.defaultSelectedButton?.action, .toolbarBottom)
    }

    // MARK: - Test Helpers

    private func createMockButtons() -> OnboardingKit.OnboardingButtons<OnboardingActions> {
        return OnboardingKit.OnboardingButtons<OnboardingActions>(
            primary: OnboardingButtonInfoModel<OnboardingActions>(
                title: "Primary",
                action: .forwardOneCard
            ),
            secondary: nil
        )
    }

    private func createMockMultipleChoiceButton(
        action: Client.OnboardingMultipleChoiceAction
    ) -> OnboardingKit.OnboardingMultipleChoiceButtonModel<Client.OnboardingMultipleChoiceAction> {
        return OnboardingKit.OnboardingMultipleChoiceButtonModel<Client.OnboardingMultipleChoiceAction>(
            title: "title",
            action: action,
            imageID: "imageID"
        )
    }

    private func createModel(
        multipleChoiceButtons: [OnboardingKit.OnboardingMultipleChoiceButtonModel<Client.OnboardingMultipleChoiceAction>]
    ) -> OnboardingKitCardInfoModel {
        return OnboardingKitCardInfoModel(
            cardType: .basic,
            name: "Test Card",
            order: 1,
            title: "Test Title",
            body: "Test Body",
            buttons: createMockButtons(),
            multipleChoiceButtons: multipleChoiceButtons,
            a11yIdRoot: "test_card",
            imageID: "test_image"
        )
    }
}
