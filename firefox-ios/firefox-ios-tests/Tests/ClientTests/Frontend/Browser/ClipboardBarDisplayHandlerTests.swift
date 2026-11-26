// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import Shared
@testable import Client

@MainActor
@available(iOS 16.0, *)
final class ClipboardBarDisplayHandlerTests: XCTestCase {
    private var prefs: MockProfilePrefs!
    private var pasteboard: MockClipboardPasteboard!
    private var delegate: MockClipboardBarDisplayHandlerDelegate!

    override func setUp() async throws {
        try await super.setUp()
        AppEventQueue.reset()
        prefs = MockProfilePrefs()
        prefs.setBool(true, forKey: PrefsKeys.ShowClipboardBar)
        prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
        pasteboard = MockClipboardPasteboard(hasURLs: true, changeCount: 1)
        delegate = MockClipboardBarDisplayHandlerDelegate()
    }

    override func tearDown() async throws {
        prefs = nil
        pasteboard = nil
        delegate = nil
        AppEventQueue.reset()
        try await super.tearDown()
    }

    func testWillEnterForeground_withURLOnPasteboard_asksDelegateToDisplay() {
        let subject = createSubject()
        AppEventQueue.signal(event: .startupFlowComplete)
        AppEventQueue.signal(event: .tabRestoration(windowUUID))
        let expectation = XCTestExpectation(description: "Delegate asked to display")
        delegate.onShouldDisplay = { expectation.fulfill() }

        subject.handleNotifications(Notification(name: UIApplication.willEnterForegroundNotification))

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(delegate.shouldDisplayCallCount, 1)
    }

    func testWillEnterForeground_withoutURLOnPasteboard_doesNotAskDelegateToDisplay() {
        pasteboard = MockClipboardPasteboard(hasURLs: false, changeCount: 1)
        let subject = createSubject()
        AppEventQueue.signal(event: .startupFlowComplete)
        AppEventQueue.signal(event: .tabRestoration(windowUUID))

        subject.handleNotifications(Notification(name: UIApplication.willEnterForegroundNotification))

        let expectation = XCTestExpectation(description: "Main queue drained")
        DispatchQueue.main.async { expectation.fulfill() }
        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(delegate.shouldDisplayCallCount, 0)
    }

    private let windowUUID = WindowUUID.XCTestDefaultUUID

    private func createSubject() -> DefaultClipboardBarDisplayHandler {
        let subject = DefaultClipboardBarDisplayHandler(
            prefs: prefs,
            windowUUID: windowUUID,
            pasteboard: pasteboard
        )
        subject.delegate = delegate
        return subject
    }
}

private final class MockClipboardPasteboard: ClipboardPasteboard {
    let hasURLs: Bool
    let changeCount: Int

    init(hasURLs: Bool, changeCount: Int) {
        self.hasURLs = hasURLs
        self.changeCount = changeCount
    }
}

@available(iOS 16.0, *)
private final class MockClipboardBarDisplayHandlerDelegate: ClipboardBarDisplayHandlerDelegate {
    var shouldDisplayCallCount = 0
    var onShouldDisplay: (() -> Void)?

    func shouldDisplay() {
        shouldDisplayCallCount += 1
        onShouldDisplay?()
    }
}
