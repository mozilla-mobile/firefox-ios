// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean
import MozillaAppServices
import XCTest

@testable import Client
@testable import Shared

class RecordedNimbusContextTests: XCTestCase {
    override func setUp() {
        Glean.shared.enableTestingMode()
        Glean.shared.resetGlean(clearStores: true)
    }

    /**
     * This test should not be modified. It will fail if any of the eventQueries are invalid.
     */
    func testValidateEventQueries() throws {
        let recordedContext = RecordedNimbusContext(isFirstRun: true, isReviewCheckerEnabled: true, isDefaultBrowser: true)
        try validateEventQueries(recordedContext: recordedContext)
    }

    func testToJsonReturnsExpected() throws {
        let recordedContext = RecordedNimbusContext(isFirstRun: true, isReviewCheckerEnabled: true, isDefaultBrowser: true)
        recordedContext.setEventQueryValues(eventQueryValues: [RecordedNimbusContext.DAYS_OPENED_IN_LAST_28: 1.5])
        let jsonString = recordedContext.toJson()

        var json = try JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!) as? [String: Any]
        XCTAssertNotNil(json)
        XCTAssertEqual(json?.removeValue(forKey: "isFirstRun") as? String, "true")
        XCTAssertEqual(json?.removeValue(forKey: "is_first_run") as? Bool, true)
        XCTAssertEqual(json?.removeValue(forKey: "is_phone") as? Bool, recordedContext.isPhone)
        XCTAssertEqual(json?.removeValue(forKey: "is_review_checker_enabled") as? Bool, true)
        XCTAssertEqual(json?.removeValue(forKey: "app_version") as? String, recordedContext.appVersion)
        XCTAssertEqual(json?.removeValue(forKey: "locale") as? String, recordedContext.locale)
        XCTAssertEqual(json?.removeValue(forKey: "language") as? String, recordedContext.language)
        XCTAssertEqual(json?.removeValue(forKey: "region") as? String, recordedContext.region)
        XCTAssertEqual(json?.removeValue(forKey: "days_since_install") as? Int32, recordedContext.daysSinceInstall)
        XCTAssertEqual(json?.removeValue(forKey: "days_since_update") as? Int32, recordedContext.daysSinceUpdate)
        XCTAssertEqual(json?.removeValue(forKey: "is_default_browser") as? Bool, recordedContext.isDefaultBrowser)

        var events = json?.removeValue(forKey: "events") as? [String: Double]
        XCTAssertNotNil(events)
        XCTAssertEqual(events?.removeValue(forKey: RecordedNimbusContext.DAYS_OPENED_IN_LAST_28), 1.5)
        XCTAssertEqual(events?.count, 0)

        XCTAssertEqual(json?.count, 0)
    }

    func testObjectRecordedToGleanMatchesExpected() throws {
        let recordedContext = RecordedNimbusContext(isFirstRun: true, isReviewCheckerEnabled: true, isDefaultBrowser: true)
        recordedContext.setEventQueryValues(eventQueryValues: [RecordedNimbusContext.DAYS_OPENED_IN_LAST_28: 1.5])
        recordedContext.record()
        let value = GleanMetrics.NimbusSystem.recordedNimbusContext.testGetValue()

        XCTAssertNotNil(value)
        XCTAssertEqual(value?.appVersion, recordedContext.appVersion)
        XCTAssertEqual(value?.isFirstRun, recordedContext.isFirstRun)
        XCTAssertEqual(value?.isPhone, recordedContext.isPhone)
        XCTAssertEqual(value?.isReviewCheckerEnabled, recordedContext.isReviewCheckerEnabled)
        XCTAssertEqual(value?.locale, recordedContext.locale)
        XCTAssertEqual(value?.region, recordedContext.region)
        XCTAssertEqual(value?.language, recordedContext.language)
        XCTAssertEqual(Int(value!.daysSinceInstall!), Int(recordedContext.daysSinceInstall!))
        XCTAssertEqual(Int(value!.daysSinceUpdate!), Int(recordedContext.daysSinceUpdate!))
        XCTAssertEqual(value?.isDefaultBrowser, recordedContext.isDefaultBrowser)

        XCTAssertNotNil(value?.eventQueryValues)
        XCTAssertEqual(value?.eventQueryValues?.daysOpenedInLast28, 1)
    }

    func testGetEventQueries() throws {
        let recordedContext = RecordedNimbusContext(isFirstRun: true, isReviewCheckerEnabled: true, isDefaultBrowser: true)
        let eventQueries = recordedContext.getEventQueries()

        XCTAssertEqual(eventQueries, RecordedNimbusContext.EVENT_QUERIES)
    }
}
