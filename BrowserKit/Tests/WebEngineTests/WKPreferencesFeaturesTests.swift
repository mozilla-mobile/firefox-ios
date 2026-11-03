// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
import TestKit
@testable import WebEngine

@MainActor
final class WKPreferencesFeaturesTests: XCTestCase {
    func testProxyLeakingFeatures_existInWebKit() {
        let subject = createSubject()

        DefaultWKEngineConfigurationProvider.proxyLeakingFeatures.forEach {
            XCTAssertNotNil(subject.isFeatureEnabled($0), "\($0) is not exposed by WebKit")
        }
    }

    func testSetFeature_disablesAndReenablesFeature() {
        let subject = createSubject()

        DefaultWKEngineConfigurationProvider.proxyLeakingFeatures.forEach {
            subject.setFeature($0, enabled: false)
            XCTAssertEqual(subject.isFeatureEnabled($0), false)

            subject.setFeature($0, enabled: true)
            XCTAssertEqual(subject.isFeatureEnabled($0), true)
        }
    }

    func testUnknownFeature_isIgnored() {
        let subject = createSubject()

        subject.setFeature("NotARealFeature", enabled: false)

        XCTAssertNil(subject.isFeatureEnabled("NotARealFeature"))
    }

    private func createSubject() -> WKPreferences {
        let subject = WKPreferences()
        trackForMemoryLeaks(subject)
        return subject
    }
}
