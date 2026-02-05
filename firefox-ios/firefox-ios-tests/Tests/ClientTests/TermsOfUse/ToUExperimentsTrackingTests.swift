// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import Shared
import struct MozillaAppServices.EnrolledExperiment
@testable import Client

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

    private func createToUExperiment(slug: String, branch: String) -> EnrolledExperiment {
        EnrolledExperiment(
            featureIds: ["tou-feature"],
            slug: slug,
            userFacingName: "Test",
            userFacingDescription: "Test",
            branchSlug: branch
        )
    }

    private func setupExperiment(slug: String, branch: String) {
        profile.prefs.setString(slug, forKey: PrefsKeys.TermsOfUseExperimentSlug)
        profile.prefs.setString(branch, forKey: PrefsKeys.TermsOfUseExperimentBranch)
    }

    private func setupDismissalData(remindersCount: Int = 2) {
        profile.prefs.setTimestamp(Date().toTimestamp(), forKey: PrefsKeys.TermsOfUseDismissedDate)
        profile.prefs.setInt(Int32(remindersCount), forKey: PrefsKeys.TermsOfUseRemindersCount)
    }

    private func assertDismissalDataReset() {
        XCTAssertNil(profile.prefs.timestampForKey(PrefsKeys.TermsOfUseDismissedDate))
        XCTAssertEqual(profile.prefs.intForKey(PrefsKeys.TermsOfUseRemindersCount), 0)
    }

    private func assertDismissalDataNotReset(expectedCount: Int) {
        XCTAssertNotNil(profile.prefs.timestampForKey(PrefsKeys.TermsOfUseDismissedDate))
        XCTAssertEqual(profile.prefs.intForKey(PrefsKeys.TermsOfUseRemindersCount), Int32(expectedCount))
    }

    // MARK: Reset Cases

    func testResetToUDataIfNeeded_Resets_WhenExperimentSlugChanges() {
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseFirstShown)
        setupExperiment(slug: "exp-1", branch: "branch-a")
        setupDismissalData(remindersCount: 3)

        tracking.resetToUDataIfNeeded(currentExperiment: createToUExperiment(slug: "exp-2", branch: "branch-a"))

        assertDismissalDataReset()
        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.TermsOfUseExperimentSlug), "exp-2")
    }

    func testResetToUDataIfNeeded_Resets_WhenBranchChanges() {
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseFirstShown)
        setupExperiment(slug: "exp-1", branch: "branch-a")
        setupDismissalData(remindersCount: 2)

        tracking.resetToUDataIfNeeded(currentExperiment: createToUExperiment(slug: "exp-1", branch: "branch-b"))

        assertDismissalDataReset()
        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.TermsOfUseExperimentBranch), "branch-b")
    }

    func testResetToUDataIfNeeded_Resets_WhenUserUnenrolled() {
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseFirstShown)
        setupExperiment(slug: "exp-1", branch: "branch-a")
        setupDismissalData(remindersCount: 2)

        tracking.resetToUDataIfNeeded(currentExperiment: nil)

        assertDismissalDataReset()
        XCTAssertNil(profile.prefs.stringForKey(PrefsKeys.TermsOfUseExperimentSlug))
    }

    // MARK: No Reset Cases

    func testResetToUDataIfNeeded_DoesNotReset_WhenUserHasAccepted() {
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseAccepted)
        setupExperiment(slug: "exp-1", branch: "branch-a")
        setupDismissalData(remindersCount: 5)

        tracking.resetToUDataIfNeeded(currentExperiment: createToUExperiment(slug: "exp-2", branch: "branch-b"))

        assertDismissalDataNotReset(expectedCount: 5)
        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.TermsOfUseExperimentSlug), "exp-1")
    }

    func testResetToUDataIfNeeded_DoesNotReset_WhenSameExperimentAndBranch() {
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseFirstShown)
        setupExperiment(slug: "exp-1", branch: "branch-a")
        setupDismissalData(remindersCount: 3)

        tracking.resetToUDataIfNeeded(currentExperiment: createToUExperiment(slug: "exp-1", branch: "branch-a"))

        assertDismissalDataNotReset(expectedCount: 3)
    }

    func testResetToUDataIfNeeded_DoesNotReset_WhenFirstEnrollmentAndNoDismissalData() {
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseFirstShown)
        tracking.resetToUDataIfNeeded(currentExperiment: createToUExperiment(slug: "exp-1", branch: "branch-a"))

        XCTAssertNil(profile.prefs.timestampForKey(PrefsKeys.TermsOfUseDismissedDate))
        XCTAssertNil(profile.prefs.intForKey(PrefsKeys.TermsOfUseRemindersCount))
        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.TermsOfUseExperimentSlug), "exp-1")
    }

    func testResetToUDataIfNeeded_DoesNotReset_WhenExperimentChangesButNoDismissalData() {
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseFirstShown)
        setupExperiment(slug: "exp-1", branch: "branch-a")

        tracking.resetToUDataIfNeeded(currentExperiment: createToUExperiment(slug: "exp-2", branch: "branch-b"))

        XCTAssertNil(profile.prefs.timestampForKey(PrefsKeys.TermsOfUseDismissedDate))
        XCTAssertNil(profile.prefs.intForKey(PrefsKeys.TermsOfUseRemindersCount))
        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.TermsOfUseExperimentSlug), "exp-2")
    }

    func testResetToUDataIfNeeded_DoesNotReset_WhenFirstRunWithNewCode() {
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseFirstShown)
        // User already in experiment when receiving new code, so slug is already stored
        setupExperiment(slug: "exp-1", branch: "branch-a")
        setupDismissalData(remindersCount: 2)

        tracking.resetToUDataIfNeeded(currentExperiment: createToUExperiment(slug: "exp-1", branch: "branch-a"))

        assertDismissalDataNotReset(expectedCount: 2)
        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.TermsOfUseExperimentSlug), "exp-1")
    }

    // MARK: Edge Cases

    func testResetToUDataIfNeeded_DoesNotReset_WhenNoExperimentAndNoStored() {
        tracking.resetToUDataIfNeeded(currentExperiment: nil)

        XCTAssertNil(profile.prefs.stringForKey(PrefsKeys.TermsOfUseExperimentSlug))
    }

    func testResetToUDataIfNeeded_Retargeting_UnenrollThenReEnroll() {
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseFirstShown)
        setupExperiment(slug: "exp-1", branch: "branch-a")
        setupDismissalData(remindersCount: 2)

        tracking.resetToUDataIfNeeded(currentExperiment: nil)
        assertDismissalDataReset()
        XCTAssertNil(profile.prefs.stringForKey(PrefsKeys.TermsOfUseExperimentSlug))

        tracking.resetToUDataIfNeeded(currentExperiment: createToUExperiment(slug: "exp-2", branch: "branch-b"))
        assertDismissalDataReset()
        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.TermsOfUseExperimentSlug), "exp-2")
        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.TermsOfUseExperimentBranch), "branch-b")
    }

    func testResetToUDataIfNeeded_Resets_WhenUnenrolledBeforeNewCodeThenEnrolls() {
        // User was unenrolled when receiving new code, has dismissal data, then enrolls
        // Reset to allow retargeting
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseFirstShown)
        setupDismissalData(remindersCount: 2)
        // No stored slug (user was unenrolled when receiving new code)

        tracking.resetToUDataIfNeeded(currentExperiment: createToUExperiment(slug: "exp-1", branch: "branch-a"))

        assertDismissalDataReset()
        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.TermsOfUseExperimentSlug), "exp-1")
    }

    func testExperimentChangeObserver_InitializesCorrectly() {
        let observer = ExperimentChangeObserver(prefs: profile.prefs)
        XCTAssertNotNil(observer)
    }
}
