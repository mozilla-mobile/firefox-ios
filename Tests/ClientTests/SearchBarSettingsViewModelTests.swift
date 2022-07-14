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
        let spyNotificationCenter = SpyNotificationCenter()
        let viewModel = createViewModel(notificationCenter: spyNotificationCenter)
        let searchBarPosition = viewModel.searchBarPosition

        XCTAssertEqual(searchBarPosition, .bottom)
        XCTAssertNil(spyNotificationCenter.notificationNameSent)
        XCTAssertNil(spyNotificationCenter.notificationObjectSent)
    }

    func testNotificationSent_onBottomSetting() {
        let spyNotificationCenter = SpyNotificationCenter()
        let viewModel = createViewModel(notificationCenter: spyNotificationCenter)
        setDefault(defaultPosition: .top)
        viewModel.bottomSetting.onChecked()

        XCTAssertNotNil(spyNotificationCenter.notificationNameSent)
        XCTAssertNotNil(spyNotificationCenter.notificationObjectSent)
    }

    func testNotificationSent_onTopSetting() {
        let spyNotificationCenter = SpyNotificationCenter()
        let viewModel = createViewModel(notificationCenter: spyNotificationCenter)
        setDefault(defaultPosition: .bottom)
        viewModel.topSetting.onChecked()

        XCTAssertNotNil(spyNotificationCenter.notificationNameSent)
        XCTAssertNotNil(spyNotificationCenter.notificationObjectSent)
    }

    func testNotificationSent_topIsReceived() {
        let spyNotificationCenter = SpyNotificationCenter()
        let viewModel = createViewModel(notificationCenter: spyNotificationCenter)
        setDefault(defaultPosition: .bottom)
        viewModel.topSetting.onChecked()

        verifyNotification(name: spyNotificationCenter.notificationNameSent,
                           object: spyNotificationCenter.notificationObjectSent,
                           expectedPosition: .top)
    }

    func testNotificationSent_bottomIsReceived() {
        let spyNotificationCenter = SpyNotificationCenter()
        let viewModel = createViewModel(notificationCenter: spyNotificationCenter)
        setDefault(defaultPosition: .top)
        viewModel.bottomSetting.onChecked()

        verifyNotification(name: spyNotificationCenter.notificationNameSent,
                           object: spyNotificationCenter.notificationObjectSent,
                           expectedPosition: .bottom)
    }
}

// MARK: - Helper methods
private extension SearchBarSettingsViewModelTests {

    func createViewModel(notificationCenter: NotificationCenter = NotificationCenter.default,
                         file: StaticString = #file,
                         line: UInt = #line) -> SearchBarSettingsViewModel {
        let viewModel = SearchBarSettingsViewModel(prefs: profile.prefs, notificationCenter: notificationCenter)
        FeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        trackForMemoryLeaks(viewModel, file: file, line: line)
        return viewModel
    }

    func setDefault(defaultPosition: SearchBarPosition) {
        profile.prefs.setString(defaultPosition.rawValue,
                                forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
    }

    func verifyNotification(name: NSNotification.Name?,
                            object: Any?,
                            expectedPosition: SearchBarPosition,
                            file: StaticString = #filePath,
                            line: UInt = #line) {

        guard let name = name,
              let dict = object as? NSDictionary,
              let newSearchBarPosition = dict[PrefsKeys.FeatureFlags.SearchBarPosition] as? SearchBarPosition
        else {
            XCTFail("Notification have name and SearchBarPosition object", file: file, line: line)
            return
        }

        XCTAssertEqual(name, Notification.Name.SearchBarPositionDidChange, file: file, line: line)
        XCTAssertEqual(newSearchBarPosition, expectedPosition, file: file, line: line)
    }
}

// MARK: - SearchBarPreferenceDelegateMock
private class SearchBarPreferenceDelegateMock: SearchBarPreferenceDelegate {

    var completion: () -> Void

    init(completion: @escaping () -> Void) {
        self.completion = completion
    }

    func didUpdateSearchBarPositionPreference() {
        completion()
    }
}

// MARK: - SpyNotificationCenter
class SpyNotificationCenter: NotificationCenter {

    var notificationNameSent: NSNotification.Name?
    var notificationObjectSent: Any?
    override func post(name aName: NSNotification.Name, object anObject: Any?) {
        super.post(name: aName, object: anObject)
        notificationNameSent = aName
        notificationObjectSent = anObject
    }
}
