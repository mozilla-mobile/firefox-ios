// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Common
import Sentry

final class CrashManagerTests: XCTestCase {
    private var sentryWrapper: MockSentryWrapper!

    override func setUp() {
        super.setUp()
        sentryWrapper = MockSentryWrapper()
    }

    override func tearDown() {
        super.tearDown()
        sentryWrapper = nil
        setupAppInformation(buildChannel: .other)
    }

    // MARK: - Setup

    func testSetup_isSimulator_notSetup() {
        sentryWrapper.dsn = "12345"
        let subject = DefaultCrashManager(sentryWrapper: sentryWrapper,
                                          isSimulator: true,
                                          skipReleaseNameCheck: true)
        subject.setup(sendUsageData: true)

        XCTAssertEqual(sentryWrapper.startWithConfigureOptionsCalled, 0)
        XCTAssertEqual(sentryWrapper.configureScopeCalled, 0)
    }

    func testSetup_sendNoUsageData_notSetup() {
        sentryWrapper.dsn = "12345"
        let subject = DefaultCrashManager(sentryWrapper: sentryWrapper,
                                          isSimulator: false,
                                          skipReleaseNameCheck: true)
        subject.setup(sendUsageData: false)

        XCTAssertEqual(sentryWrapper.startWithConfigureOptionsCalled, 0)
        XCTAssertEqual(sentryWrapper.configureScopeCalled, 0)
    }

    func testSetup_noDSN_notSetup() {
        let subject = DefaultCrashManager(sentryWrapper: sentryWrapper,
                                          isSimulator: false,
                                          skipReleaseNameCheck: true)
        subject.setup(sendUsageData: true)

        XCTAssertEqual(sentryWrapper.startWithConfigureOptionsCalled, 0)
        XCTAssertEqual(sentryWrapper.configureScopeCalled, 0)
    }

    func testSetup_isSetup() {
        sentryWrapper.dsn = "12345"
        let subject = DefaultCrashManager(sentryWrapper: sentryWrapper,
                                          isSimulator: false,
                                          skipReleaseNameCheck: true)
        subject.setup(sendUsageData: true)

        XCTAssertEqual(sentryWrapper.startWithConfigureOptionsCalled, 1)
        XCTAssertEqual(sentryWrapper.configureScopeCalled, 1)
    }

    func testSetup_isSetupTwice_notCalledTwice() {
        sentryWrapper.dsn = "12345"
        let subject = DefaultCrashManager(sentryWrapper: sentryWrapper,
                                          isSimulator: false,
                                          skipReleaseNameCheck: true)
        subject.setup(sendUsageData: true)
        subject.setup(sendUsageData: true)

        XCTAssertEqual(sentryWrapper.startWithConfigureOptionsCalled, 1)
        XCTAssertEqual(sentryWrapper.configureScopeCalled, 1)
    }

    // MARK: - crashedLastLaunch

    func testCrashedLastLaunch_false() {
        let subject = DefaultCrashManager(sentryWrapper: sentryWrapper,
                                          isSimulator: false,
                                          skipReleaseNameCheck: true)
        XCTAssertFalse(subject.crashedLastLaunch)
    }

    func testCrashedLastLaunch_true() {
        sentryWrapper.mockCrashedInLastRun = true
        let subject = DefaultCrashManager(sentryWrapper: sentryWrapper,
                                          isSimulator: false,
                                          skipReleaseNameCheck: true)
        XCTAssertTrue(subject.crashedLastLaunch)
    }

    // MARK: - Send message

    func testSendMessage_notEnabled_doesNothing() {
        let subject = DefaultCrashManager(sentryWrapper: sentryWrapper,
                                          isSimulator: false,
                                          skipReleaseNameCheck: true)
        subject.send(message: "A message",
                     category: .setup,
                     level: .debug,
                     extraEvents: nil)

        XCTAssertNil(sentryWrapper.savedMessage)
        XCTAssertNil(sentryWrapper.savedBreadcrumb)
    }

    func testSendMessageFatal_enabledDebug_sendBreadcrumb() {
        sentryWrapper.dsn = "12345"
        let subject = DefaultCrashManager(sentryWrapper: sentryWrapper,
                                          isSimulator: false,
                                          skipReleaseNameCheck: true)
        subject.setup(sendUsageData: true)

        subject.send(message: "A message",
                     category: .setup,
                     level: .fatal,
                     extraEvents: nil)

        XCTAssertNil(sentryWrapper.savedMessage)
        XCTAssertNotNil(sentryWrapper.savedBreadcrumb)
        XCTAssertEqual(sentryWrapper.savedBreadcrumb?.message, "A message")
    }

