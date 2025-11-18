// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean
import MozillaAppServices
import XCTest

@testable import Client

class RecordedNimbusContextTests: XCTestCase {
    override func setUp() {
        Glean.shared.enableTestingMode()
        Glean.shared.resetGlean(clearStores: true)
    }

    /**
     * This test should not be modified. It will fail if any of the eventQueries are invalid.
     */
    func testValidateEventQueries() throws {
        let recordedContext = RecordedNimbusContext(
            isFirstRun: true,
            isDefaultBrowser: true,
            isBottomToolbarUser: true,
            hasEnabledTipsNotifications: true,
            hasAcceptedTermsOfUse: true,
            isAppleIntelligenceAvailable: true,
            cannotUseAppleIntelligence: true
        )
        try validateEventQueries(recordedContext: recordedContext)
    }

    func testToJsonReturnsExpected() throws {
        let recordedContext = RecordedNimbusContext(
            isFirstRun: true,
            isDefaultBrowser: true,
            isBottomToolbarUser: true,
            hasEnabledTipsNotifications: true,
            hasAcceptedTermsOfUse: true,
            isAppleIntelligenceAvailable: true,
            cannotUseAppleIntelligence: true
        )
        recordedContext.setEventQueryValues(eventQueryValues: [RecordedNimbusContext.DAYS_OPENED_IN_LAST_28: 1.5])
        let jsonString = recordedContext.toJson()

        var json = try JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!) as? [String: Any]
        XCTAssertNotNil(json)
        XCTAssertEqual(json?.removeValue(forKey: "isFirstRun") as? String, "true")
        XCTAssertEqual(json?.removeValue(forKey: "is_first_run") as? Bool, true)
        XCTAssertEqual(json?.removeValue(forKey: "is_phone") as? Bool, recordedContext.isPhone)
        XCTAssertEqual(json?.removeValue(forKey: "app_version") as? String, recordedContext.appVersion)
        XCTAssertEqual(json?.removeValue(forKey: "locale") as? String, recordedContext.locale)
        XCTAssertEqual(json?.removeValue(forKey: "language") as? String, recordedContext.language)
        XCTAssertEqual(json?.removeValue(forKey: "region") as? String, recordedContext.region)
        XCTAssertEqual(json?.removeValue(forKey: "days_since_install") as? Int32, recordedContext.daysSinceInstall)
        XCTAssertEqual(json?.removeValue(forKey: "days_since_update") as? Int32, recordedContext.daysSinceUpdate)
        XCTAssertEqual(json?.removeValue(forKey: "is_default_browser") as? Bool, recordedContext.isDefaultBrowser)
        XCTAssertEqual(
            json?.removeValue(forKey: "is_bottom_toolbar_user") as? Bool,
            recordedContext.isBottomToolbarUser
        )
        XCTAssertEqual(
            json?.removeValue(forKey: "has_enabled_tips_notifications") as? Bool,
            recordedContext.hasEnabledTipsNotifications
        )
        XCTAssertEqual(
            json?.removeValue(forKey: "has_accepted_terms_of_use") as? Bool,
            recordedContext.hasAcceptedTermsOfUse
        )
        XCTAssertEqual(
            json?.removeValue(forKey: "is_apple_intelligence_available") as? Bool,
            recordedContext.isAppleIntelligenceAvailable
        )
        XCTAssertEqual(
            json?.removeValue(forKey: "cannot_use_apple_intelligence") as? Bool,
            recordedContext.cannotUseAppleIntelligence
        )
        XCTAssertEqual(
            json?.removeValue(forKey: "tou_experience_points") as? Int32,
            recordedContext.touExperiencePoints
        )

        var events = json?.removeValue(forKey: "events") as? [String: Double]
        XCTAssertNotNil(events)
        XCTAssertEqual(events?.removeValue(forKey: RecordedNimbusContext.DAYS_OPENED_IN_LAST_28), 1.5)
        XCTAssertEqual(events?.count, 0)

