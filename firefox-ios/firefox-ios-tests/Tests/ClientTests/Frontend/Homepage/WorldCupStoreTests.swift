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

    // MARK: - isFeatureEnabled

    func test_isFeatureEnabled_whenNimbusFeatureEnabled_returnsTrue() {
        setNimbusFeature(enabled: true)
        let subject = createSubject()

        XCTAssertTrue(subject.isFeatureEnabled)
    }

    func test_isFeatureEnabled_whenNimbusFeatureDisabled_returnsFalse() {
        setNimbusFeature(enabled: false)
        let subject = createSubject()

        XCTAssertFalse(subject.isFeatureEnabled)
    }

    // MARK: - isFeatureEnabledAndSectionEnabled

    func test_isFeatureEnabledAndSectionEnabled_withFeatureOnAndSectionOn_returnsTrue() {
        setNimbusFeature(enabled: true, milestone2EnableDate: "2099-01-01T00:00:00Z")
        mockProfile.prefs.setBool(true, forKey: PrefsKeys.HomepageSettings.WorldCupSection)
        let subject = createSubject()

        XCTAssertTrue(subject.isFeatureEnabledAndSectionEnabled)
    }

    func test_isFeatureEnabledAndSectionEnabled_withFeatureOffAndSectionOn_returnsFalse() {
        setNimbusFeature(enabled: false, milestone2EnableDate: "2099-01-01T00:00:00Z")
        mockProfile.prefs.setBool(true, forKey: PrefsKeys.HomepageSettings.WorldCupSection)
        let subject = createSubject()

        XCTAssertFalse(subject.isFeatureEnabledAndSectionEnabled)
    }

    func test_isFeatureEnabledAndSectionEnabled_withFeatureOnAndSectionOff_returnsFalse() {
        setNimbusFeature(enabled: true, milestone2EnableDate: "2099-01-01T00:00:00Z")
        mockProfile.prefs.setBool(false, forKey: PrefsKeys.HomepageSettings.WorldCupSection)
        let subject = createSubject()

        XCTAssertFalse(subject.isFeatureEnabledAndSectionEnabled)
    }

    func test_isFeatureEnabledAndSectionEnabled_withoutSectionPref_defaultsToFeatureFlagValue() {
        setNimbusFeature(enabled: true, milestone2EnableDate: "2099-01-01T00:00:00Z")
        let subject = createSubject()

        XCTAssertTrue(subject.isFeatureEnabledAndSectionEnabled)
    }

    func test_isFeatureEnabledAndSectionEnabled_onMilestone2_whenSectionDisabled_forceEnablesSectionOnce() {
        setNimbusFeature(enabled: true, milestone2EnableDate: "2026-05-10T19:00:00Z")
        mockProfile.prefs.setBool(false, forKey: PrefsKeys.HomepageSettings.WorldCupSection)
        let subject = createSubject(
            dateProvider: MockDateProvider(fixedDate: iso8601Date("2026-05-11T00:00:00Z"))
        )

        XCTAssertTrue(subject.isFeatureEnabledAndSectionEnabled)
        XCTAssertEqual(
            mockProfile.prefs.boolForKey(PrefsKeys.HomepageSettings.WorldCupSection),
            true
        )
        XCTAssertEqual(
            mockProfile.prefs.boolForKey(PrefsKeys.HomepageSettings.WorldCupMilestone2Transitioned),
            true
        )
    }

    func test_isFeatureEnabledAndSectionEnabled_onMilestone2_afterTransition_respectsUserPreference() {
        setNimbusFeature(enabled: true, milestone2EnableDate: "2026-05-10T19:00:00Z")
        mockProfile.prefs.setBool(true, forKey: PrefsKeys.HomepageSettings.WorldCupMilestone2Transitioned)
        mockProfile.prefs.setBool(false, forKey: PrefsKeys.HomepageSettings.WorldCupSection)
        let subject = createSubject(
            dateProvider: MockDateProvider(fixedDate: iso8601Date("2026-05-11T00:00:00Z"))
        )

        XCTAssertFalse(subject.isFeatureEnabledAndSectionEnabled)
        XCTAssertEqual(
            mockProfile.prefs.boolForKey(PrefsKeys.HomepageSettings.WorldCupSection),
            false
        )
    }

    func test_isFeatureEnabledAndSectionEnabled_beforeMilestone2_doesNotTransition() {
        setNimbusFeature(enabled: true, milestone2EnableDate: "2026-05-10T19:00:00Z")
        mockProfile.prefs.setBool(false, forKey: PrefsKeys.HomepageSettings.WorldCupSection)
        let subject = createSubject(
            dateProvider: MockDateProvider(fixedDate: iso8601Date("2026-05-10T18:59:59Z"))
        )

        XCTAssertFalse(subject.isFeatureEnabledAndSectionEnabled)
        XCTAssertNil(mockProfile.prefs.boolForKey(PrefsKeys.HomepageSettings.WorldCupMilestone2Transitioned))
        XCTAssertEqual(
            mockProfile.prefs.boolForKey(PrefsKeys.HomepageSettings.WorldCupSection),
            false
        )
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

    // MARK: - seenWinningMatchIDs

    func test_seenWinningMatchIDs_returnsEmptyWhenUnset() {
        let subject = createSubject()

        XCTAssertTrue(subject.seenWinningMatchIDs.isEmpty)
    }

    func test_seenWinningMatchIDs_roundTripsThroughPrefs() {
        let subject = createSubject()
        let ids: Set<String> = ["ARG|BRA|Jun 12", "ARG|CHI|Jun 20"]

        subject.setSeenWinningMatchIDs(ids)

        XCTAssertEqual(subject.seenWinningMatchIDs, ids)
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

    // MARK: - hasWorldCupStarted

    func test_hasWorldCupStarted_whenNowIsAfterStartDate_returnsTrue() {
        setNimbusFeature(countdownTargetDate: "2026-06-11T19:00:00Z")
        let subject = createSubject(
            dateProvider: MockDateProvider(fixedDate: iso8601Date("2026-06-12T00:00:00Z"))
        )

        XCTAssertTrue(subject.hasWorldCupStarted)
    }

    func test_hasWorldCupStarted_whenNowIsBeforeStartDate_returnsFalse() {
        setNimbusFeature(countdownTargetDate: "2026-06-11T19:00:00Z")
        let subject = createSubject(
            dateProvider: MockDateProvider(fixedDate: iso8601Date("2026-06-11T18:59:59Z"))
        )

        XCTAssertFalse(subject.hasWorldCupStarted)
    }

    func test_hasWorldCupStarted_whenStartDateIsInvalid_returnsFalse() {
        setNimbusFeature(countdownTargetDate: "not-a-real-date")
        let subject = createSubject(dateProvider: MockDateProvider(fixedDate: Date()))

        XCTAssertFalse(subject.hasWorldCupStarted)
    }

    func test_hasWorldCupEnded_whenNowIsAfterEndDate_returnsTrue() {
        let subject = createSubject(
            dateProvider: MockDateProvider(fixedDate: iso8601Date("2026-07-20T08:00:01Z"))
        )

        XCTAssertTrue(subject.hasWorldCupEnded)
    }

    func test_hasWorldCupEnded_atEndDate_returnsTrue() {
        let subject = createSubject(
            dateProvider: MockDateProvider(fixedDate: iso8601Date(WorldCupStore.worldCupEndDateString))
        )

        XCTAssertTrue(subject.hasWorldCupEnded)
    }

    func test_hasWorldCupEnded_whenNowIsBeforeEndDate_returnsFalse() {
        let subject = createSubject(
            dateProvider: MockDateProvider(fixedDate: iso8601Date("2026-07-20T07:59:59Z"))
        )

        XCTAssertFalse(subject.hasWorldCupEnded)
    }

    // MARK: - kill switch

    func test_isFeatureEnabled_afterWorldCupEnded_returnsFalseEvenWhenNimbusEnabled() {
        setNimbusFeature(enabled: true)
        let subject = createSubject(
            dateProvider: MockDateProvider(fixedDate: iso8601Date("2026-07-20T08:00:01Z"))
        )

        XCTAssertFalse(subject.isFeatureEnabled)
    }

    func test_isFeatureEnabledAndSectionEnabled_afterWorldCupEnded_returnsFalse() {
        setNimbusFeature(enabled: true, milestone2EnableDate: "2026-05-10T19:00:00Z")
        mockProfile.prefs.setBool(true, forKey: PrefsKeys.HomepageSettings.WorldCupSection)
        let subject = createSubject(
            dateProvider: MockDateProvider(fixedDate: iso8601Date("2026-07-20T08:00:01Z"))
        )

        XCTAssertFalse(subject.isFeatureEnabledAndSectionEnabled)
    }

    func test_isFeatureEnabled_beforeWorldCupEnded_stillReflectsNimbus() {
        setNimbusFeature(enabled: true)
        let subject = createSubject(
            dateProvider: MockDateProvider(fixedDate: iso8601Date("2026-07-20T07:59:59Z"))
        )

        XCTAssertTrue(subject.isFeatureEnabled)
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

    func test_setSelectedTeam_withNil_clearsPref() {
        mockProfile.prefs.setString("ESP", forKey: PrefsKeys.Homepage.WorldCupSelectedCountry)
        let subject = createSubject()

        subject.setSelectedTeam(countryId: nil)

        XCTAssertNil(mockProfile.prefs.stringForKey(PrefsKeys.Homepage.WorldCupSelectedCountry))
    }

    // MARK: - Helpers

    /// A fixed instant during the tournament (after start, before the end
    /// kill-switch) used as the default clock so tests are deterministic and do
    /// not flip once the real date passes `WorldCupStore.worldCupEndDateString`.
    private static let duringTournamentDate = ISO8601DateFormatter().date(from: "2026-06-15T00:00:00Z")!

    private func createSubject(
        dateProvider: DateProvider = MockDateProvider(fixedDate: WorldCupStoreTests.duringTournamentDate)
    ) -> WorldCupStore {
        return WorldCupStore(
            profile: mockProfile,
            nimbusFeature: FxNimbus.shared.features.worldCupWidgetFeature,
            dateProvider: dateProvider
        )
    }

    private func setNimbusFeature(
        enabled: Bool = false,
        milestone2EnableDate: String = "2026-05-10T19:00:00Z",
        countdownTargetDate: String = "2026-06-11T19:00:00Z"
    ) {
        FxNimbus.shared.features.worldCupWidgetFeature.with { _, _ in
            return WorldCupWidgetFeature(
                countdownTargetDate: countdownTargetDate,
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
