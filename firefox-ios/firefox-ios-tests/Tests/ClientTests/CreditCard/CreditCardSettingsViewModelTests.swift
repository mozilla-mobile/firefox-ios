// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Glean
import MozillaAppServices
import Shared
import UIKit
import XCTest

@testable import Client

final class CreditCardSettingsViewModelTests: XCTestCase {
    private var profile: MockProfile!
    private var featureFlags: MockNimbusFeatureFlags!
    private var userDefaults: MockUserDefaults!
    private var gleanWrapper: MockGleanWrapper!

    override func setUp() async throws {
        try await super.setUp()
        await DependencyHelperMock().bootstrapDependencies()
        profile = makeProfile()
        featureFlags = MockNimbusFeatureFlags()
        featureFlags.enabledFlags = [.creditCardSecurityCode]
        userDefaults = MockUserDefaults()
        gleanWrapper = MockGleanWrapper()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        profile = nil
        featureFlags = nil
        userDefaults = nil
        gleanWrapper = nil
        try await super.tearDown()
    }

    func testShowsSecurityCodeToggle_featureEnabled_isTrue() {
        XCTAssertTrue(createSubject().showsSecurityCodeToggle)
    }

    func testShowsSecurityCodeToggle_featureDisabled_isFalse() {
        featureFlags.enabledFlags = []

        XCTAssertFalse(createSubject().showsSecurityCodeToggle)
    }

    func testSecurityCodeToggleModel_reflectsStoredPreference() {
        userDefaults.set(false, forKey: PrefsKeys.KeyAutofillCreditCardSecurityCodeStatus)

        XCTAssertFalse(createSubject().securityCodeToggleModel.isEnabled)
    }

    func testSecurityCodeToggleModel_defaultsToOn() {
        XCTAssertTrue(createSubject().securityCodeToggleModel.isEnabled)
    }

    func testTogglingSecurityCodes_persistsPreferenceOnly() {
        let subject = createSubject()
        let autofillStatusBefore = UserDefaults.standard.object(forKey: PrefsKeys.KeyAutofillCreditCardStatus) as? Bool

        subject.securityCodeToggleModel.isEnabled = false

        XCTAssertEqual(userDefaults.object(forKey: PrefsKeys.KeyAutofillCreditCardSecurityCodeStatus) as? Bool, false)
        XCTAssertEqual(UserDefaults.standard.object(forKey: PrefsKeys.KeyAutofillCreditCardStatus) as? Bool,
                       autofillStatusBefore)
    }

    func testTogglingSecurityCodes_recordsSettingsChangedTelemetry() throws {
        let subject = createSubject()

        subject.securityCodeToggleModel.isEnabled = false

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? GleanMetrics.Settings.ChangedExtra)
        XCTAssertEqual(savedExtras.setting, PrefsKeys.KeyAutofillCreditCardSecurityCodeStatus)
        XCTAssertEqual(savedExtras.changedTo, "false")
        XCTAssertEqual(savedExtras.changedFrom, "true")
    }

    @MainActor
    func testTableView_withSecurityCodeToggle_showsTwoToggleRows() {
        let tableViewModel = CreditCardTableViewModel()
        tableViewModel.toggleModel = ToggleModel(isEnabled: true)
        tableViewModel.securityCodeToggleModel = ToggleModel(isEnabled: true)
        let subject = CreditCardTableViewController(viewModel: tableViewModel, windowUUID: .XCTestDefaultUUID)

        XCTAssertEqual(subject.tableView(UITableView(), numberOfRowsInSection: 0), 2)
    }

    @MainActor
    func testTableView_withoutSecurityCodeToggle_showsOneToggleRow() {
        let tableViewModel = CreditCardTableViewModel()
        tableViewModel.toggleModel = ToggleModel(isEnabled: true)
        let subject = CreditCardTableViewController(viewModel: tableViewModel, windowUUID: .XCTestDefaultUUID)

        XCTAssertEqual(subject.tableView(UITableView(), numberOfRowsInSection: 0), 1)
    }

    func testTogglingSecurityCodes_updatesCardListSecurityCodeVisibility() {
        let subject = createSubject()

        subject.securityCodeToggleModel.isEnabled = false
        XCTAssertFalse(subject.tableViewModel.isSecurityCodeEnabled)

        subject.securityCodeToggleModel.isEnabled = true
        XCTAssertTrue(subject.tableViewModel.isSecurityCodeEnabled)
    }

    func testTableViewModel_securityCodeEnabledAndCardHasCvv_showsSaved() {
        let subject = CreditCardTableViewModel()
        subject.isSecurityCodeEnabled = true
        subject.creditCards = [makeCard(ccCvv: "123")]

        XCTAssertEqual(subject.securityCodeDisplay(for: makeCard(ccCvv: "123")), .saved)
        XCTAssertTrue(subject.a11yLabel(for: IndexPath(row: 0, section: 1)).string
            .hasSuffix(String.CreditCard.Settings.SecurityCodeSavedLabel))
    }

    func testTableViewModel_securityCodeDisabled_hidesSaved() {
        let subject = CreditCardTableViewModel()
        subject.creditCards = [makeCard(ccCvv: "123")]

        XCTAssertNil(subject.securityCodeDisplay(for: makeCard(ccCvv: "123")))
        XCTAssertFalse(subject.a11yLabel(for: IndexPath(row: 0, section: 1)).string
            .contains(String.CreditCard.Settings.SecurityCodeSavedLabel))
    }

    func testTableViewModel_cardWithoutCvv_hidesSaved() {
        let subject = CreditCardTableViewModel()
        subject.isSecurityCodeEnabled = true

        XCTAssertNil(subject.securityCodeDisplay(for: makeCard(ccCvv: nil)))
        XCTAssertNil(subject.securityCodeDisplay(for: makeCard(ccCvv: "")))
    }

    func testTableViewModel_changingSecurityCodeEnabled_reloadsCards() {
        let subject = CreditCardTableViewModel()
        var reloadCount = 0
        subject.didUpdateCreditCards = { reloadCount += 1 }

        subject.isSecurityCodeEnabled = true

        XCTAssertEqual(reloadCount, 1)
    }

    // MARK: - Helpers

    private func makeCard(ccCvv: String?) -> CreditCard {
        return CreditCard(guid: "1",
                          ccName: "Allen Burges",
                          ccNumber: "4111111111111111",
                          ccCvv: ccCvv,
                          ccNumberLast4: "1111",
                          ccExpMonth: 3,
                          ccExpYear: 2043,
                          ccType: "VISA",
                          timeCreated: 1234678,
                          timeLastUsed: nil,
                          timeLastModified: 123123,
                          timesUsed: 123123)
    }

    private func createSubject() -> CreditCardSettingsViewModel {
        return CreditCardSettingsViewModel(
            profile: profile,
            windowUUID: .XCTestDefaultUUID,
            securityCodeSettings: CreditCardSecurityCodeSettings(
                featureFlagsProvider: featureFlags,
                userDefaults: userDefaults,
                telemetry: SettingsTelemetry(gleanWrapper: gleanWrapper)
            )
        )
    }
}
