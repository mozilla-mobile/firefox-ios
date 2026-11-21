// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

import Common
@testable import Client

@MainActor
final class LibraryViewControllerTests: XCTestCase {
    private let windowUUID: WindowUUID = .XCTestDefaultUUID
    private var profile: MockProfile!
    private var notificationCenter: MockNotificationCenter!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = makeProfile()
        notificationCenter = MockNotificationCenter()
    }

    override func tearDown() async throws {
        profile = nil
        notificationCenter = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testTitle_whenHistoryIsOpened_showsHistory() {
        let subject = createSubject()

        subject.setupOpenPanel(panelType: .history)

        XCTAssertEqual(subject.navigationItem.title, LibraryPanelType.history.title)
    }

    func testTitle_whenRecentlyClosedIsPushed_showsRecentlyClosed() {
        let subject = createSubject()
        subject.setupOpenPanel(panelType: .history)

        pushRecentlyClosed(on: subject)

        XCTAssertEqual(subject.navigationItem.title, String.RecentlyClosedTabsPanelTitle)
    }

    func testTitle_whenRecentlyClosedIsPopped_showsHistoryAgain() {
        let subject = createSubject()
        subject.setupOpenPanel(panelType: .history)
        pushRecentlyClosed(on: subject)

        historyStack(of: subject).popViewController(animated: false)
        subject.handleNotifications(Notification(name: .LibraryPanelStateDidChange))

        XCTAssertEqual(subject.navigationItem.title, LibraryPanelType.history.title)
    }

    func testTitle_whenSwitchingPanelsWhileRecentlyClosedIsShown_keepsRecentlyClosed() {
        let subject = createSubject()
        subject.setupOpenPanel(panelType: .history)
        pushRecentlyClosed(on: subject)

        subject.setupOpenPanel(panelType: .downloads)
        subject.setupOpenPanel(panelType: .history)

        XCTAssertEqual(subject.navigationItem.title, String.RecentlyClosedTabsPanelTitle)
    }

    // MARK: - Helpers

    private func pushRecentlyClosed(on subject: LibraryViewController) {
        let panel = RecentlyClosedTabsPanel(profile: profile, windowUUID: windowUUID)
        historyStack(of: subject).pushViewController(panel, animated: false)
        // The history panel posts this once the coordinator has pushed Recently Closed
        subject.handleNotifications(Notification(name: .LibraryPanelStateDidChange))
    }

    private func historyStack(of subject: LibraryViewController) -> UINavigationController {
        return subject.childPanelControllers[LibraryPanelType.history.rawValue]
    }

    private func createSubject() -> LibraryViewController {
        let subject = LibraryViewController(profile: profile,
                                            tabManager: MockTabManager(),
                                            notificationCenter: notificationCenter)
        subject.childPanelControllers = [
            UINavigationController(rootViewController: UIViewController()),
            UINavigationController(rootViewController: HistoryPanel(profile: profile, windowUUID: windowUUID)),
            UINavigationController(rootViewController: DownloadsPanel(windowUUID: windowUUID)),
            UINavigationController(rootViewController: UIViewController())
        ]
        subject.loadViewIfNeeded()
        trackForMemoryLeaks(subject)
        return subject
    }
}
