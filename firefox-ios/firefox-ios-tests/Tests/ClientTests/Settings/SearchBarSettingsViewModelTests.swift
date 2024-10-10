// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import XCTest
import Shared

@testable import Client

class SearchBarSettingsViewModelTests: XCTestCase {
    var prefs: Prefs!
    var mockNotificationCenter: MockNotificationCenter!

    override func setUp() {
        super.setUp()
        let profile = MockProfile(databasePrefix: "SearchBarSettingsTests")
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        prefs = profile.prefs
        prefs.clearAll()
        mockNotificationCenter = MockNotificationCenter()
    }

    override func tearDown() {
        prefs.clearAll()
        prefs = nil
        mockNotificationCenter = nil
        super.tearDown()
    }

    // MARK: Default
    func testDefaultSearchPosition() {
        let viewModel = createViewModel()
        XCTAssertEqual(viewModel.searchBarPosition, .top)
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
        let viewModel = createViewModel()
        viewModel.topSetting.onChecked()

        let delegate = SearchBarPreferenceDelegateMock {
            XCTAssertEqual(viewModel.bottomSetting.isChecked(), true)
        }
        viewModel.delegate = delegate
        viewModel.bottomSetting.onChecked()
    }

    func testSavedSearchPosition_onTopSettingCallsDelegate() {
        let viewModel = createViewModel()
        viewModel.bottomSetting.onChecked()

        let delegate = SearchBarPreferenceDelegateMock {
            XCTAssertEqual(viewModel.topSetting.isChecked(), true)
        }
        viewModel.delegate = delegate
        viewModel.topSetting.onChecked()
    }

    // MARK: Notification

    func testNoNotificationSent_withoutDefaultPref() {
        let viewModel = createViewModel()
        let searchBarPosition = viewModel.searchBarPosition

        XCTAssertEqual(searchBarPosition, .top)
        XCTAssertEqual(mockNotificationCenter.postCallCount, 0)
    }

    func testNotificationSent_onBottomSetting() {
        setDefault(defaultPosition: .top)
        let viewModel = createViewModel()
        viewModel.bottomSetting.onChecked()

        XCTAssertEqual(mockNotificationCenter.postCallCount, 1)
    }

    func testNotificationSent_onTopSetting() {
        setDefault(defaultPosition: .bottom)
        let viewModel = createViewModel()
        viewModel.topSetting.onChecked()

        XCTAssertEqual(mockNotificationCenter.postCallCount, 1)
    }

    func testNotificationSent_topIsReceived() {
        setDefault(defaultPosition: .bottom)
        let viewModel = createViewModel()
        viewModel.topSetting.onChecked()

        verifyNotification(name: mockNotificationCenter.savePostName,
                           object: mockNotificationCenter.savePostObject,
                           expectedPosition: .top)
    }

    func testNotificationSent_bottomIsReceived() {
        setDefault(defaultPosition: .top)
        let viewModel = createViewModel()
        viewModel.bottomSetting.onChecked()

        verifyNotification(name: mockNotificationCenter.savePostName,
                           object: mockNotificationCenter.savePostObject,
                           expectedPosition: .bottom)
    }
}

// MARK: - Helper methods
private extension SearchBarSettingsViewModelTests {
    func createViewModel(file: StaticString = #file,
                         line: UInt = #line) -> SearchBarSettingsViewModel {
        let viewModel = SearchBarSettingsViewModel(prefs: prefs, notificationCenter: mockNotificationCenter)
        trackForMemoryLeaks(viewModel, file: file, line: line)
        return viewModel
    }

    func setDefault(defaultPosition: SearchBarPosition) {
        prefs.setString(defaultPosition.rawValue,
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
