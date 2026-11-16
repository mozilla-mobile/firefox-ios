// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import Shared
import Storage
import XCTest

@testable import Client

final class CreditCardSecurityCodeSettingsTests: XCTestCase {
    private var featureFlags: MockNimbusFeatureFlags!
    private var userDefaults: MockUserDefaults!
    private var gleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        featureFlags = MockNimbusFeatureFlags()
        userDefaults = MockUserDefaults()
        gleanWrapper = MockGleanWrapper()
    }

    override func tearDown() {
        featureFlags = nil
        userDefaults = nil
        gleanWrapper = nil
        super.tearDown()
    }

    func testIsSaveSecurityCodesEnabled_defaultsToOn() {
        let subject = createSubject()

        XCTAssertTrue(subject.isSaveSecurityCodesEnabled)
    }

    func testSetSaveSecurityCodesEnabled_persistsValue() {
        let subject = createSubject()

        subject.setSaveSecurityCodesEnabled(false)

        XCTAssertFalse(subject.isSaveSecurityCodesEnabled)
        XCTAssertEqual(userDefaults.object(forKey: PrefsKeys.KeyAutofillCreditCardSecurityCodeStatus) as? Bool, false)
    }

    func testSetSaveSecurityCodesEnabled_recordsSettingsChangedTelemetry() throws {
        typealias EventExtrasType = GleanMetrics.Settings.ChangedExtra
        let subject = createSubject()

        subject.setSaveSecurityCodesEnabled(false)

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)
        XCTAssertEqual(savedExtras.setting, PrefsKeys.KeyAutofillCreditCardSecurityCodeStatus)
        XCTAssertEqual(savedExtras.changedTo, "false")
        XCTAssertEqual(savedExtras.changedFrom, "true")
        XCTAssert(savedMetric === GleanMetrics.Settings.changed)
    }

    func testIsSecurityCodeEnabled_featureOnAndToggleOn_isTrue() {
        featureFlags.enabledFlags = [.creditCardSecurityCode]

        XCTAssertTrue(createSubject().isSecurityCodeEnabled)
    }

    func testIsSecurityCodeEnabled_featureOff_isFalse() {
        XCTAssertFalse(createSubject().isFeatureEnabled)
        XCTAssertFalse(createSubject().isSecurityCodeEnabled)
    }

    func testIsSecurityCodeEnabled_toggleOff_isFalse() {
        featureFlags.enabledFlags = [.creditCardSecurityCode]
        let subject = createSubject()

        subject.setSaveSecurityCodesEnabled(false)

        XCTAssertTrue(subject.isFeatureEnabled)
        XCTAssertFalse(subject.isSecurityCodeEnabled)
    }

    func testApplying_enabled_keepsSecurityCode() {
        featureFlags.enabledFlags = [.creditCardSecurityCode]

        XCTAssertEqual(createSubject().applying(to: makeCard(ccCvv: "123")).ccCvv, "123")
    }

    func testApplying_disabled_dropsOnlySecurityCode() {
        let card = makeCard(ccCvv: "123")

        let result = createSubject().applying(to: card)

        XCTAssertNil(result.ccCvv)
        XCTAssertEqual(result.ccNumber, card.ccNumber)
        XCTAssertEqual(result.ccName, card.ccName)
        XCTAssertEqual(result.ccExpMonth, card.ccExpMonth)
        XCTAssertEqual(result.ccExpYear, card.ccExpYear)
    }

    // MARK: - Helpers

    private func createSubject() -> CreditCardSecurityCodeSettings {
        return CreditCardSecurityCodeSettings(featureFlagsProvider: featureFlags,
                                              userDefaults: userDefaults,
                                              telemetry: SettingsTelemetry(gleanWrapper: gleanWrapper))
    }

    private func makeCard(ccCvv: String?) -> UnencryptedCreditCardFields {
        return UnencryptedCreditCardFields(ccName: "Allen Burges",
                                           ccNumber: "4111111111111111",
                                           ccNumberLast4: "1111",
                                           ccExpMonth: 3,
                                           ccExpYear: 2043,
                                           ccType: "VISA",
                                           ccCvv: ccCvv)
    }
}
