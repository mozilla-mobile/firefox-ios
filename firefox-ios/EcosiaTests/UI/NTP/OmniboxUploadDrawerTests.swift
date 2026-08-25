// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import SwiftUI
import Common
import SnowplowTracker
@testable import Client
@testable import Ecosia

@MainActor
final class OmniboxUploadDrawerTests: XCTestCase {

    func testUploadOptionsExposeAllCases() {
        XCTAssertEqual(OmniboxUploadOption.allCases.count, 3)
        XCTAssertEqual(Set(OmniboxUploadOption.allCases), Set([.photos, .camera, .files]))
    }

    func testUploadOptionAccessibilityMetadata() {
        XCTAssertEqual(OmniboxUploadOption.photos.accessibilityLabel, String.localized(.photos))
        XCTAssertEqual(OmniboxUploadOption.photos.accessibilityHint, String.localized(.uploadPhotosAccessibilityHint))
        XCTAssertEqual(OmniboxUploadOption.photos.accessibilityIdentifier, "OmniboxUploadPhotosOption")

        XCTAssertEqual(OmniboxUploadOption.camera.accessibilityLabel, String.localized(.camera))
        XCTAssertEqual(OmniboxUploadOption.camera.accessibilityHint, String.localized(.uploadCameraAccessibilityHint))
        XCTAssertEqual(OmniboxUploadOption.camera.accessibilityIdentifier, "OmniboxUploadCameraOption")

        XCTAssertEqual(OmniboxUploadOption.files.accessibilityLabel, String.localized(.files))
        XCTAssertEqual(OmniboxUploadOption.files.accessibilityHint, String.localized(.uploadFilesAccessibilityHint))
        XCTAssertEqual(OmniboxUploadOption.files.accessibilityIdentifier, "OmniboxUploadFilesOption")
    }

    @available(iOS 16.0, *)
    func testLightThemeDrawerAndIconTilesHaveDistinctBackgrounds() {
        var theme = OmniboxUploadDrawerViewTheme()
        let lightTheme = EcosiaLightTheme()
        theme.applyTheme(theme: lightTheme)

        XCTAssertEqual(theme.backgroundColor, Color(lightTheme.colors.ecosia.backgroundPrimaryDecorative))
        XCTAssertEqual(theme.iconBackgroundColor, Color(lightTheme.colors.ecosia.backgroundElevation1))
        XCTAssertNotEqual(theme.backgroundColor, theme.iconBackgroundColor)
    }

    func testUploadDrawerIconsLoadFromFrameworkBundle() {
        XCTAssertNotNil(UIImage.ecosia(named: "upload-photos"))
        XCTAssertNotNil(UIImage.ecosia(named: "upload-camera"))
        XCTAssertNotNil(UIImage.ecosia(named: "upload-files"))
    }

    func testUploadOptionsRenderInDesignOrder() {
        XCTAssertEqual(OmniboxUploadOption.allCases, [.photos, .camera, .files])
    }

    func testChatModesExposeAllCases() {
        XCTAssertEqual(OmniboxChatMode.allCases.count, 4)
        XCTAssertEqual(OmniboxChatMode.allCases, [.standard, .thinkLonger, .displaySources, .learning])
    }

    func testChatModeAccessibilityMetadata() {
        XCTAssertEqual(OmniboxChatMode.standard.accessibilityLabel, String.localized(.chatModeStandard))
        XCTAssertEqual(OmniboxChatMode.standard.accessibilityIdentifier, "OmniboxChatModeStandardOption")
        XCTAssertEqual(OmniboxChatMode.thinkLonger.accessibilityIdentifier, "OmniboxChatModeThinkLongerOption")
        XCTAssertEqual(OmniboxChatMode.displaySources.accessibilityIdentifier, "OmniboxChatModeDisplaySourcesOption")
        XCTAssertEqual(OmniboxChatMode.learning.accessibilityIdentifier, "OmniboxChatModeLearningOption")
    }

    func testChatModeIconsLoadFromFrameworkBundle() {
        XCTAssertNotNil(UIImage.ecosia(named: "chatmodes-standard-ai-chat"))
        XCTAssertNotNil(UIImage.ecosia(named: "chatmodes-think-longer"))
        XCTAssertNotNil(UIImage.ecosia(named: "chatmodes-display-sources"))
        XCTAssertNotNil(UIImage.ecosia(named: "chatmodes-learning"))
    }

