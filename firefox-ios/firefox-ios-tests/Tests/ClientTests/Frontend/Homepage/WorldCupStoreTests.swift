// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
@testable import Client

@MainActor
final class WorldCupStoreTests: XCTestCase {
    private var mockProfile: MockProfile!

    override func setUp() async throws {
        try await super.setUp()
        mockProfile = MockProfile()
        DependencyHelperMock().bootstrapDependencies(injectedProfile: mockProfile)
        setNimbusFeature(enabled: false, milestone2EnableDate: "2026-05-10T19:00:00Z")
    }

    override func tearDown() async throws {
        mockProfile = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - isFeatureEnabledAndSectionEnabled

    func test_isFeatureEnabledAndSectionEnabled_withFeatureOnAndSectionOn_returnsTrue() {
        setNimbusFeature(enabled: true)
        mockProfile.prefs.setBool(true, forKey: PrefsKeys.HomepageSettings.WorldCupSection)
        let subject = createSubject()

        XCTAssertTrue(subject.isFeatureEnabledAndSectionEnabled)
    }

    func test_isFeatureEnabledAndSectionEnabled_withFeatureOffAndSectionOn_returnsFalse() {
        setNimbusFeature(enabled: false)
        mockProfile.prefs.setBool(true, forKey: PrefsKeys.HomepageSettings.WorldCupSection)
        let subject = createSubject()

        XCTAssertFalse(subject.isFeatureEnabledAndSectionEnabled)
    }

    func test_isFeatureEnabledAndSectionEnabled_withFeatureOnAndSectionOff_returnsFalse() {
        setNimbusFeature(enabled: true)
        mockProfile.prefs.setBool(false, forKey: PrefsKeys.HomepageSettings.WorldCupSection)
        let subject = createSubject()

        XCTAssertFalse(subject.isFeatureEnabledAndSectionEnabled)
    }

    func test_isFeatureEnabledAndSectionEnabled_withoutSectionPref_defaultsToFeatureFlagValue() {
        setNimbusFeature(enabled: true)
        let subject = createSubject()

        XCTAssertTrue(subject.isFeatureEnabledAndSectionEnabled)
    }

    // MARK: - selectedTeam

    func test_selectedTeam_returnsNilWhenUnset() {
        let subject = createSubject()

        XCTAssertNil(subject.selectedTeam)
    }

    func test_selectedTeam_returnsValueWhenSet() {
        let subject = createSubject()
        mockProfile.prefs.setString("FRA", forKey: PrefsKeys.Homepage.WorldCupSelectedCountry)

        XCTAssertEqual(subject.selectedTeam, "FRA")
    }

    // MARK: - isMilestone2

    func test_isMilestone2_whenNowIsAfterEnableDate_returnsTrue() {
        setNimbusFeature(milestone2EnableDate: "2026-05-10T19:00:00Z")
        let subject = createSubject(
            dateProvider: MockDateProvider(fixedDate: iso8601Date("2026-05-11T00:00:00Z"))
        )

        XCTAssertTrue(subject.isMilestone2)
    }

    func test_isMilestone2_whenNowIsBeforeEnableDate_returnsFalse() {
        setNimbusFeature(milestone2EnableDate: "2026-05-10T19:00:00Z")
        let subject = createSubject(
            dateProvider: MockDateProvider(fixedDate: iso8601Date("2026-05-10T18:59:59Z"))
        )

        XCTAssertFalse(subject.isMilestone2)
    }

    func test_isMilestone2_whenEnableDateIsInvalid_returnsFalse() {
        setNimbusFeature(milestone2EnableDate: "not-a-real-date")
        let subject = createSubject(dateProvider: MockDateProvider(fixedDate: Date()))

        XCTAssertFalse(subject.isMilestone2)
    }

    // MARK: - setIsHomepageSectionEnabled

    func test_setIsHomepageSectionEnabled_writesToPrefs() {
        let subject = createSubject()

        subject.setIsHomepageSectionEnabled(true)

        XCTAssertEqual(
            mockProfile.prefs.boolForKey(PrefsKeys.HomepageSettings.WorldCupSection),
            true
        )
    }

    // MARK: - setSelectedTeam

    func test_setSelectedTeam_writesToPrefs() {
        let subject = createSubject()

        subject.setSelectedTeam(countryId: "ESP")

        XCTAssertEqual(
            mockProfile.prefs.stringForKey(PrefsKeys.Homepage.WorldCupSelectedCountry),
            "ESP"
        )
    }

    // MARK: - Helpers

    private func createSubject(
        dateProvider: DateProvider = MockDateProvider(fixedDate: Date())
    ) -> WorldCupStore {
        return WorldCupStore(
            profile: mockProfile,
            nimbusFeature: FxNimbus.shared.features.worldCupWidgetFeature,
            dateProvider: dateProvider
        )
    }

    private func setNimbusFeature(
        enabled: Bool = false,
        milestone2EnableDate: String = "2026-05-10T19:00:00Z"
    ) {
        FxNimbus.shared.features.worldCupWidgetFeature.with { _, _ in
            return WorldCupWidgetFeature(
                enabled: enabled,
                milestone2EnableDate: milestone2EnableDate
            )
        }
    }

    private func iso8601Date(_ string: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)!
    }
}
