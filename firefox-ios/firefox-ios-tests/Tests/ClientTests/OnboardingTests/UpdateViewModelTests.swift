// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client
import XCTest
import Shared
import Common

class UpdateViewModelTests: XCTestCase {
    private var profile: MockProfile!
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
    }

    override func tearDown() {
        super.tearDown()
        profile = nil
        UserDefaults.standard.removeObject(forKey: PrefsKeys.NimbusUserEnabledFeatureTestsOverride)
    }

    // MARK: Enable cards
    func testEnabledCards_ForHasSyncAccount() {
        profile.hasSyncableAccountMock = true
        let subject = createSubject()
        let expectation = expectation(description: "The hasAccount var has value")

        subject.hasSyncableAccount {
            subject.setupViewControllerDelegates(with: MockOnboardinCardDelegateController(),
                                                 for: self.windowUUID)

            XCTAssertEqual(subject.availableCards.count, 2)
            XCTAssertEqual(subject.availableCards[0].viewModel.name, "Name 1")
            XCTAssertEqual(subject.availableCards[1].viewModel.name, "Name 2")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testEnabledCards_ForSyncAccountDisabled() {
        profile.hasSyncableAccountMock = false
        let subject = createSubject()
        let expectation = expectation(description: "The hasAccount var has value")

        subject.hasSyncableAccount {
            subject.setupViewControllerDelegates(with: MockOnboardinCardDelegateController(),
                                                 for: self.windowUUID)

            XCTAssertEqual(subject.availableCards.count, 2)
            XCTAssertEqual(subject.availableCards[0].viewModel.name, "Name 1")
            XCTAssertEqual(subject.availableCards[1].viewModel.name, "Name 2")
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
            subject.setupViewControllerDelegates(with: MockOnboardinCardDelegateController(),
                                                 for: self.windowUUID)

            XCTAssertEqual(subject.shouldShowSingleCard, false)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testHasSingleCard_ForSyncAccountDisabled() {
        profile.hasSyncableAccountMock = false
        let subject = createSubject()
        subject.setupViewControllerDelegates(with: MockOnboardinCardDelegateController(),
                                             for: self.windowUUID)

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

        let shouldShow = subject.shouldShowUpdateSheet(appVersion: currentTestAppVersion)
        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.AppVersion.Latest), currentTestAppVersion)
        XCTAssertFalse(shouldShow)
    }

    func testShouldNotShowCoverSheetForSameVersion() {
        let subject = createSubject()
        let currentTestAppVersion = "22.0"
        UserDefaults.standard.set(true, forKey: PrefsKeys.NimbusUserEnabledFeatureTestsOverride)

        // Setting clean install to false
        profile.prefs.setString(currentTestAppVersion, forKey: PrefsKeys.AppVersion.Latest)
        let shouldShow = subject.shouldShowUpdateSheet(appVersion: currentTestAppVersion)
        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.AppVersion.Latest), currentTestAppVersion)
        XCTAssertFalse(shouldShow)
    }

    func testShouldNotShowCoverSheet_ForMinorVersionUpgrade() {
        let subject = createSubject()

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

        let currentTestAppVersion = "22.0"

        let shouldShow = subject.shouldShowUpdateSheet(appVersion: currentTestAppVersion)
        XCTAssertFalse(shouldShow)
    }

    func testShouldSaveVersion_CleanInstall() {
        let subject = createSubject()

        let currentTestAppVersion = "22.0"

        profile.prefs.setString(currentTestAppVersion, forKey: PrefsKeys.AppVersion.Latest)
        _ = subject.shouldShowUpdateSheet(appVersion: currentTestAppVersion)
        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.AppVersion.Latest), currentTestAppVersion)
    }

    func testShouldSaveVersion_UnsavedVersion() {
        let subject = createSubject()

        let currentTestAppVersion = "22.0"

        _ = subject.shouldShowUpdateSheet(appVersion: currentTestAppVersion)
        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.AppVersion.Latest), currentTestAppVersion)
    }

    // MARK: - Private Helpers
    func createSubject(
        hasOnboardingCards: Bool = true,
        file: StaticString = #file,
        line: UInt = #line
    ) -> UpdateViewModel {
        let onboardingModel = createOnboardingViewModel(withCards: hasOnboardingCards)
        let telemetryUtility = OnboardingTelemetryUtility(with: onboardingModel)
        let subject = UpdateViewModel(profile: profile,
                                      model: onboardingModel,
                                      telemetryUtility: telemetryUtility,
                                      windowUUID: .XCTestDefaultUUID)

        trackForMemoryLeaks(subject, file: file, line: line)

        return subject
    }

    func createOnboardingViewModel(withCards: Bool) -> OnboardingViewModel {
        let cards: [OnboardingCardInfoModel] = [
            createCard(index: 1),
            createCard(index: 2)
        ]

        return OnboardingViewModel(cards: withCards ? cards : [],
                                   isDismissable: true)
    }

    func createCard(index: Int) -> OnboardingCardInfoModel {
        let buttons = OnboardingButtons(primary: OnboardingButtonInfoModel(title: "Button title \(index)",
                                                                           action: .forwardOneCard))
        return OnboardingCardInfoModel(
            cardType: .basic,
            name: "Name \(index)",
            order: index,
            title: "Title \(index)",
            body: "Body \(index)",
            link: nil,
            buttons: buttons,
            multipleChoiceButtons: [],
            onboardingType: .upgrade,
            a11yIdRoot: "A11y id \(index)",
            imageID: "Image id \(index)",
            instructionsPopup: nil)
    }
}
