// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import XCTest
import Shared

@testable import Client

class SearchBarSettingsViewModelTests: XCTestCase {

    private let expectationWaitTime: TimeInterval = 1

    var profile: MockProfile!

    override func setUp() {
        super.setUp()
        profile = MockProfile(databasePrefix: "SearchBarSettingsTests_")
        profile.prefs.clearAll()
    }

    override func tearDown() {
        super.tearDown()
        profile.prefs.clearAll()
        profile = nil
    }

    // MARK: Default
    func testDefaultSearchPosition() {
        let viewModel = createViewModel()
        XCTAssertEqual(viewModel.searchBarPosition, .bottom)
    }

    // MARK: Saved

    func testSavedSearchPosition_onTopSavesOnTop() {
        let viewModel = createViewModel()
        viewModel.topSetting.onChecked()

        XCTAssertEqual(viewModel.searchBarPosition, .top)
    }

    func testSavedSearchPosition_onBottomSavesOnBottom() {
        let viewModel = createViewModel()
        viewModel.bottomSetting.onChecked()

        XCTAssertEqual(viewModel.searchBarPosition, .bottom)
    }

    // MARK: Checkmark

    func testSavedSearchPosition_onTopSettingHasCheckmark() {
        let viewModel = createViewModel()
        viewModel.topSetting.onChecked()

        XCTAssertEqual(viewModel.topSetting.isChecked(), true)
        XCTAssertEqual(viewModel.bottomSetting.isChecked(), false)
    }

    func testSavedSearchPosition_onBottomSettingHasCheckmark() {
        let viewModel = createViewModel()
        viewModel.bottomSetting.onChecked()

        XCTAssertEqual(viewModel.bottomSetting.isChecked(), true)
        XCTAssertEqual(viewModel.topSetting.isChecked(), false)
    }

    // MARK: Delegate

    func testSavedSearchPosition_onBottomSettingCallsDelegate() {
        let expectation = expectation(description: "Delegate is called")
        let viewModel = createViewModel()
        viewModel.topSetting.onChecked()

        let delegate = SearchBarPreferenceDelegateMock(completion: {
            XCTAssertEqual(viewModel.bottomSetting.isChecked(), true)
            expectation.fulfill()
        })
        viewModel.delegate = delegate
        viewModel.bottomSetting.onChecked()

        waitForExpectations(timeout: expectationWaitTime, handler: nil)
    }

    func testSavedSearchPosition_onTopSettingCallsDelegate() {
        let expectation = expectation(description: "Delegate is called")
        let viewModel = createViewModel()
        viewModel.bottomSetting.onChecked()

        let delegate = SearchBarPreferenceDelegateMock(completion: {
            XCTAssertEqual(viewModel.topSetting.isChecked(), true)
            expectation.fulfill()
        })
        viewModel.delegate = delegate
        viewModel.topSetting.onChecked()

        waitForExpectations(timeout: expectationWaitTime, handler: nil)
    }

    // MARK: Notification

    func testNoNotificationSent_withoutDefaultPref() {
        let expectation = expectation(forNotification: .SearchBarPositionDidChange, object: nil, handler: nil)
        expectation.isInverted = true

        let viewModel = createViewModel()
        let searchBarPosition = viewModel.searchBarPosition

        XCTAssertEqual(searchBarPosition, .bottom)
        waitForExpectations(timeout: expectationWaitTime, handler: nil)
    }

    func testNotificationSent_onBottomSetting() {
        expectation(forNotification: .SearchBarPositionDidChange, object: nil, handler: nil)
        let viewModel = createViewModel()
        setDefault(defaultPosition: .top)
        viewModel.bottomSetting.onChecked()

        waitForExpectations(timeout: expectationWaitTime, handler: nil)
    }

    func testNotificationSent_onTopSetting() {
        expectation(forNotification: .SearchBarPositionDidChange, object: nil, handler: nil)
        let viewModel = createViewModel()
        setDefault(defaultPosition: .bottom)
        viewModel.topSetting.onChecked()

        waitForExpectations(timeout: expectationWaitTime, handler: nil)
    }

    func testNotificationSent_topIsReceived() {
        expectation(forNotification: .SearchBarPositionDidChange,
                    object: nil) { notification in
            self.verifyNotification(expectedPosition: .top, notification: notification)
        }

        let viewModel = createViewModel()
        setDefault(defaultPosition: .bottom)
        viewModel.topSetting.onChecked()

        waitForExpectations(timeout: expectationWaitTime, handler: nil)
    }

    func testNotificationSent_bottomIsReceived() {
        expectation(forNotification: .SearchBarPositionDidChange,
                    object: nil) { notification in
            self.verifyNotification(expectedPosition: .bottom,
                                    notification: notification)
        }

        let viewModel = createViewModel()
        setDefault(defaultPosition: .top)
        viewModel.bottomSetting.onChecked()

        waitForExpectations(timeout: expectationWaitTime, handler: nil)
    }
}

// MARK: Helper methods
private extension SearchBarSettingsViewModelTests {

    func createViewModel(file: StaticString = #file, line: UInt = #line) -> SearchBarSettingsViewModel {
        let viewModel = SearchBarSettingsViewModel(prefs: profile.prefs)
        FeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        trackForMemoryLeaks(viewModel, file: file, line: line)
        return viewModel
    }

    func setDefault(defaultPosition: SearchBarPosition) {
        profile.prefs.setString(defaultPosition.rawValue,
                                forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
    }

    func verifyNotification(expectedPosition: SearchBarPosition,
                            notification: Notification,
                            file: StaticString = #filePath,
                            line: UInt = #line) -> Bool {

        guard let dict = notification.object as? NSDictionary,
              let newSearchBarPosition = dict[PrefsKeys.FeatureFlags.SearchBarPosition] as? SearchBarPosition
        else {
            XCTFail("Notification should be \(expectedPosition), instead of \(notification.debugDescription)", file: file, line: line)
            return false
        }

        XCTAssertEqual(newSearchBarPosition, expectedPosition, file: file, line: line)
        return true
    }
}

private class SearchBarPreferenceDelegateMock: SearchBarPreferenceDelegate {

    var completion: () -> Void

    init(completion: @escaping () -> Void) {
        self.completion = completion
    }

    func didUpdateSearchBarPositionPreference() {
        completion()
    }
}