    func testChatModeAIChatQueryItemsMapToBackendFlags() {
        XCTAssertTrue(OmniboxChatMode.standard.aiChatQueryItems.isEmpty)
        XCTAssertEqual(OmniboxChatMode.thinkLonger.aiChatQueryItems,
                       [URLQueryItem(name: "t", value: "1")])
        XCTAssertEqual(OmniboxChatMode.displaySources.aiChatQueryItems,
                       [URLQueryItem(name: "m", value: "2")])
        XCTAssertEqual(OmniboxChatMode.learning.aiChatQueryItems,
                       [URLQueryItem(name: "m", value: "1")])
    }

    func testAIChatURLCarriesChatModeQueryItems() {
        let provider = URLProvider.production

        let standardURL = provider.aiChat(origin: .omnibox,
                                          query: "hello",
                                          additionalQueryItems: OmniboxChatMode.standard.aiChatQueryItems)
        let standardItems = URLComponents(url: standardURL, resolvingAgainstBaseURL: false)?.queryItems ?? []
        XCTAssertTrue(standardURL.path.hasSuffix("/ai-chat"))
        XCTAssertFalse(standardItems.contains { $0.name == "t" || $0.name == "m" })

        let learningURL = provider.aiChat(origin: .omnibox,
                                          query: "hello",
                                          additionalQueryItems: OmniboxChatMode.learning.aiChatQueryItems)
        let learningItems = URLComponents(url: learningURL, resolvingAgainstBaseURL: false)?.queryItems ?? []
        XCTAssertTrue(learningItems.contains(URLQueryItem(name: "m", value: "1")))
        XCTAssertTrue(learningItems.contains(URLQueryItem(name: "q", value: "hello")))
    }

    func testAIChatURLCarriesChatModeQueryItemsAndFiles() throws {
        let provider = URLProvider.production
        let files = [
            AIChatFileQuery(
                fileId: "file-1",
                filename: "doc.pdf",
                mimeType: "application/pdf",
                sizeBytes: 1024
            )
        ]

        let url = provider.aiChat(origin: .omnibox,
                                  query: "summarize this",
                                  files: files,
                                  additionalQueryItems: OmniboxChatMode.learning.aiChatQueryItems)
        let items = Dictionary(
            uniqueKeysWithValues: (URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? [])
                .map { ($0.name, $0.value) }
        )

        XCTAssertEqual(items["q"], "summarize this")
        XCTAssertEqual(items["m"], "1")
        XCTAssertNotNil(items["files"])
    }
}

@MainActor
final class NTPOmniboxSheetStateTests: XCTestCase {

    private func present(_ state: NTPOmniboxSheetState,
                         isAuthenticated: Bool = true,
                         onSelectUpload: @escaping (OmniboxUploadOption) -> Void = { _ in },
                         onChatModeSelectionChanged: @escaping (OmniboxChatMode?) -> Void = { _ in },
                         onLogin: @escaping () -> Void = {}) {
        state.presentUploadDrawer(isAuthenticated: isAuthenticated,
                                  onSelectUpload: onSelectUpload,
                                  onChatModeSelectionChanged: onChatModeSelectionChanged,
                                  onLogin: onLogin)
    }

    func testSelectedOptionIsDeliveredAfterDrawerDismisses() {
        let state = NTPOmniboxSheetState()
        var received: OmniboxUploadOption?
        present(state, onSelectUpload: { received = $0 })

        state.handleUploadOptionSelected(.files)
        XCTAssertFalse(state.showUploadDrawer)
        XCTAssertNil(received)

        state.handleUploadDrawerDismissed()
        XCTAssertEqual(received, .files)
    }

    func testSelectedChatModeAppliesImmediatelyOnTap() {
        let state = NTPOmniboxSheetState()
        var changes: [OmniboxChatMode?] = []
        var receivedUpload: OmniboxUploadOption?
        present(
            state,
            onSelectUpload: { receivedUpload = $0 },
            onChatModeSelectionChanged: { changes.append($0) }
        )

        state.handleChatModeSelected(.thinkLonger)
        // Delivered on tap — not deferred until the sheet dismisses.
        XCTAssertEqual(state.selectedChatMode, .thinkLonger)
        XCTAssertEqual(changes, [.thinkLonger])
        XCTAssertFalse(state.showUploadDrawer)
        XCTAssertNil(receivedUpload)
    }

