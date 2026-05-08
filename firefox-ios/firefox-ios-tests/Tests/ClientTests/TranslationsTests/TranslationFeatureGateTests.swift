// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class TranslationFeatureGateTests: XCTestCase {
    // MARK: - isMultiLanguageFlowEnabled

    func test_isMultiLanguageFlowEnabled_whenFlagOff_returnsFalse() {
        let provider = MockNimbusFeatureFlags()
        let gate = TranslationFeatureGate(featureFlagsProvider: provider)
        XCTAssertFalse(gate.isMultiLanguageFlowEnabled)
    }

    func test_isMultiLanguageFlowEnabled_whenFlagOn_returnsTrue() {
        let provider = MockNimbusFeatureFlags()
        provider.enabledFlags = [.translationLanguagePicker]
        let gate = TranslationFeatureGate(featureFlagsProvider: provider)
        XCTAssertTrue(gate.isMultiLanguageFlowEnabled)
    }

    func test_isMultiLanguageFlowEnabled_whenUnrelatedFlagOn_returnsFalse() {
        let provider = MockNimbusFeatureFlags()
        provider.enabledFlags = [.translation]
        let gate = TranslationFeatureGate(featureFlagsProvider: provider)
        XCTAssertFalse(gate.isMultiLanguageFlowEnabled)
    }

    // MARK: - shouldUsePickerUI

    func test_shouldUsePickerUI_whenFlagOff_returnsFalse() {
        let provider = MockNimbusFeatureFlags()
        let gate = TranslationFeatureGate(featureFlagsProvider: provider)
        XCTAssertFalse(gate.shouldUsePickerUI)
    }

    func test_shouldUsePickerUI_whenFlagOn_returnsTrue() {
        let provider = MockNimbusFeatureFlags()
        provider.enabledFlags = [.translationLanguagePicker]
        let gate = TranslationFeatureGate(featureFlagsProvider: provider)
        XCTAssertTrue(gate.shouldUsePickerUI)
    }

    func test_shouldUsePickerUI_whenUnrelatedFlagOn_returnsFalse() {
        let provider = MockNimbusFeatureFlags()
        provider.enabledFlags = [.translation]
        let gate = TranslationFeatureGate(featureFlagsProvider: provider)
        XCTAssertFalse(gate.shouldUsePickerUI)
    }
}
