// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class RestoreTabManagerTestsTests: XCTestCase {
    private var delegate: MockRestoreTabManagerDelegate!
    private var presenter: MockPresenter!
    private var alertCreator: MockRestoreAlertCreator!
    private var logger: MockLogger!
    private var userDefaults: MockUserDefaults!

    override func setUp() {
        super.setUp()
        delegate = MockRestoreTabManagerDelegate()
        presenter = MockPresenter()
        alertCreator = MockRestoreAlertCreator()
        logger = MockLogger()
        userDefaults = MockUserDefaults()
    }

    override func tearDown() {
        super.tearDown()
        delegate = nil
        presenter = nil
        alertCreator = nil
        logger = nil
        userDefaults = nil
    }

    func testAlertNeedsShowing_didNotCrashedLastLaunch_alertDoesntNeedToShow() {
        logger.crashedLastLaunch = false
        let subject = createSubject(hasTabsToRestoreAtStartup: false)

        XCTAssertFalse(subject.alertNeedsToShow)
    }

    func testAlertNeedsShowing_createdTwice_stillFalse() {
        logger.crashedLastLaunch = false
        _ = createSubject(hasTabsToRestoreAtStartup: false)
        let subject = createSubject(hasTabsToRestoreAtStartup: false)

        XCTAssertFalse(subject.alertNeedsToShow)
    }

    func testAlertNeedsShowing_crashedLastLaunch_alertNeedsToShow() {
        logger.crashedLastLaunch = true
        let subject = createSubject(hasTabsToRestoreAtStartup: false)

        XCTAssertTrue(subject.alertNeedsToShow)
    }

    func testAlertNeedsShowing_resetOnAnotherLaunchWithoutACrash_stillNeedsShowing() {
        logger.crashedLastLaunch = true
        _ = createSubject(hasTabsToRestoreAtStartup: false)

        logger.crashedLastLaunch = false
        let subject = createSubject(hasTabsToRestoreAtStartup: false)

        XCTAssertTrue(subject.alertNeedsToShow)
    }

    func testWithoutTabsToRestore_createAnEmptyTab() {
        logger.crashedLastLaunch = true
        let subject = createSubject(hasTabsToRestoreAtStartup: false)

        subject.showAlert(on: presenter, alertCreator: alertCreator)

        XCTAssertEqual(delegate?.needsNewTabOpenedCalled, 1)
        XCTAssertEqual(delegate?.needsTabRestoreCalled, 0)
        XCTAssertNil(presenter?.savedViewControllerToPresent)
    }

    func testWithTabsToRestore_pressOk_needsTabRestore() throws {
        logger.crashedLastLaunch = true
        let subject = createSubject(hasTabsToRestoreAtStartup: true)

        subject.showAlert(on: presenter, alertCreator: alertCreator)

        alertCreator.savedOkayCallback!()
        XCTAssertEqual(delegate?.needsNewTabOpenedCalled, 0)
        XCTAssertEqual(delegate?.needsTabRestoreCalled, 1)
        XCTAssertFalse(subject.alertNeedsToShow)
        XCTAssertNotNil(presenter?.savedViewControllerToPresent)
    }

    func testWithTabsToRestore_pressNo_needsNewTabOpened() throws {
        logger.crashedLastLaunch = true
        let subject = createSubject(hasTabsToRestoreAtStartup: true)

        subject.showAlert(on: presenter, alertCreator: alertCreator)

        alertCreator.savedNoCallback!()
        XCTAssertEqual(delegate?.needsNewTabOpenedCalled, 1)
        XCTAssertEqual(delegate?.needsTabRestoreCalled, 0)
        XCTAssertFalse(subject.alertNeedsToShow)
        XCTAssertNotNil(presenter?.savedViewControllerToPresent)
    }

    // MARK: Helper methods

    private func createSubject(hasTabsToRestoreAtStartup: Bool,
                               file: StaticString = #file,
                               line: UInt = #line) -> RestoreTabManager {
        let subject = DefaultRestoreTabManager(hasTabsToRestoreAtStartup: hasTabsToRestoreAtStartup,
                                               delegate: delegate,
                                               logger: logger,
                                               userDefaults: userDefaults)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
