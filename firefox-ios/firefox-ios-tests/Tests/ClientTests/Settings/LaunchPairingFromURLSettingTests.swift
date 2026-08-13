// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
import Shared
import Common
import enum MozillaAppServices.OAuthScope

@MainActor
class LaunchPairingFromURLSettingTests: XCTestCase {
    let windowUUID: WindowUUID = .XCTestDefaultUUID
    private var settingsTable: SettingsTableViewController!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        settingsTable = SettingsTableViewController(style: .grouped, windowUUID: windowUUID)
        settingsTable.profile = MockProfile()
    }

    override func tearDown() async throws {
        UIPasteboard.general.string = ""
        settingsTable = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testAccessibilityIdentifier() {
        XCTAssertEqual(createSubject().accessibilityIdentifier, "LaunchPairingFromURL.Setting")
    }

    func testTitleIsNilWithoutTheme() {
        XCTAssertNil(createSubject().title)
    }

    func testTitleUsesThemeTextColor() {
        let subject = createSubject()
        let theme = DefaultThemeManager(
            sharedContainerIdentifier: AppInfo.sharedContainerIdentifier
        ).getCurrentTheme(for: windowUUID)
        subject.theme = theme

        XCTAssertEqual(subject.title?.string, "Launch pairing from URL")
        let color = subject.title?.attributes(at: 0, effectiveRange: nil)[.foregroundColor] as? UIColor
        XCTAssertEqual(color, theme.colors.textPrimary)
    }

    func testOnClickPresentsAlert() {
        let navigationController = UINavigationController(rootViewController: settingsTable)
        createSubject().onClick(navigationController)
    }

    func testLaunchPairingWithBlankURLDoesNothing() {
        let navigationController = UINavigationController(rootViewController: settingsTable)
        createSubject().launchPairing(urlString: "   ", navigationController: navigationController)
    }

    func testPrefilledPairingURLReturnsPairingURLFromPasteboard() {
        let url = "https://accounts.firefox.com/pair#channel_id=abc&channel_key=def"
        UIPasteboard.general.string = url
        XCTAssertEqual(LaunchPairingFromURLSetting.prefilledPairingURL(), url)
    }

    func testPrefilledPairingURLIgnoresNonPairingPasteboard() {
        UIPasteboard.general.string = "https://example.com"
        XCTAssertNil(LaunchPairingFromURLSetting.prefilledPairingURL())
    }

    func testLaunchPairingCallsAuthenticatorWithTrimmedURLAndScopes() {
        let authenticator = MockPairingAuthenticator()
        let subject = createSubject()
        subject.pairingAuthenticatorProvider = { authenticator }

        subject.launchPairing(urlString: "  https://accounts.firefox.com/pair#c=1  ",
                              navigationController: UINavigationController())

        XCTAssertEqual(authenticator.beginCallCount, 1)
        XCTAssertEqual(authenticator.capturedPairingUrl, "https://accounts.firefox.com/pair#c=1")
        XCTAssertEqual(authenticator.capturedEntrypoint, "pairing_debug")
        XCTAssertEqual(
            authenticator.capturedScopes,
            [OAuthScope.profile, OAuthScope.oldSync, OAuthScope.session, OAuthScope.relay]
        )
    }

    func testLaunchPairingWithoutAuthenticatorDoesNothing() {
        let subject = createSubject()
        subject.pairingAuthenticatorProvider = { nil }

        subject.launchPairing(urlString: "https://accounts.firefox.com/pair#c=1",
                              navigationController: UINavigationController())
    }

    private func createSubject() -> LaunchPairingFromURLSetting {
        return LaunchPairingFromURLSetting(settings: settingsTable)
    }
}

private class MockPairingAuthenticator: PairingAuthenticating {
    var beginCallCount = 0
    var capturedPairingUrl: String?
    var capturedEntrypoint: String?
    var capturedScopes: [String]?

    func beginPairingAuthentication(
        pairingUrl: String,
        entrypoint: String,
        scopes: [String],
        completionHandler: @Sendable @MainActor @escaping (Result<URL, Error>) -> Void
    ) {
        beginCallCount += 1
        capturedPairingUrl = pairingUrl
        capturedEntrypoint = entrypoint
        capturedScopes = scopes
        // Drive the failure branch so the completion runs without building the
        // web view controller (which is not unit-testable). Safe: the test calls
        // this synchronously on the main actor.
        MainActor.assumeIsolated {
            completionHandler(.failure(NSError(domain: "test", code: 0)))
        }
    }
}