    func testSendMessageFatal_enabledBeta_sendMessage() {
        sentryWrapper.dsn = "12345"
        setupAppInformation(buildChannel: .beta)
        let subject = DefaultCrashManager(sentryWrapper: sentryWrapper,
                                          isSimulator: false,
                                          skipReleaseNameCheck: true)
        subject.setup(sendUsageData: true)

        subject.send(message: "A message",
                     category: .setup,
                     level: .fatal,
                     extraEvents: nil)

        XCTAssertNotNil(sentryWrapper.savedMessage)
        XCTAssertEqual(sentryWrapper.savedMessage, "A message")
        XCTAssertNil(sentryWrapper.savedBreadcrumb)
    }

    func testSendMessageInfo_enabledBeta_sendBreadcrumb() {
        sentryWrapper.dsn = "12345"
        setupAppInformation(buildChannel: .beta)
        let subject = DefaultCrashManager(sentryWrapper: sentryWrapper,
                                          isSimulator: false,
                                          skipReleaseNameCheck: true)
        subject.setup(sendUsageData: true)

        subject.send(message: "A message",
                     category: .setup,
                     level: .info,
                     extraEvents: nil)

        XCTAssertNil(sentryWrapper.savedMessage)
        XCTAssertNotNil(sentryWrapper.savedBreadcrumb)
        XCTAssertEqual(sentryWrapper.savedBreadcrumb?.message, "A message")
    }

    func testSendMessageFatal_enabledRelease_sendMessage() {
        sentryWrapper.dsn = "12345"
        setupAppInformation(buildChannel: .release)
        let subject = DefaultCrashManager(sentryWrapper: sentryWrapper,
                                          isSimulator: false,
                                          skipReleaseNameCheck: true)
        subject.setup(sendUsageData: true)

        subject.send(message: "A message",
                     category: .setup,
                     level: .fatal,
                     extraEvents: nil)

        XCTAssertNotNil(sentryWrapper.savedMessage)
        XCTAssertEqual(sentryWrapper.savedMessage, "A message")
        XCTAssertNil(sentryWrapper.savedBreadcrumb)
    }

    func testSendMessageInfo_enabledRelease_sendBreadcrumb() {
        sentryWrapper.dsn = "12345"
        setupAppInformation(buildChannel: .release)
        let subject = DefaultCrashManager(sentryWrapper: sentryWrapper,
                                          isSimulator: false,
                                          skipReleaseNameCheck: true)
        subject.setup(sendUsageData: true)

        subject.send(message: "A message",
                     category: .setup,
                     level: .info,
                     extraEvents: nil)

        XCTAssertNil(sentryWrapper.savedMessage)
        XCTAssertNotNil(sentryWrapper.savedBreadcrumb)
        XCTAssertEqual(sentryWrapper.savedBreadcrumb?.message, "A message")
    }
}

// MARK: - Helpers
extension CrashManagerTests {
    private func setupAppInformation(buildChannel: AppBuildChannel) {
        BrowserKitInformation.shared.configure(buildChannel: buildChannel,
                                               nightlyAppVersion: "",
                                               sharedContainerIdentifier: "")
    }
}

// MARK: - MockSentryWrapper
private class MockSentryWrapper: SentryWrapper {
    var mockCrashedInLastRun = false
    var crashedInLastRun: Bool {
        return mockCrashedInLastRun
    }

    var dsn: String?

    var startWithConfigureOptionsCalled = 0
    func startWithConfigureOptions(configure options: @escaping (Options) -> Void) {
        startWithConfigureOptionsCalled += 1
    }

    var savedMessage: String?
    func captureMessage(message: String, with scopeBlock: @escaping (Scope) -> Void) {
        savedMessage = message
    }

    var savedError: Error?
    func captureError(error: Error) {
        savedError = error
    }

    var savedBreadcrumb: Breadcrumb?
    func addBreadcrumb(crumb: Breadcrumb) {
        savedBreadcrumb = crumb
    }

    var configureScopeCalled = 0
    func configureScope(scope: @escaping (Scope) -> Void) {
        configureScopeCalled += 1
    }
}
