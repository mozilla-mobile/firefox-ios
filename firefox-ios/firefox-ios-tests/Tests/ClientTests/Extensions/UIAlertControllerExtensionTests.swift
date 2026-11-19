// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import XCTest
import Shared

@testable import Client

@MainActor
final class UIAlertControllerExtensionTests: XCTestCase {
    func testDeleteLoginAlertWithUpdatedStringsEnabledUsesNewCopy() {
        let alert = createDeleteLoginAlert(hasSyncedLogins: true, usesUpdatedSyncStrings: true)

        XCTAssertEqual(alert.title, String.DeleteLoginAlert.Title)
        XCTAssertEqual(alert.message, String(format: .DeleteLoginAlert.SyncedMessage, AppName.shortName.rawValue))
        XCTAssertEqual(alert.actions.first?.title, String.DeleteLoginAlertCancel)
        XCTAssertEqual(alert.actions.last?.title, String.DeleteLoginAlert.DeleteButtonTitle)
        XCTAssertEqual(alert.actions.last?.style, .destructive)
    }

    func testDeleteLoginAlertWithUpdatedStringsDisabledUsesExistingCopy() {
        let alert = createDeleteLoginAlert(hasSyncedLogins: true, usesUpdatedSyncStrings: false)

        XCTAssertEqual(alert.title, String.DeleteLoginAlertTitle)
        XCTAssertEqual(alert.message, String.DeleteLoginAlertSyncedMessage)
        XCTAssertEqual(alert.actions.last?.title, String.DeleteLoginAlertDelete)
    }

    func testDeleteLoginAlertWithLocalLoginsKeepsLocalWarning() {
        let alert = createDeleteLoginAlert(hasSyncedLogins: false, usesUpdatedSyncStrings: true)

        XCTAssertEqual(alert.title, String.DeleteLoginAlert.Title)
        XCTAssertEqual(alert.message, String.DeleteLoginAlertLocalMessage)
        XCTAssertEqual(alert.actions.last?.title, String.DeleteLoginAlert.DeleteButtonTitle)
    }

    func testAddShortcutAlertEnablesSaveButtonForValidURL() throws {
        let alert = UIAlertController.addShortcutAlert { _ in }

        let saveAction = try XCTUnwrap(alert.actions.last)
        let textField = try XCTUnwrap(alert.textFields?.first)

        XCTAssertFalse(saveAction.isEnabled)

        textField.text = "facebook.com"
        textField.sendActions(for: .editingChanged)

        XCTAssertTrue(saveAction.isEnabled)
    }

    func testAddShortcutAlertDisablesSaveButtonForInvalidURL() throws {
        let alert = UIAlertController.addShortcutAlert { _ in }

        let saveAction = try XCTUnwrap(alert.actions.last)
        let textField = try XCTUnwrap(alert.textFields?.first)

        textField.text = "facebook.com"
        textField.sendActions(for: .editingChanged)

        XCTAssertTrue(saveAction.isEnabled)

        textField.text = "foo bar"
        textField.sendActions(for: .editingChanged)

        XCTAssertFalse(saveAction.isEnabled)
    }

    private func createDeleteLoginAlert(
        hasSyncedLogins: Bool,
        usesUpdatedSyncStrings: Bool
    ) -> UIAlertController {
        return UIAlertController.deleteLoginAlertWithDeleteCallback(
            { _ in },
            hasSyncedLogins: hasSyncedLogins,
            usesUpdatedSyncStrings: usesUpdatedSyncStrings
        )
    }
}