    func testSelectingChatModeReplacesThePreviousOne() {
        let state = NTPOmniboxSheetState()
        present(state)

        state.handleChatModeSelected(.thinkLonger)
        state.handleChatModeSelected(.learning)
        XCTAssertEqual(state.selectedChatMode, .learning)
    }

    func testReTappingActiveChatModeInDrawerKeepsItSelected() {
        // Deselection happens via the omnibox chip, not the drawer — re-picking
        // the active mode just closes the drawer with the mode still active. The
        // re-tap is a no-op: it does NOT re-notify the selection callback, since
        // nothing about the selection changed.
        let state = NTPOmniboxSheetState()
        var changes: [OmniboxChatMode?] = []
        present(state, onChatModeSelectionChanged: { changes.append($0) })

        state.handleChatModeSelected(.learning)
        state.handleChatModeSelected(.learning)
        XCTAssertEqual(state.selectedChatMode, .learning)
        XCTAssertEqual(changes, [.learning])
    }

    func testReTappingActiveChatModeDoesNotTrackASecondSelection() {
        let previousAnalytics = Analytics.shared
        let previousUsageData = User.shared.sendAnonymousUsageData
        let spy = AnalyticsSpy()
        Analytics.shared = spy
        User.shared.sendAnonymousUsageData = true
        defer {
            Analytics.shared = previousAnalytics
            User.shared.sendAnonymousUsageData = previousUsageData
        }

        let state = NTPOmniboxSheetState()
        present(state)

        // First pick reports one `select`; re-tapping the same mode is a no-op
        // and must not emit another event.
        state.handleChatModeSelected(.learning)
        state.handleChatModeSelected(.learning)

        let modeSelections = spy.trackedEvents
            .compactMap { $0 as? Structured }
            .filter { $0.label == Analytics.Label.modeSelection.rawValue }
        XCTAssertEqual(modeSelections.count, 1)
        XCTAssertEqual(modeSelections.first?.property,
                       #"{"action":"select","logged_in":true,"mode":"learning"}"#)
    }

    func testDismissWithoutSelectionDoesNotDeliverOption() {
        let state = NTPOmniboxSheetState()
        var received: OmniboxUploadOption?
        present(state, onSelectUpload: { received = $0 })

        state.handleUploadDrawerDismissed()
        XCTAssertNil(received)
        XCTAssertNil(state.selectedChatMode)
    }

    func testPresentPublishesAuthenticationState() {
        let state = NTPOmniboxSheetState()
        present(state, isAuthenticated: false)
        XCTAssertFalse(state.isAuthenticated)

        present(state, isAuthenticated: true)
        XCTAssertTrue(state.isAuthenticated)
    }

    func testLoginRequestIsDeliveredAfterDrawerDismisses() {
        let state = NTPOmniboxSheetState()
        var didLogin = false
        present(state, isAuthenticated: false, onLogin: { didLogin = true })

        state.handleLoginRequested()
        // Deferred until the sheet dismisses so the auth flow doesn't fight it.
        XCTAssertFalse(state.showUploadDrawer)
        XCTAssertFalse(didLogin)

        state.handleUploadDrawerDismissed()
        XCTAssertTrue(didLogin)
    }

    func testUploadSelectionTakesPrecedenceOverPendingLogin() {
        let state = NTPOmniboxSheetState()
        var didLogin = false
        var received: OmniboxUploadOption?
        present(state, onSelectUpload: { received = $0 }, onLogin: { didLogin = true })

        state.handleUploadOptionSelected(.files)
        state.handleUploadDrawerDismissed()
        XCTAssertEqual(received, .files)
        XCTAssertFalse(didLogin)
    }

    func testSignInSheetDismissalStartsSignInAfterSheetCloses() {
        let state = NTPOmniboxSheetState()
        var didSignIn = false
        var didOpenDrawer = false

        state.presentSignInSheetForUpload(
            onSignIn: { didSignIn = true },
            onSignUp: {},
            onUploadDrawerRequested: { didOpenDrawer = true }
        )
        XCTAssertTrue(state.showSignInSheet)

        state.handleSignInSheetSignInTapped()
        XCTAssertFalse(state.showSignInSheet)
        XCTAssertFalse(didSignIn)

        state.handleSignInSheetDismissed()
        XCTAssertTrue(didSignIn)
        XCTAssertFalse(didOpenDrawer)

        state.handleAuthenticationCompleted(success: true)
        XCTAssertTrue(didOpenDrawer)
    }

    func testAuthenticationFailureClearsPendingUploadDrawer() {
        let state = NTPOmniboxSheetState()
        var didOpenDrawer = false

        state.presentSignInSheetForUpload(
            onSignIn: {},
            onSignUp: {},
            onUploadDrawerRequested: { didOpenDrawer = true }
        )
        state.handleSignInSheetSignInTapped()
        state.handleSignInSheetDismissed()

        state.handleAuthenticationCompleted(success: false)
        state.handleAuthenticationCompleted(success: true)
        XCTAssertFalse(didOpenDrawer)
    }

    func testSignInSheetDismissWithoutActionClearsPendingUpload() {
        let state = NTPOmniboxSheetState()
        var didOpenDrawer = false

        state.presentSignInSheetForUpload(
            onSignIn: {},
            onSignUp: {},
            onUploadDrawerRequested: { didOpenDrawer = true }
        )

        state.showSignInSheet = false
        state.handleSignInSheetDismissed()

        state.handleAuthenticationCompleted(success: true)
        XCTAssertFalse(didOpenDrawer)
    }

    func testSignInSheetDismissalStartsSignUpAfterSheetCloses() {
        let state = NTPOmniboxSheetState()
        var didSignUp = false
        var didOpenDrawer = false

        state.presentSignInSheetForUpload(
            onSignIn: {},
            onSignUp: { didSignUp = true },
            onUploadDrawerRequested: { didOpenDrawer = true }
        )

        state.handleSignInSheetCreateAccountTapped()
        XCTAssertFalse(state.showSignInSheet)
        XCTAssertFalse(didSignUp)

        state.handleSignInSheetDismissed()
        XCTAssertTrue(didSignUp)
        XCTAssertFalse(didOpenDrawer)

        state.handleAuthenticationCompleted(success: true)
        XCTAssertTrue(didOpenDrawer)
    }
}

@MainActor
final class NTPSearchBarUploadDelegateTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Self.enableFileUploadFlag(true)
    }

    override func tearDown() {
        Unleash.clearInstanceModel()
        super.tearDown()
    }

    private static func enableFileUploadFlag(_ enabled: Bool) {
        let toggle = Unleash.Toggle(
            name: Unleash.Toggle.Name.fileUpload.rawValue,
            enabled: enabled,
            variant: Unleash.Variant(name: "", enabled: false, payload: nil)
        )
        Unleash.model = Unleash.Model(toggles: Set([toggle]))
    }

    private final class UploadDelegateSpy: NTPSearchBarDelegate {
        var didTapUpload = false

        func ntpSearchBarDidSubmit(_ searchTerm: String) {}
        func ntpSearchBarTextDidChange(_ searchTerm: String) {}
        func ntpSearchBarNeedsSearchReset() {}
        func ntpSearchBarDidBeginEditing() {}
        func ntpSearchBarDidCancel() {}
        func ntpSearchBarRequestsOverlayDismiss() {}
        func ntpSearchBarDidTapUpload() {
            didTapUpload = true
        }
    }

    func testUploadButtonTapNotifiesDelegate() throws {
        let bar = NTPSearchBarView(frame: CGRect(x: 0, y: 0, width: 320, height: 110))
        let spy = UploadDelegateSpy()
        bar.delegate = spy

        let uploadButton = bar.subviews.compactMap { $0 as? EcosiaOmniboxUploadButton }.first
        let button = try XCTUnwrap(uploadButton)
        button.sendActions(for: .touchUpInside)

        XCTAssertTrue(spy.didTapUpload)
    }

    func testUploadButtonHiddenWhenFileUploadFlagDisabled() throws {
        Self.enableFileUploadFlag(false)
        let bar = NTPSearchBarView(frame: CGRect(x: 0, y: 0, width: 320, height: 110))

        let uploadButton = bar.subviews.compactMap { $0 as? EcosiaOmniboxUploadButton }.first
        let button = try XCTUnwrap(uploadButton)
        XCTAssertTrue(button.isHidden)
    }
}
