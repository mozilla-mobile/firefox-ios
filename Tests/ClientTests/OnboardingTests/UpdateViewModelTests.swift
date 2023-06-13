// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client
import XCTest
import Shared

class UpdateViewModelTests: XCTestCase {
    var profile: MockProfile!
    var nimbusUtility: NimbusOnboardingTestingConfigUtility!
    typealias cards = NimbusOnboardingTestingConfigUtility.CardOrder

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        nimbusUtility = NimbusOnboardingTestingConfigUtility()
        nimbusUtility.setupNimbus(withOrder: cards.allCards)
        profile = MockProfile(databasePrefix: "UpdateViewModel_tests")
        profile.reopen()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
    }

    override func tearDown() {
        super.tearDown()
        profile.shutdown()
        profile = nil
        nimbusUtility = nil

        UserDefaults.standard.set(false, forKey: PrefsKeys.NimbusFeatureTestsOverride)
    }

    // MARK: Enable cards
    func testEnabledCards_ForHasSyncAccount() {
        profile.hasSyncableAccountMock = true
        let subject = createSubject()
        let expectation = expectation(description: "The hasAccount var has value")

        subject.hasSyncableAccount {
            subject.setupViewControllerDelegates(with: MockOnboardinCardDelegateController())

            XCTAssertEqual(subject.availableCards.count, 1)
            XCTAssertEqual(subject.availableCards[0].viewModel.name, cards.updateWelcome.rawValue)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testEnabledCards_ForSyncAccountDisabled() {
        profile.hasSyncableAccountMock = false
        let subject = createSubject()
        let expectation = expectation(description: "The hasAccount var has value")

        subject.hasSyncableAccount {
            subject.setupViewControllerDelegates(with: MockOnboardinCardDelegateController())

            XCTAssertEqual(subject.availableCards.count, 2)
            XCTAssertEqual(subject.availableCards[0].viewModel.name, cards.updateWelcome.rawValue)
            XCTAssertEqual(subject.availableCards[1].viewModel.name, cards.updateSync.rawValue)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    // MARK: Has Single card
    func testHasSingleCard_ForHasSyncAccount() {
        profile.hasSyncableAccountMock = true
        let subject = createSubject()
        let expectation = expectation(description: "The hasAccount var has value")

        subject.hasSyncableAccount {
            subject.setupViewControllerDelegates(with: MockOnboardinCardDelegateController())

            XCTAssertEqual(subject.shouldShowSingleCard, true)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testHasSingleCard_ForSyncAccountDisabled() {
        profile.hasSyncableAccountMock = false
        let subject = createSubject()
        subject.setupViewControllerDelegates(with: MockOnboardinCardDelegateController())

        XCTAssertEqual(subject.shouldShowSingleCard, false)
    }

    // MARK: ShouldShowFeature
    func testShouldShowCoverSheet_forceIsTrue() {
        let subject = createSubject()
        let currentTestAppVersion = "22.0"

        let shouldShow = subject.shouldShowUpdateSheet(force: true, appVersion: currentTestAppVersion)
        XCTAssertTrue(shouldShow)
    }

    func testShouldNotShowCoverSheet_featureFlagOff_appVersionKeyNil() {
        let subject = createSubject()
        let currentTestAppVersion = "22.0"
        UserDefaults.standard.set(true, forKey: PrefsKeys.NimbusFeatureTestsOverride)

        let shouldShow = subject.shouldShowUpdateSheet(appVersion: currentTestAppVersion)
        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.AppVersion.Latest), currentTestAppVersion)
        XCTAssertFalse(shouldShow)
    }

    func testShouldNotShowCoverSheetForSameVersion() {
        let subject = createSubject()
        let currentTestAppVersion = "22.0"
        UserDefaults.standard.set(true, forKey: PrefsKeys.NimbusFeatureTestsOverride)

        // Setting clean install to false
        profile.prefs.setString(currentTestAppVersion, forKey: PrefsKeys.AppVersion.Latest)
        let shouldShow = subject.shouldShowUpdateSheet(appVersion: currentTestAppVersion)
        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.AppVersion.Latest), currentTestAppVersion)
        XCTAssertFalse(shouldShow)
    }

    func testShouldNotShowCoverSheet_ForMinorVersionUpgrade() {
        let subject = createSubject()
        UserDefaults.standard.set(true, forKey: PrefsKeys.NimbusFeatureTestsOverride)

        let olderTestAppVersion = "21.0"
        let updatedTestAppVersion = "21.1"

        // Setting clean install to false
        profile.prefs.setString(olderTestAppVersion, forKey: PrefsKeys.AppVersion.Latest)

        let shouldShow = subject.shouldShowUpdateSheet(appVersion: updatedTestAppVersion)
        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.AppVersion.Latest), olderTestAppVersion)
        XCTAssertFalse(shouldShow)
    }

    func testShouldShowCoverSheetFromUpdateVersion() {
        let subject = createSubject()
        UserDefaults.standard.set(true, forKey: PrefsKeys.NimbusFeatureTestsOverride)

        let olderTestAppVersion = "21.0"
        let updatedTestAppVersion = "22.0"

        // Setting clean install to false
        profile.prefs.setString(olderTestAppVersion, forKey: PrefsKeys.AppVersion.Latest)

        let shouldShow = subject.shouldShowUpdateSheet(appVersion: updatedTestAppVersion)
        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.AppVersion.Latest), updatedTestAppVersion)
        XCTAssertTrue(shouldShow)
    }

    func testShouldShowCoverSheetForVersionNil() {
        let subject = createSubject()
        UserDefaults.standard.set(true, forKey: PrefsKeys.NimbusFeatureTestsOverride)

        let currentTestAppVersion = "22.0"

        let shouldShow = subject.shouldShowUpdateSheet(appVersion: currentTestAppVersion)
        XCTAssertFalse(shouldShow)
    }

    func testShouldSaveVersion_CleanInstall() {
        let subject = createSubject()
        UserDefaults.standard.set(true, forKey: PrefsKeys.NimbusFeatureTestsOverride)

        let currentTestAppVersion = "22.0"

        profile.prefs.setString(currentTestAppVersion, forKey: PrefsKeys.AppVersion.Latest)
        _ = subject.shouldShowUpdateSheet(appVersion: currentTestAppVersion)
        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.AppVersion.Latest), currentTestAppVersion)
    }

    func testShouldSaveVersion_UnsavedVersion() {
        let subject = createSubject()
        UserDefaults.standard.set(true, forKey: PrefsKeys.NimbusFeatureTestsOverride)

        let currentTestAppVersion = "22.0"

        _ = subject.shouldShowUpdateSheet(appVersion: currentTestAppVersion)
        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.AppVersion.Latest), currentTestAppVersion)
    }

    // MARK: - Private Helpers
    func createSubject(
        file: StaticString = #file,
        line: UInt = #line
    ) -> UpdateViewModel {
        let onboardingModel = NimbusOnboardingFeatureLayer().getOnboardingModel(for: .upgrade)
        let telemetryUtility = OnboardingTelemetryUtility(with: onboardingModel)
        let subject = UpdateViewModel(profile: profile,
                                      model: onboardingModel,
                                      telemetryUtility: telemetryUtility)

        trackForMemoryLeaks(subject, file: file, line: line)

        return subject
    }
}
