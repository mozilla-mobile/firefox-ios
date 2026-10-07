// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

@testable import Client

@MainActor
final class AdBlockerExceptionsSettingTests: XCTestCase {
    private var mockStorage: MockAdBlockerExceptionsStorage!
    private var mockDelegate: MockBrowsingSettingsDelegate!

    override func setUp() async throws {
        try await super.setUp()
        mockStorage = MockAdBlockerExceptionsStorage()
        mockDelegate = MockBrowsingSettingsDelegate()
    }

    override func tearDown() async throws {
        mockStorage = nil
        mockDelegate = nil
        try await super.tearDown()
    }

    func testTitle_matchesExceptionsString() {
        let subject = createSubject()

        XCTAssertEqual(subject.title?.string, String.Settings.Browsing.Exceptions.Title)
    }

    func testAccessibilityIdentifier_isCorrect() {
        let subject = createSubject()

        XCTAssertEqual(
            subject.accessibilityIdentifier,
            AccessibilityIdentifiers.Settings.Browsing.AdBlockerExceptions.settingRow
        )
    }

    func testStatus_showsCount() {
        mockStorage.stubbedDomains = ["a.com", "b.com"]
        let subject = createSubject()

        XCTAssertEqual(subject.status?.string, "2")
    }

    func testStatus_showsZeroWhenEmpty() {
        mockStorage.stubbedDomains = []
        let subject = createSubject()

        XCTAssertEqual(subject.status?.string, "0")
    }

    func testOnClick_callsDelegate() {
        let subject = createSubject()

        subject.onClick(nil)

        XCTAssertTrue(mockDelegate.pressedAdBlockerExceptionsCalled)
    }

    func testStyle_isValue1() {
        let subject = createSubject()

        XCTAssertEqual(subject.style, .value1)
    }

    // MARK: - Helpers

    private func createSubject() -> AdBlockerExceptionsSetting {
        let theme = LightTheme()
        let subject = AdBlockerExceptionsSetting(
            theme: theme,
            settingsDelegate: mockDelegate,
            exceptionsStorage: mockStorage
        )
        trackForMemoryLeaks(subject)
        return subject
    }
}

private final class MockBrowsingSettingsDelegate: BrowsingSettingsDelegate {
    var pressedAdBlockerExceptionsCalled = false

    func pressedMailApp() {}
    func pressedAutoPlay() {}

    func pressedAdBlockerExceptions() {
        pressedAdBlockerExceptionsCalled = true
    }

    func pressedRegionalAdBlockLists() {}
}

@MainActor
private final class MockAdBlockerExceptionsStorage: AdBlockerExceptionsStorageProtocol {
    var stubbedDomains: [String] = []

    var domains: [String] { stubbedDomains }
    var count: Int { stubbedDomains.count }

    func addDomain(_ domain: String) {
        stubbedDomains.append(domain)
    }

    func removeDomain(_ domain: String) {
        stubbedDomains.removeAll { $0 == domain }
    }

    func removeDomains(_ domains: Set<String>) {
        stubbedDomains.removeAll { domains.contains($0) }
    }

    func removeAllDomains() {
        stubbedDomains.removeAll()
    }

    func containsDomain(_ domain: String) -> Bool {
        return stubbedDomains.contains(domain)
    }
}