        XCTAssertEqual(json?.count, 0)
    }

    func testObjectRecordedToGleanMatchesExpected() throws {
        let recordedContext = RecordedNimbusContext(
            isFirstRun: true,
            isDefaultBrowser: true,
            isBottomToolbarUser: true,
            hasEnabledTipsNotifications: true,
            hasAcceptedTermsOfUse: true,
            isAppleIntelligenceAvailable: true,
            cannotUseAppleIntelligence: true
        )

        var value: GleanMetrics.NimbusSystem.RecordedNimbusContextObject?
        let expectation = expectation(description: "The Firefox Suggest ping was sent")
        GleanMetrics.Pings.shared.nimbus.testBeforeNextSubmit { e in
            value = GleanMetrics.NimbusSystem.recordedNimbusContext.testGetValue()
            expectation.fulfill()
        }

        recordedContext.setEventQueryValues(eventQueryValues: [RecordedNimbusContext.DAYS_OPENED_IN_LAST_28: 1.5])
        recordedContext.record()

        wait(for: [expectation], timeout: 5.0)

        XCTAssertNotNil(value)
        XCTAssertEqual(value?.appVersion, recordedContext.appVersion)
        XCTAssertEqual(value?.isFirstRun, recordedContext.isFirstRun)
        XCTAssertEqual(value?.isPhone, recordedContext.isPhone)
        XCTAssertEqual(value?.locale, recordedContext.locale)
        XCTAssertEqual(value?.region, recordedContext.region)
        XCTAssertEqual(value?.language, recordedContext.language)
        XCTAssertEqual(value?.daysSinceInstall, recordedContext.daysSinceInstall.toInt64())
        XCTAssertEqual(value?.daysSinceUpdate, recordedContext.daysSinceUpdate.toInt64())
        XCTAssertEqual(value?.isDefaultBrowser, recordedContext.isDefaultBrowser)
        XCTAssertEqual(value?.isBottomToolbarUser, recordedContext.isBottomToolbarUser)
        XCTAssertEqual(
            value?.hasEnabledTipsNotifications,
            recordedContext.hasEnabledTipsNotifications
        )
        XCTAssertEqual(
            value?.hasAcceptedTermsOfUse,
            recordedContext.hasAcceptedTermsOfUse
        )
        XCTAssertEqual(
            value?.touExperiencePoints,
            recordedContext.touExperiencePoints.toInt64()
        )

        XCTAssertNotNil(value?.eventQueryValues)
        XCTAssertEqual(value?.eventQueryValues?.daysOpenedInLast28, 1)
    }

    func testGetEventQueries() throws {
        let recordedContext = RecordedNimbusContext(
            isFirstRun: true,
            isDefaultBrowser: true,
            isBottomToolbarUser: true,
            hasEnabledTipsNotifications: true,
            hasAcceptedTermsOfUse: true,
            isAppleIntelligenceAvailable: true,
            cannotUseAppleIntelligence: true
        )
        let eventQueries = recordedContext.getEventQueries()

        XCTAssertEqual(eventQueries, RecordedNimbusContext.EVENT_QUERIES)
    }

    /// This function makes sure that the items in metrics.yaml and RecordedNimbusContext
    /// are the same, to prevent human error forgetting to enter something somewhere
    func testRecordedNimbusContextAndMetricsContextFieldsAreEquivalent() {
        let recordedContext = RecordedNimbusContext(
            isFirstRun: true,
            isDefaultBrowser: true,
            isBottomToolbarUser: true,
            hasEnabledTipsNotifications: true,
            hasAcceptedTermsOfUse: true,
            isAppleIntelligenceAvailable: true,
            cannotUseAppleIntelligence: true
        )
        var recordedContextMembers = Set(Mirror(reflecting: recordedContext).children.compactMap(\.label))
        // removing values that are not part of the metrics file
        recordedContextMembers.remove("logger")
        recordedContextMembers.remove("eventQueries")

        let metricsObject = GleanMetrics.NimbusSystem.RecordedNimbusContextObject()
        let metricsObjectMembers = Set(Mirror(reflecting: metricsObject).children.compactMap(\.label))

        XCTAssertTrue(recordedContextMembers.symmetricDifference(metricsObjectMembers).isEmpty)
    }

    func testGetEventQueriesValuesMatchesMetricsQueriesValuesYaml() {
        let recordedContext = RecordedNimbusContext(
            isFirstRun: true,
            isDefaultBrowser: true,
            isBottomToolbarUser: true,
            hasEnabledTipsNotifications: true,
            hasAcceptedTermsOfUse: true,
            isAppleIntelligenceAvailable: true,
            cannotUseAppleIntelligence: true
        )

        let eventKeys = Set(
            recordedContext
                .getEventQueries().keys
                .map { snakeToCamelCase($0) }
        )
        let eventQueryValues = Set(
            Mirror(
                reflecting: GleanMetrics.NimbusSystem.RecordedNimbusContextObjectItemEventQueryValuesObject()
            ).children.compactMap(\.label)
        )

        XCTAssertTrue(eventKeys.symmetricDifference(eventQueryValues).isEmpty)
    }

    func testSnakeToCamelCaseCovertsWithoutNumber() {
        let snake = "snake_case_value"
        let expectedResult = "snakeCaseValue"

        XCTAssertEqual(snakeToCamelCase(snake), expectedResult)
    }

    func testSnakeToCamelCaseCovertsWithNumber() {
        let snakeNumberAtEnd = "snake_case_value_18"
        let expectedResultNumberAtEnd = "snakeCaseValue18"

        let snakeNumberInMiddle = "snake_case_18_value"
        let expectedResultNumberInMiddle = "snakeCase18Value"

        XCTAssertEqual(snakeToCamelCase(snakeNumberAtEnd), expectedResultNumberAtEnd)
        XCTAssertEqual(snakeToCamelCase(snakeNumberInMiddle), expectedResultNumberInMiddle)
    }

    private func snakeToCamelCase(_ string: String) -> String {
        let parts = string.split(separator: "_")
        guard let first = parts.first else { return string }

        let rest = parts.dropFirst().map { part -> String in
            guard let firstChar = part.first else { return "" }
            return String(firstChar).uppercased() + part.dropFirst()
        }

        return ([String(first)] + rest).joined()
    }
}
