// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import XCTest

@testable import Client

@MainActor
final class BackgroundAudioHelperTests: XCTestCase {
    private var mockNotificationCenter: MockNotificationCenter!
    private var prefs: MockProfilePrefs!

    override func setUp() async throws {
        try await super.setUp()
        mockNotificationCenter = MockNotificationCenter()
        prefs = MockProfilePrefs()
    }

    override func tearDown() async throws {
        mockNotificationCenter = nil
        prefs = nil
        try await super.tearDown()
    }

    func testIsEnabled_defaultsToFalse() {
        let subject = createSubject()
        _ = subject

        XCTAssertFalse(BackgroundAudioHelper.isEnabled(prefs))
    }

    func testIsEnabled_returnsTrueWhenPrefSet() {
        let subject = createSubject()
        _ = subject
        prefs.setBool(true, forKey: PrefsKeys.BackgroundAudio)

        XCTAssertTrue(BackgroundAudioHelper.isEnabled(prefs))
    }

    func testIsEnabled_returnsFalseWhenPrefSetToFalse() {
        let subject = createSubject()
        _ = subject
        prefs.setBool(false, forKey: PrefsKeys.BackgroundAudio)

        XCTAssertFalse(BackgroundAudioHelper.isEnabled(prefs))
    }

    func testConfigure_whenDisabled_doesNotObserve() {
        let subject = createSubject()

        subject.configure(prefs: prefs)

        XCTAssertEqual(mockNotificationCenter.addObserverCallCount, 0)
    }

    func testConfigure_whenEnabled_startsObserving() {
        prefs.setBool(true, forKey: PrefsKeys.BackgroundAudio)
        let subject = createSubject()

        subject.configure(prefs: prefs)

        XCTAssertEqual(mockNotificationCenter.addObserverCallCount, 2)
        XCTAssertTrue(mockNotificationCenter.observers.contains(UIApplication.willResignActiveNotification))
        XCTAssertTrue(mockNotificationCenter.observers.contains(UIApplication.didEnterBackgroundNotification))
    }

    func testToggle_enableSetsPrefsAndStartsObserving() {
        let subject = createSubject()

        subject.toggle(isEnabled: true, prefs: prefs)

        XCTAssertTrue(prefs.boolForKey(PrefsKeys.BackgroundAudio) ?? false)
        XCTAssertEqual(mockNotificationCenter.addObserverCallCount, 2)
    }

    func testToggle_disableSetsPrefsAndStopsObserving() {
        let subject = createSubject()
        subject.toggle(isEnabled: true, prefs: prefs)

        subject.toggle(isEnabled: false, prefs: prefs)

        XCTAssertFalse(prefs.boolForKey(PrefsKeys.BackgroundAudio) ?? true)
    }

    func testStartObserving_registersForCorrectNotifications() {
        let subject = createSubject()

        subject.startObserving()

        XCTAssertEqual(mockNotificationCenter.addObserverCallCount, 2)
        XCTAssertTrue(mockNotificationCenter.observers.contains(UIApplication.willResignActiveNotification))
        XCTAssertTrue(mockNotificationCenter.observers.contains(UIApplication.didEnterBackgroundNotification))
    }

    func testStartObserving_calledTwice_doesNotDoubleRegister() {
        let subject = createSubject()

        subject.startObserving()
        subject.startObserving()

        XCTAssertEqual(mockNotificationCenter.addObserverCallCount, 2)
    }

    func testStopObserving_whenNotObserving_doesNothing() {
        let subject = createSubject()

        subject.stopObserving()

        XCTAssertEqual(mockNotificationCenter.removeObserverCallCount, 0)
    }

    private func createSubject() -> BackgroundAudioHelper {
        let subject = BackgroundAudioHelper(notificationCenter: mockNotificationCenter)
        trackForMemoryLeaks(subject)
        return subject
    }
}
