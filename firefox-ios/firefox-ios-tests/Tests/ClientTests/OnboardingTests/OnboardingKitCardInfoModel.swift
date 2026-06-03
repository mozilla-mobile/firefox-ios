// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import UIKit
import OnboardingKit
@testable import Client

@MainActor
class OnboardingKitCardInfoModelTests: XCTestCase {
    private var mockUserPreferences: MockUserFeaturePreferences!

    override func setUp() {
        super.setUp()
        mockUserPreferences = MockUserFeaturePreferences()
        DependencyHelperMock().bootstrapDependencies(injectedUserFeaturePreferences: mockUserPreferences)
        clearSavedTheme()
    }

    override func tearDown() {
        clearSavedTheme()
        DependencyHelperMock().reset()
        mockUserPreferences = nil
        super.tearDown()
    }

    func testDefaultSelectedButton_emptyButtons_returnsNil() {
        let model = createModel(multipleChoiceButtons: [])

        XCTAssertNil(model.defaultSelectedButton, "Should return nil when no buttons are available")
    }

    // MARK: - Toolbar selection reflects the saved search bar position

    func testDefaultSelectedButton_savedBottomPosition_selectsToolbarBottom() {
        mockUserPreferences.searchBarPosition = .bottom
        let model = createModel(multipleChoiceButtons: [
            createMockMultipleChoiceButton(action: .toolbarTop),
            createMockMultipleChoiceButton(action: .toolbarBottom)
        ])

        XCTAssertEqual(model.defaultSelectedButton?.action, .toolbarBottom)
    }

    func testDefaultSelectedButton_savedTopPosition_selectsToolbarTop() {
        mockUserPreferences.searchBarPosition = .top
        let model = createModel(multipleChoiceButtons: [
            createMockMultipleChoiceButton(action: .toolbarTop),
            createMockMultipleChoiceButton(action: .toolbarBottom)
        ])

        XCTAssertEqual(model.defaultSelectedButton?.action, .toolbarTop)
    }

    func testDefaultSelectedButton_savedPositionMissingFromButtons_fallsBackToFirst() {
        mockUserPreferences.searchBarPosition = .bottom
        let model = createModel(multipleChoiceButtons: [
            createMockMultipleChoiceButton(action: .toolbarTop)
        ])

        // Saved position has no matching button, so fall back to the first button.
        XCTAssertEqual(model.defaultSelectedButton?.action, .toolbarTop)
    }

    // MARK: - Theme selection reflects the saved theme

    func testDefaultSelectedButton_systemThemeOn_selectsSystemDefault() {
        UserDefaults.standard.set(true, forKey: "prefKeySystemThemeSwitchOnOff")
        let model = createModel(multipleChoiceButtons: [
            createMockMultipleChoiceButton(action: .themeLight),
            createMockMultipleChoiceButton(action: .themeSystemDefault),
            createMockMultipleChoiceButton(action: .themeDark)
        ])

        XCTAssertEqual(model.defaultSelectedButton?.action, .themeSystemDefault)
    }

    func testDefaultSelectedButton_noSavedTheme_returnsFirst() {
        let model = createModel(multipleChoiceButtons: [
            createMockMultipleChoiceButton(action: .themeDark),
            createMockMultipleChoiceButton(action: .themeLight)
        ])

        // With no saved theme and no toolbar buttons, fall back to the first button.
        XCTAssertEqual(model.defaultSelectedButton?.action, .themeDark)
    }

    // MARK: - Test Helpers

    private func clearSavedTheme() {
        UserDefaults.standard.removeObject(forKey: "prefKeySystemThemeSwitchOnOff")
        UserDefaults.standard.removeObject(forKey: "prefKeyThemeName")
    }

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
