// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class TranslationFeatureGateTests: XCTestCase {
    func test_isLanguagePickerEnabled_whenFlagOff_returnsFalse() {
        let provider = MockNimbusFeatureFlags()
        XCTAssertFalse(TranslationFeatureGate(featureFlagsProvider: provider).isLanguagePickerEnabled)
    }

    func test_isLanguagePickerEnabled_whenFlagOn_returnsTrue() {
        let provider = MockNimbusFeatureFlags()
        provider.enabledFlags = [.translationLanguagePicker]
        XCTAssertTrue(TranslationFeatureGate(featureFlagsProvider: provider).isLanguagePickerEnabled)
    }

    func test_isLanguagePickerEnabled_whenUnrelatedFlagOn_returnsFalse() {
        let provider = MockNimbusFeatureFlags()
        provider.enabledFlags = [.translation]
        XCTAssertFalse(TranslationFeatureGate(featureFlagsProvider: provider).isLanguagePickerEnabled)
    }
}
