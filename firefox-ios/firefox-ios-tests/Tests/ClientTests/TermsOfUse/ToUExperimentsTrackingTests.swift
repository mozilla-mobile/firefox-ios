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

    private func createToUExperiment(slug: String, branch: String, featureIds: [String] = ["tou-feature"]) -> EnrolledExperiment {
        EnrolledExperiment(
            featureIds: featureIds,
            slug: slug,
            userFacingName: "Test",
            userFacingDescription: "Test",
            branchSlug: branch
        )
    }

    private func createNonToUExperiment(slug: String, branch: String) -> EnrolledExperiment {
        EnrolledExperiment(
            featureIds: ["other-feature"],
            slug: slug,
            userFacingName: "Other",
            userFacingDescription: "Other",
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

    // MARK: - resetToUDataIfNeeded
    func testResetToUDataIfNeeded_DoesNotReset_WhenUserHasAccepted() {
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseAccepted)
        setupExperiment(slug: "exp-1", branch: "branch-a")
        setupDismissalData(remindersCount: 5)

        tracking.resetToUDataIfNeeded(currentExperiment: createToUExperiment(slug: "exp-2", branch: "branch-b"))

        assertDismissalDataNotReset(expectedCount: 5)
        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.TermsOfUseExperimentSlug), "exp-1")
    }
    
    func testResetToUDataIfNeeded_Resets_WhenExperimentSlugChanges() {
        setupExperiment(slug: "exp-1", branch: "branch-a")
        setupDismissalData(remindersCount: 3)
        
        tracking.resetToUDataIfNeeded(currentExperiment: createToUExperiment(slug: "exp-2", branch: "branch-a"))
        
        assertDismissalDataReset()
        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.TermsOfUseExperimentSlug), "exp-2")
    }
    
    func testResetToUDataIfNeeded_Resets_WhenBranchChanges() {
        setupExperiment(slug: "exp-1", branch: "branch-a")
        setupDismissalData(remindersCount: 2)
        
        tracking.resetToUDataIfNeeded(currentExperiment: createToUExperiment(slug: "exp-1", branch: "branch-b"))
        
        assertDismissalDataReset()
        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.TermsOfUseExperimentBranch), "branch-b")
    }
    
    func testResetToUDataIfNeeded_DoesNotReset_WhenSameExperimentAndBranch() {
        setupExperiment(slug: "exp-1", branch: "branch-a")
        setupDismissalData(remindersCount: 3)
        
        tracking.resetToUDataIfNeeded(currentExperiment: createToUExperiment(slug: "exp-1", branch: "branch-a"))
        
        assertDismissalDataNotReset(expectedCount: 3)
    }
    
    func testResetToUDataIfNeeded_Resets_WhenUserUnenrolled() {
        setupExperiment(slug: "exp-1", branch: "branch-a")
        setupDismissalData(remindersCount: 2)
        
        tracking.resetToUDataIfNeeded(currentExperiment: nil)
        
        assertDismissalDataReset()
        XCTAssertNil(profile.prefs.stringForKey(PrefsKeys.TermsOfUseExperimentSlug))
    }
    
    func testResetToUDataIfNeeded_StoresExperiment_WhenFirstEnrollment() {
        let experiment = createToUExperiment(slug: "exp-1", branch: "branch-a")
        tracking.resetToUDataIfNeeded(currentExperiment: experiment)
        
        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.TermsOfUseExperimentSlug), "exp-1")
        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.TermsOfUseExperimentBranch), "branch-a")
    }
    
    func testResetToUDataIfNeeded_DoesNotReset_WhenNoExperimentAndNoStored() {
        tracking.resetToUDataIfNeeded(currentExperiment: nil)
        
        XCTAssertNil(profile.prefs.stringForKey(PrefsKeys.TermsOfUseExperimentSlug))
    }
    
    func testResetToUDataIfNeeded_DoesNotReset_WhenFirstEnrollmentAndNoDismissalData() {
        let experiment = createToUExperiment(slug: "exp-1", branch: "branch-a")
        tracking.resetToUDataIfNeeded(currentExperiment: experiment)
        
        XCTAssertNil(profile.prefs.timestampForKey(PrefsKeys.TermsOfUseDismissedDate))
        XCTAssertEqual(profile.prefs.intForKey(PrefsKeys.TermsOfUseRemindersCount), 0)
        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.TermsOfUseExperimentSlug), "exp-1")
    }
    
    func testResetToUDataIfNeeded_DoesNotReset_WhenExperimentChangesButNoDismissalData() {
        setupExperiment(slug: "exp-1", branch: "branch-a")
        
        tracking.resetToUDataIfNeeded(currentExperiment: createToUExperiment(slug: "exp-2", branch: "branch-b"))
        
        XCTAssertNil(profile.prefs.timestampForKey(PrefsKeys.TermsOfUseDismissedDate))
        XCTAssertEqual(profile.prefs.intForKey(PrefsKeys.TermsOfUseRemindersCount), 0)
        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.TermsOfUseExperimentSlug), "exp-2")
    }
    
    // MARK: - identifyToUExperiment
    
    func testIdentifyToUExperiment_FindsStoredExperiment_WhenMultipleExist() {
        profile.prefs.setString("exp-1", forKey: PrefsKeys.TermsOfUseExperimentSlug)
        let experiments = [
            createToUExperiment(slug: "exp-0", branch: "branch-a"),
            createToUExperiment(slug: "exp-1", branch: "branch-a"),
            createToUExperiment(slug: "exp-2", branch: "branch-b"),
            createNonToUExperiment(slug: "other", branch: "control")
        ]
        
        let identified = tracking.identifyToUExperiment(from: experiments)
        
        XCTAssertEqual(identified?.slug, "exp-1")
        XCTAssertEqual(identified?.branchSlug, "branch-a")
    }
    
    func testIdentifyToUExperiment_ReturnsFirst_WhenNoStoredExperiment() {
        let experiments = [
            createToUExperiment(slug: "exp-0", branch: "branch-a"),
            createToUExperiment(slug: "exp-1", branch: "branch-b")
        ]
        
        let identified = tracking.identifyToUExperiment(from: experiments)
        
        XCTAssertEqual(identified?.slug, "exp-0")
    }
    
    func testIdentifyToUExperiment_ReturnsNil_WhenNoToUExperiments() {
        let identified = tracking.identifyToUExperiment(from: [
            createNonToUExperiment(slug: "other-1", branch: "control"),
            createNonToUExperiment(slug: "other-2", branch: "treatment")
        ])
        
        XCTAssertNil(identified)
    }
    
    func testIdentifyToUExperiment_ReturnsNil_WhenEmptyList() {
        XCTAssertNil(tracking.identifyToUExperiment(from: []))
    }
    
    func testIdentifyToUExperiment_ReturnsFirst_WhenStoredExperimentNotInList() {
        profile.prefs.setString("exp-1", forKey: PrefsKeys.TermsOfUseExperimentSlug)
        let experiments = [
            createToUExperiment(slug: "exp-0", branch: "branch-a"),
            createToUExperiment(slug: "exp-2", branch: "branch-b")
        ]
        
        let identified = tracking.identifyToUExperiment(from: experiments)
        
        XCTAssertEqual(identified?.slug, "exp-0")
    }
    
    func testIdentifyToUExperiment_FiltersOnlyToUExperiments() {
        let experiments = [
            createNonToUExperiment(slug: "other-1", branch: "control"),
            createToUExperiment(slug: "exp-1", branch: "branch-a"),
            createNonToUExperiment(slug: "other-2", branch: "treatment"),
            createToUExperiment(slug: "exp-2", branch: "branch-b")
        ]
        
        let identified = tracking.identifyToUExperiment(from: experiments)
        
        XCTAssertTrue(identified?.featureIds.contains("tou-feature") ?? false)
        XCTAssertEqual(identified?.slug, "exp-1")
    }
    
    func testIdentifyToUExperiment_HandlesMultipleFeatureIds() {
        let experiment = createToUExperiment(
            slug: "exp-1",
            branch: "branch-a",
            featureIds: ["tou-feature", "other-feature"]
        )
        
        let identified = tracking.identifyToUExperiment(from: [experiment])
        
        XCTAssertEqual(identified?.slug, "exp-1")
    }
        
    func testSetupExperimentChangeObserver_ReturnsValidObserver() {
        let observer = tracking.setupExperimentChangeObserver()
        XCTAssertNotNil(observer)
    }
}
