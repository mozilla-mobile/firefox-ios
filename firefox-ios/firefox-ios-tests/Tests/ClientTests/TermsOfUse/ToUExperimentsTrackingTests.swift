// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import Shared
import struct MozillaAppServices.EnrolledExperiment
@testable import Client

/// Verifies ToU experiment tracking reset data behavior
/// - No reset for users who accepted ToU,
///  are already enrolled in experiment
/// - Reset data for retargeting on experiment/branch
/// change or if they enroll again in a new experiment
@MainActor
final class ToUExperimentsTrackingTests: XCTestCase {
    private var profile: MockProfile!
    private var tracking: ToUExperimentsTracking!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        tracking = ToUExperimentsTracking(prefs: profile.prefs)
    }

    override func tearDown() async throws {
        tracking = nil
        profile = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    private func createToUExperiment(
        slug: String,
        branch: String,
        name: String = "Test"
    ) -> EnrolledExperiment {
        EnrolledExperiment(
            featureIds: ["tou-feature"],
            slug: slug,
            userFacingName: name,
            userFacingDescription: "Test",
            branchSlug: branch
        )
    }

    /// Build experiment key string (slug|branch|name)
    private func experimentKey(slug: String, branch: String, name: String = "Test") -> String {
        "\(slug)|\(branch)|\(name)"
    }

    private func setupStoredExperimentKey(_ key: String) {
        profile.prefs.setString(key, forKey: PrefsKeys.TermsOfUseExperimentKey)
    }

    private func storedSlug() -> String? {
        let fp = profile.prefs.stringForKey(PrefsKeys.TermsOfUseExperimentKey)
        return fp?.split(separator: "|").first.map(String.init)
    }

    private func storedBranch() -> String? {
        let fp = profile.prefs.stringForKey(PrefsKeys.TermsOfUseExperimentKey)
        guard let parts = fp?.split(separator: "|"), parts.count > 1 else { return nil }
        return String(parts[1])
    }

    private func setupDismissalData(remindersCount: Int = 2) {
        profile.prefs.setTimestamp(Date().toTimestamp(), forKey: PrefsKeys.TermsOfUseDismissedDate)
        profile.prefs.setInt(Int32(remindersCount), forKey: PrefsKeys.TermsOfUseRemindersCount)
    }

    private func assertDismissalDataReset() {
        XCTAssertNil(profile.prefs.timestampForKey(PrefsKeys.TermsOfUseDismissedDate))
        XCTAssertEqual(profile.prefs.intForKey(PrefsKeys.TermsOfUseRemindersCount), 0)
        XCTAssertFalse(profile.prefs.boolForKey(PrefsKeys.TermsOfUseFirstShown) ?? true)
        XCTAssertFalse(profile.prefs.boolForKey(PrefsKeys.TermsOfUseShownRecorded) ?? true)
    }

    private func assertDismissalDataNotReset(expectedCount: Int) {
        XCTAssertNotNil(profile.prefs.timestampForKey(PrefsKeys.TermsOfUseDismissedDate))
        XCTAssertEqual(profile.prefs.intForKey(PrefsKeys.TermsOfUseRemindersCount), Int32(expectedCount))
    }

    // MARK: Reset

    func testResetToUDataIfNeeded_Resets_WhenDifferentExperiment() {
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseFirstShown)
        setupStoredExperimentKey(experimentKey(slug: "exp-1", branch: "branch-a"))
        setupDismissalData(remindersCount: 3)

        tracking.resetToUDataIfNeeded(currentExperiment: createToUExperiment(slug: "exp-2", branch: "branch-a"))

        assertDismissalDataReset()
        XCTAssertEqual(storedSlug(), "exp-2")
    }

    func testResetToUDataIfNeeded_Resets_WhenDifferentBranchSameExperiment() {
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseFirstShown)
        setupStoredExperimentKey(experimentKey(slug: "exp-1", branch: "branch-a"))
        setupDismissalData(remindersCount: 2)

        tracking.resetToUDataIfNeeded(currentExperiment: createToUExperiment(slug: "exp-1", branch: "branch-b"))

        assertDismissalDataReset()
        XCTAssertEqual(storedBranch(), "branch-b")
    }

    func testResetToUDataIfNeeded_Resets_WhenSameSlugAndBranchButNameChanged() {
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseFirstShown)
        setupStoredExperimentKey("exp-1|branch-a|Old Name")
        setupDismissalData(remindersCount: 2)

        tracking.resetToUDataIfNeeded(currentExperiment: createToUExperiment(
            slug: "exp-1",
            branch: "branch-a",
            name: "New Name"
        ))

        assertDismissalDataReset()
        XCTAssertEqual(storedSlug(), "exp-1")
        XCTAssertEqual(storedBranch(), "branch-a")
    }

    func testResetToUDataIfNeeded_DoesNotReset_WhenUnenrolled() {
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseFirstShown)
        setupStoredExperimentKey(experimentKey(slug: "exp-1", branch: "branch-a"))
        setupDismissalData(remindersCount: 2)

        tracking.resetToUDataIfNeeded(currentExperiment: nil)

        assertDismissalDataNotReset(expectedCount: 2)
        XCTAssertEqual(storedSlug(), "exp-1")
    }

    func testResetToUDataIfNeeded_DoesNotReset_WhenUnenrolledThenReEnrolledInSameExperiment() {
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseFirstShown)
        setupStoredExperimentKey(experimentKey(slug: "exp-1", branch: "branch-a"))
        setupDismissalData(remindersCount: 2)

        tracking.resetToUDataIfNeeded(currentExperiment: nil)
        assertDismissalDataNotReset(expectedCount: 2)

        tracking.resetToUDataIfNeeded(currentExperiment: createToUExperiment(slug: "exp-1", branch: "branch-a"))
        assertDismissalDataNotReset(expectedCount: 2)
        XCTAssertEqual(storedSlug(), "exp-1")
    }

    // MARK: No reset

    func testResetToUDataIfNeeded_DoesNotReset_WhenUserHasAcceptedToU() {
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseAccepted)
        setupStoredExperimentKey(experimentKey(slug: "exp-1", branch: "branch-a"))
        setupDismissalData(remindersCount: 5)

        tracking.resetToUDataIfNeeded(currentExperiment: createToUExperiment(slug: "exp-2", branch: "branch-b"))

        assertDismissalDataNotReset(expectedCount: 5)
        XCTAssertEqual(storedSlug(), "exp-1")
    }

    func testResetToUDataIfNeeded_DoesNotReset_WhenSameExperimentAndSameBranch() {
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseFirstShown)
        setupStoredExperimentKey(experimentKey(slug: "exp-1", branch: "branch-a"))
        setupDismissalData(remindersCount: 3)

        tracking.resetToUDataIfNeeded(currentExperiment: createToUExperiment(slug: "exp-1", branch: "branch-a"))

        assertDismissalDataNotReset(expectedCount: 3)
    }

    func testResetToUDataIfNeeded_DoesNotReset_WhenBottomSheetNotShownYet() {
        setupStoredExperimentKey(experimentKey(slug: "exp-1", branch: "branch-a"))
        setupDismissalData(remindersCount: 2)

        tracking.resetToUDataIfNeeded(currentExperiment: createToUExperiment(slug: "exp-2", branch: "branch-b"))

        assertDismissalDataNotReset(expectedCount: 2)
        XCTAssertEqual(storedSlug(), "exp-2")
    }

    func testResetToUDataIfNeeded_DoesNotReset_WhenNoDismissalData_ExperimentChange() {
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseFirstShown)
        setupStoredExperimentKey(experimentKey(slug: "exp-1", branch: "branch-a"))

        tracking.resetToUDataIfNeeded(currentExperiment: createToUExperiment(slug: "exp-2", branch: "branch-b"))

        XCTAssertNil(profile.prefs.timestampForKey(PrefsKeys.TermsOfUseDismissedDate))
        XCTAssertNil(profile.prefs.intForKey(PrefsKeys.TermsOfUseRemindersCount))
        XCTAssertEqual(storedSlug(), "exp-2")
    }

    func testResetToUDataIfNeeded_DoesNotReset_WhenNoDismissalData_FirstEnrollment() {
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseFirstShown)

        tracking.resetToUDataIfNeeded(currentExperiment: createToUExperiment(slug: "exp-1", branch: "branch-a"))

        XCTAssertNil(profile.prefs.timestampForKey(PrefsKeys.TermsOfUseDismissedDate))
        XCTAssertNil(profile.prefs.intForKey(PrefsKeys.TermsOfUseRemindersCount))
        XCTAssertEqual(storedSlug(), "exp-1")
    }

    // MARK: Legacy users

    func testResetToUDataIfNeeded_LegacyEnrolled_DoesNotReset() {
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseFirstShown)
        setupDismissalData(remindersCount: 2)

        tracking.resetToUDataIfNeeded(currentExperiment: createToUExperiment(slug: "exp-1", branch: "branch-a"))

        assertDismissalDataNotReset(expectedCount: 2)
        XCTAssertEqual(storedSlug(), "exp-1")
    }

    func testResetToUDataIfNeeded_LegacyUnenrolled_FirstRun_NoReset_ThenEnrolled_Resets() {
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseFirstShown)
        setupDismissalData(remindersCount: 2)

        tracking.resetToUDataIfNeeded(currentExperiment: nil)
        assertDismissalDataNotReset(expectedCount: 2)
        XCTAssertNil(storedSlug())

        tracking.resetToUDataIfNeeded(currentExperiment: createToUExperiment(slug: "exp-1", branch: "branch-a"))
        assertDismissalDataReset()
        XCTAssertEqual(storedSlug(), "exp-1")
    }

    func testResetToUDataIfNeeded_LegacyNeverEnrolled_NoExperiment_NoReset() {
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseFirstShown)

        tracking.resetToUDataIfNeeded(currentExperiment: nil)

        XCTAssertNil(storedSlug())
        XCTAssertNil(profile.prefs.timestampForKey(PrefsKeys.TermsOfUseDismissedDate))
    }

    func testResetToUDataIfNeeded_LegacyNeverEnrolled_NowEnrolled_NoDismissalData_StoresSlugOnly() {
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseFirstShown)

        tracking.resetToUDataIfNeeded(currentExperiment: createToUExperiment(slug: "exp-1", branch: "branch-a"))

        XCTAssertEqual(storedSlug(), "exp-1")
        XCTAssertNil(profile.prefs.timestampForKey(PrefsKeys.TermsOfUseDismissedDate))
    }

    // MARK: Edge cases

    func testResetToUDataIfNeeded_NoExperimentAndNoStoredSlug_StoresNothing() {
        tracking.resetToUDataIfNeeded(currentExperiment: nil)

        XCTAssertNil(storedSlug())
    }

    func testResetToUDataIfNeeded_UnenrollThenReEnroll_NoResetOnUnenroll_ResetOnReEnroll() {
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseFirstShown)
        setupStoredExperimentKey(experimentKey(slug: "exp-1", branch: "branch-a"))
        setupDismissalData(remindersCount: 2)

        tracking.resetToUDataIfNeeded(currentExperiment: nil)
        assertDismissalDataNotReset(expectedCount: 2)
        XCTAssertEqual(storedSlug(), "exp-1")

        tracking.resetToUDataIfNeeded(currentExperiment: createToUExperiment(slug: "exp-2", branch: "branch-b"))
        assertDismissalDataReset()
        XCTAssertEqual(storedSlug(), "exp-2")
        XCTAssertEqual(storedBranch(), "branch-b")
    }
}
