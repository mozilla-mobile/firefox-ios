// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import XCTest
import Shared

@testable import Client

class SearchBarSettingsViewModelTests: XCTestCase {

    private let expectationWaitTime: TimeInterval = 1

    // MARK: Default

    func testDefaultSearchPosition_freshInstall() {
        InstallType.set(type: .fresh)
        let viewModel = createViewModel()
        XCTAssertEqual(viewModel.searchBarPosition, .bottom)
    }

    func testDefaultSearchPosition_upgrade() {
        InstallType.set(type: .upgrade)
        let viewModel = createViewModel()
        XCTAssertEqual(viewModel.searchBarPosition, .top)
    }

    func testDefaultSearchPosition_unknown() {
        InstallType.set(type: .unknown)
        let viewModel = createViewModel()
        XCTAssertEqual(viewModel.searchBarPosition, .top)
    }

    // MARK: Saved

    func testSavedSearchPosition_onTopSavesOnTop() {
        let viewModel = createViewModel()
        callSetting(viewModel.topSetting)

        XCTAssertEqual(viewModel.searchBarPosition, .top)
    }

    func testSavedSearchPosition_onBottomSavesOnBottom() {
        let viewModel = createViewModel()
        callSetting(viewModel.bottomSetting)

        XCTAssertEqual(viewModel.searchBarPosition, .bottom)
    }

    // MARK: Checkmark

    func testSavedSearchPosition_onTopSettingHasCheckmark() {
        let viewModel = createViewModel()
        callSetting(viewModel.topSetting)

        XCTAssertEqual(viewModel.topSetting.isChecked(), true)
        XCTAssertEqual(viewModel.bottomSetting.isChecked(), false)
    }

    func testSavedSearchPosition_onBottomSettingHasCheckmark() {
        let viewModel = createViewModel()
        callSetting(viewModel.bottomSetting)

        XCTAssertEqual(viewModel.bottomSetting.isChecked(), true)
        XCTAssertEqual(viewModel.topSetting.isChecked(), false)
    }

    // MARK: Delegate

    private var delegate: SearchBarPreferenceDelegateMock?
    func testSavedSearchPosition_onBottomSettingCallsDelegate() {
        let expectation = expectation(description: "Delegate is called")
        let viewModel = createViewModel()
        callSetting(viewModel.topSetting)

        delegate = SearchBarPreferenceDelegateMock(completion: {
            expectation.fulfill()
            XCTAssertEqual(viewModel.bottomSetting.isChecked(), true)
        })
        viewModel.delegate = delegate
        callSetting(viewModel.bottomSetting)

        waitForExpectations(timeout: expectationWaitTime, handler: nil)
    }

    func testSavedSearchPosition_onTopSettingCallsDelegate() {
        let expectation = expectation(description: "Delegate is called")
        let viewModel = createViewModel()
        callSetting(viewModel.bottomSetting)
        
        delegate = SearchBarPreferenceDelegateMock(completion: {
            expectation.fulfill()
            XCTAssertEqual(viewModel.topSetting.isChecked(), true)
        })
        viewModel.delegate = delegate
        callSetting(viewModel.topSetting)

        waitForExpectations(timeout: expectationWaitTime, handler: nil)
    }

    // MARK: Notification

    func testNoNotificationSent_withoutDefaultPref() {
        InstallType.set(type: .fresh)
        let expectation = expectation(forNotification: .SearchBarPositionDidChange, object: nil, handler: nil)
        expectation.isInverted = true

        let viewModel = createViewModel()
        let searchBarPosition = viewModel.searchBarPosition

        XCTAssertEqual(searchBarPosition, .bottom)
        waitForExpectations(timeout: expectationWaitTime, handler: nil)
    }

    func testNotificationSent_onBottomSetting() {
        expectation(forNotification: .SearchBarPositionDidChange, object: nil, handler: nil)
        let (viewModel, prefs) = createViewModelWithPrefs()
        setDefault(prefs, defaultPosition: .top)
        callSetting(viewModel.bottomSetting)

        waitForExpectations(timeout: expectationWaitTime, handler: nil)
    }

    func testNotificationSent_onTopSetting() {
        expectation(forNotification: .SearchBarPositionDidChange, object: nil, handler: nil)
        let (viewModel, prefs) = createViewModelWithPrefs()
        setDefault(prefs, defaultPosition: .bottom)
        callSetting(viewModel.topSetting)

        waitForExpectations(timeout: expectationWaitTime, handler: nil)
    }

    func testNotificationSent_topIsReceived() {
        expectation(forNotification: .SearchBarPositionDidChange, object: nil, handler: { notification in
            self.verifyNotification(expectedPosition: .top, notification: notification)
        })
        let (viewModel, prefs) = createViewModelWithPrefs()
        setDefault(prefs, defaultPosition: .bottom)
        callSetting(viewModel.topSetting)

        waitForExpectations(timeout: expectationWaitTime, handler: nil)
    }

    func testNotificationSent_bottomIsReceived() {
        expectation(forNotification: .SearchBarPositionDidChange, object: nil, handler: { notification in
            self.verifyNotification(expectedPosition: .bottom, notification: notification)
        })
        let (viewModel, prefs) = createViewModelWithPrefs()
        setDefault(prefs, defaultPosition: .top)
        callSetting(viewModel.bottomSetting)

        waitForExpectations(timeout: expectationWaitTime, handler: nil)
    }
}

// MARK: Helper methods
private extension SearchBarSettingsViewModelTests {

    func createViewModel() -> SearchBarSettingsViewModel {
        return createViewModelWithPrefs().0
    }

    func createViewModelWithPrefs() -> (SearchBarSettingsViewModel, Prefs) {
        let mockPrefs = MockProfile().prefs
        mockPrefs.clearAll()
        let viewModel = SearchBarSettingsViewModel(prefs: mockPrefs)

        return (viewModel, mockPrefs)
    }

    func callSetting(_ setting: CheckmarkSetting) {
        let dummyNavController = UINavigationController()
        setting.onClick(dummyNavController)
    }

    func setDefault(_ prefs: Prefs, defaultPosition: SearchBarPosition) {
        prefs.setString(defaultPosition.rawValue, forKey: PrefsKeys.KeySearchBarPosition)
    }

    func verifyNotification(expectedPosition: SearchBarPosition,
                            notification: Notification,
                            file: StaticString = #filePath,
                            line: UInt = #line) -> Bool {

        guard let dict = notification.object as? NSDictionary,
              let newSearchBarPosition = dict[PrefsKeys.KeySearchBarPosition] as? SearchBarPosition
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
