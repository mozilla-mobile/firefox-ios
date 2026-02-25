// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Client

@MainActor
final class PickerSettingTests: XCTestCase {
    private let selectedValue = "value1"
    private lazy var pickerOptions = [(selectedValue, "Label 1")]
    private let accessibilityIdentifier = "test"
    private let pickerButtonAccessibilityLabel = "Picker Button"
    private let pickerButtonAccessibilityIdentifier = "pickerButton"

    func test_onConfigureCell() throws {
        let subject = createSubject()
        let theme = DarkTheme()
        let cell = UITableViewCell()

        subject.onConfigureCell(cell, theme: theme)

        let pickerButton = try XCTUnwrap(cell.accessoryView as? UIButton)
        XCTAssertEqual(cell.textLabel?.text, pickerOptions[0].1)
        XCTAssertEqual(cell.selectionStyle, .none)
        XCTAssertTrue(pickerButton.showsMenuAsPrimaryAction)
        XCTAssertTrue(pickerButton.adjustsImageSizeForAccessibilityContentSizeCategory)
        XCTAssertNotNil(pickerButton.menu)
        XCTAssertEqual(pickerButton.menu?.children.count, pickerOptions.count)
        XCTAssertEqual(pickerButton.tintColor, theme.colors.iconPrimary)
        XCTAssertEqual(pickerButton.accessibilityLabel, pickerButtonAccessibilityLabel)
        XCTAssertEqual(pickerButton.accessibilityIdentifier, pickerButtonAccessibilityIdentifier)
    }

    private func createSubject(
        onOptionSelected: @escaping (String) -> Void = { _ in }
    ) -> PickerSetting<String> {
        let setting = PickerSetting(
            selectedValue: selectedValue,
            pickerOptions: pickerOptions,
            accessibilityIdentifier: accessibilityIdentifier,
            pickerButtonAccessibilityLabel: pickerButtonAccessibilityLabel,
            pickerButtonAccessibilityIdentifier: pickerButtonAccessibilityIdentifier,
            onOptionSelected: onOptionSelected
        )
        trackForMemoryLeaks(setting)
        return setting
    }
}
