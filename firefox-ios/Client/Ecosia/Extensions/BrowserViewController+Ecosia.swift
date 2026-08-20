// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SwiftUI
import Shared
import Ecosia

// MARK: HomepageViewControllerDelegate
@MainActor
extension BrowserViewController: HomepageViewControllerDelegate {
    func homeDidTapSearchButton(_ home: HomepageViewController) {
        // Ecosia: urlBar renamed to addressToolbarContainer; use enterOverlayMode to focus search
        addressToolbarContainer.enterOverlayMode(nil, pasted: false, search: true)
    }
}

// MARK: DefaultBrowserDelegate
@MainActor
extension BrowserViewController: DefaultBrowserDelegate {
    @available(iOS 14, *)
    func defaultBrowserDidShow(_ defaultBrowser: DefaultBrowserViewController) {
        User.shared.markDefaultBrowserSearchPromoAsShown()
    }
}

// MARK: - NTP omnibox session
extension BrowserViewController {

    /// Shows the embedded webview for a tab captured before async work (e.g. attachment submit).
    func showEmbeddedWebview(for tab: Tab) {
        if tabManager.selectedTab !== tab {
            tabManager.selectTab(tab)
        }
        showEmbeddedWebview()
    }

    /// The homepage VC while the webview is frontmost (swiping-tabs keeps it as a child).
    fileprivate var ecosiaEmbeddedHomepage: HomepageViewController? {
        if let homepage = contentContainer.contentController as? HomepageViewController {
            return homepage
        }
        return children.first { $0 is HomepageViewController } as? HomepageViewController
    }

    /// See `HomepageViewController.resetNTPOmniboxSession()`.
    func ecosiaPrepareNTPOmniboxForDisplay() {
        guard let homepage = ecosiaEmbeddedHomepage,
              homepage.ntpSearchBar?.isFirstResponder == false else { return }
        homepage.resetNTPOmniboxSession()
    }

    /// See `HomepageViewController.resetNTPOmniboxSession()`.
    func ecosiaResetNTPOmniboxWhenLeavingNTP() {
        ecosiaEmbeddedHomepage?.resetNTPOmniboxSession()
    }
}

// MARK: - Default browser promo after search threshold
extension BrowserViewController {

    /// Pure eligibility check, isolated from UIKit for unit-testing.
    static func isEligibleForEcosiaDefaultBrowserSearchPromo(
        searchCount: Int,
        isDefaultBrowser: Bool,
        promoAlreadyShown: Bool
    ) -> Bool {
        guard !isDefaultBrowser else { return false }
        guard searchCount > DefaultBrowserViewController.minSearchCountToTrigger else { return false }
        guard !promoAlreadyShown else { return false }
        return true
    }

    /// Presents the default-browser promo once the search-count threshold is crossed.
    /// Safe to call repeatedly — the User flag prevents double-presentation.
    func ecosiaMaybePresentDefaultBrowserPromoForSearchThreshold() {
        guard #available(iOS 14, *) else { return }

        guard Self.isEligibleForEcosiaDefaultBrowserSearchPromo(
            searchCount: User.shared.searchCount,
            isDefaultBrowser: DefaultBrowserUtility().isDefaultBrowser,
            promoAlreadyShown: User.shared.defaultBrowserSearchPromoShown
        ) else { return }

        guard presentedViewController == nil else { return }
        guard viewIfLoaded?.window != nil else { return }

        let controller = DefaultBrowserViewController(windowUUID: windowUUID, delegate: self)
        present(controller, animated: true, completion: nil)
    }
}

// MARK: WhatsNewViewDelegate
@MainActor
extension BrowserViewController: WhatsNewViewDelegate {
    func whatsNewViewDidShow(_ viewController: WhatsNewViewController) {
        // Ecosia: whatsNewDataProvider removed in Firefox refactor; use WhatsNewLocalDataProvider to mark as seen
        WhatsNewLocalDataProvider().markPreviousVersionsAsSeen()
    }
}

// MARK: PageActionsShortcutsDelegate
@MainActor
extension BrowserViewController: PageActionsShortcutsDelegate {
    func pageOptionsOpenHome() {
        // Ecosia: tabToolbarDidPressHome/toolbar removed; focus search (home equivalent)
        addressToolbarContainer.enterOverlayMode(nil, pasted: false, search: true)
        dismiss(animated: true)
        Analytics.shared.menuClick(.home)
    }

    func pageOptionsNewTab() {
        openBlankNewTab(focusLocationField: false)
        dismiss(animated: true)
        Analytics.shared.menuClick(.newTab)
    }

    func pageOptionsSettings() {
        // Ecosia: homePanelDidRequestToOpenSettings removed; use navigationHandler.show(settings:)
        navigationHandler?.show(settings: .general)
        dismiss(animated: true)
        Analytics.shared.menuClick(.settings)
    }

    func pageOptionsShare() {
        dismiss(animated: true) {
            // Ecosia: menuHelper not in scope; use navigationHandler to show share sheet if needed
            self.navigationHandler?.showMainMenu()
        }
    }
}

// MARK: URL Bar
@MainActor
extension BrowserViewController {

    func updateURLBarFollowingPrivateModeUI() {
        let isPrivate = tabManager.selectedTab?.isPrivate ?? false
        addressToolbarContainer.applyUIMode(isPrivate: isPrivate, theme: themeManager.getCurrentTheme(for: windowUUID))
    }

    /// Pushes text appended from a suggestion's "append" arrow into the address bar.
    ///
    /// The Redux round-trip cannot do this. Ecosia's reducer deliberately preserves
    /// `didStartTyping` on `didSetTextInLocationView` (upstream clears it) so a suggestion
    /// highlight can't overwrite the field mid-keystroke — and
    /// `LocationView.configureURLTextField` bails on that same flag before writing the text
    /// field. By the time the append arrow is reachable the user has necessarily typed, so
    /// the flag is always set and the appended query never lands, leaving the address bar
    /// out of sync with the suggestions list (which `appendSearch` updates directly).
    ///
    /// Clearing the flag instead is not an option: with the keyboard drag-dismissed it is
    /// the only thing stopping `LocationView` from resigning first responder (MOB-4580),
    /// which would tear the overlay down. So write the field directly — the same guard that
    /// blocks the state update also stops a later reconfigure from clobbering this.
    func applyAppendedSearchTermToAddressBar(_ text: String) {
        // The NTP omnibox owns the overlay in that mode and `setLocationView` already
        // wrote the pill directly.
        guard !(searchController?.parent is HomepageViewController) else { return }

        addressToolbarContainer.setOverlayLocationText(text)
    }
}

// MARK: Present intro
@MainActor
extension BrowserViewController {

    func presentIntroViewController(_ alwaysShow: Bool = false) {
        if showLoadingScreen(for: .shared) {
            presentLoadingScreen()
        } else if User.shared.firstTime {
            handleFirstTimeUserActions()
        }
    }

    private func presentLoadingScreen() {
        guard let referrals = referrals else { return }
        present(LoadingScreen(profile: profile, referrals: referrals, windowUUID: windowUUID, referralCode: User.shared.referrals.pendingClaim), animated: true)
    }

    private func handleFirstTimeUserActions() {
        User.shared.firstTime = false
        User.shared.migrated = true
        User.shared.hideBookmarksImportExportTooltip()
    }

    private func showLoadingScreen(for user: User) -> Bool {
        user.referrals.pendingClaim != nil
    }
}

// MARK: Claim Referral
@MainActor
extension BrowserViewController {

    func openBlankNewTabAndClaimReferral(code: String) {
        User.shared.referrals.pendingClaim = code

        // on first start, browser is not in view hierarchy yet
        guard !User.shared.firstTime else { return }
        navigationHandler?.popToBVC()
        openURLInNewTab(nil, isPrivate: false)
        // Intro logic will trigger claiming referral
        presentIntroViewController()
    }
}

// MARK: Ecosia URL Detection and Handling
@MainActor
extension BrowserViewController {
    /// Detects Ecosia-specific URLs (auth, profile, etc.) and triggers native flows.
    /// - Returns: `true` if the URL was handled and navigation should be cancelled, `false` otherwise
    func detectAndHandleEcosiaURL(_ url: URL, for tab: Tab) -> Bool {
        guard !tab.isInvisible else { return false }

        let interceptor = EcosiaURLInterceptor()
        let interceptedType = interceptor.interceptedType(for: url)

        switch interceptedType {
        case .signUp, .signIn:
            return handleSignInAndSignUpDetection(url, tab: tab, interceptedType: interceptedType)
        case .signOut:
            return handleSignOutDetection(url)
        case .profile:
            return handleProfilePageDetection(url)
        case .none:
            return false
        }
    }

    private func handleSignInAndSignUpDetection(
        _ url: URL,
        tab: Tab,
        interceptedType: EcosiaInterceptedURLType
    ) -> Bool {
        guard let ecosiaAuth = ecosiaAuth else {
            EcosiaLogger.auth.notice("No EcosiaAuth instance available for authentication detection")
            return false
        }

        if !ecosiaAuth.isLoggedIn {
            EcosiaLogger.auth.info("🔐 [WEB-AUTH] Auth URL detected in navigation: \(url)")
            EcosiaLogger.auth.info("🔐 [WEB-AUTH] Triggering native authentication flow")

            let configuredAuth = ecosiaAuth
                .onNativeAuthCompleted {
                    EcosiaLogger.auth.info("🔐 [WEB-AUTH] Native authentication completed from navigation detection")
                }
                .onAuthFlowCompleted { [weak self] success in
                    if success {
                        EcosiaLogger.auth.info("🔐 [WEB-AUTH] Complete authentication flow successful from navigation")
                        // Ecosia: Task { @MainActor in } instead of DispatchQueue.main.async for strict concurrency
                        Task { @MainActor in
                            self?.tabManager.selectedTab?.reload()
                            EcosiaLogger.auth.info("🔐 [WEB-AUTH] Page refreshed after successful sign-in")
                        }
                    } else {
                        EcosiaLogger.auth.notice("🔐 [WEB-AUTH] Authentication flow completed with issues from navigation")
                    }
                }
                .onError { error in
                    EcosiaLogger.auth.error("🔐 [WEB-AUTH] Authentication failed from navigation: \(error)")
                }

            switch interceptedType {
            case .signUp:
                configuredAuth.signUp()
            case .signIn:
                configuredAuth.login()
            default:
                configuredAuth.login()
            }
        } else {
            EcosiaLogger.auth.sentry("🔐 [WEB-AUTH] Inconsistent state: web says logged out but native doesn't; " +
                                     "forcing logout+re-login to avoid user getting locked")

            ecosiaAuth
                .onAuthFlowCompleted { _ in
                    EcosiaLogger.auth.info("🔐 [WEB-AUTH] Logout completed to resolve inconsistency")
                    ecosiaAuth
                        .onAuthFlowCompleted { [weak self] success in
                            if success {
                                EcosiaLogger.auth.info("🔐 [WEB-AUTH] Re-authentication successful after resolving inconsistency")
                                // Ecosia: Task { @MainActor in } instead of DispatchQueue.main.async for strict concurrency
                                Task { @MainActor in
                                    self?.tabManager.selectedTab?.reload()
                                    EcosiaLogger.auth.info("🔐 [WEB-AUTH] Page refreshed after inconsistency resolution")
                                }
                            } else {
                                EcosiaLogger.auth.error("🔐 [WEB-AUTH] Re-authentication failed after resolving inconsistency")
                            }
                        }
                        .onError { error in
                            EcosiaLogger.auth.error("🔐 [WEB-AUTH] Re-authentication error after resolving inconsistency: \(error)")
                        }
                        .login()
                }
                .onError { error in
                    EcosiaLogger.auth.error("🔐 [WEB-AUTH] Logout failed while resolving inconsistency: \(error)")
                }
                .logout()
        }

        return true
    }

    private func handleSignOutDetection(_ url: URL) -> Bool {
        guard let ecosiaAuth = ecosiaAuth else {
            EcosiaLogger.auth.notice("No EcosiaAuth instance available for sign-out detection")
            return false
        }

        // Always perform logout on web-triggered sign-out to clear inconsistent state
        if !ecosiaAuth.isLoggedIn {
            EcosiaLogger.auth.info("🔐 [WEB-AUTH] User already logged out, but we perform logout anyways to clear inconsistent state for: \(url) as if it's triggered, it means the User sees the page and clicks logout. It may happen sometimes. Noticed especially on iPad.")
        }

        EcosiaLogger.auth.info("🔐 [WEB-AUTH] Sign-out URL detected in navigation: \(url)")
        EcosiaLogger.auth.info("🔐 [WEB-AUTH] Triggering native logout flow")

        ecosiaAuth
            .onNativeAuthCompleted {
                EcosiaLogger.auth.info("🔐 [WEB-AUTH] Native logout completed from navigation detection")
            }
            .onAuthFlowCompleted { [weak self] success in
                if success {
                    EcosiaLogger.auth.info("🔐 [WEB-AUTH] Complete logout flow successful from navigation")
                    // Ecosia: Task { @MainActor in } instead of DispatchQueue.main.async for strict concurrency
                    Task { @MainActor in
                        self?.tabManager.selectedTab?.reload()
                        EcosiaLogger.auth.info("🔐 [WEB-AUTH] Page refreshed after successful sign-out")
                    }
                } else {
                    EcosiaLogger.auth.notice("🔐 [WEB-AUTH] Logout flow completed with issues from navigation")
                }
            }
            .onError { error in
                EcosiaLogger.auth.error("🔐 [WEB-AUTH] Logout failed from navigation: \(error)")
            }
            .logout()

        return true
    }

    private func handleProfilePageDetection(_ url: URL) -> Bool {
        EcosiaLogger.auth.info("🔐 [WEB-PROFILE] Profile URL detected in navigation: \(url)")
        EcosiaLogger.auth.info("🔐 [WEB-PROFILE] Opening native profile modal")
        // Ecosia: Task { @MainActor in } instead of DispatchQueue.main.async for strict concurrency
        Task { @MainActor in
            self.presentProfileModal()
        }
        return true
    }
}

// MARK: Profile Modal Presentation
@MainActor
extension BrowserViewController {
    /// Presents the profile page as a modal, similar to EcosiaAccountImpactView
    func presentProfileModal() {
        guard #available(iOS 16.0, *) else {
            EcosiaLogger.auth.notice("Profile modal requires iOS 16.0+")
            return
        }

        let profileView = EcosiaWebViewModal(
            url: Environment.current.urlProvider.profileURL,
            windowUUID: windowUUID,
            userAgent: EcosiaInAppWebViewUserAgent.mobileUserAgent(),
            onLoadComplete: {
                Analytics.shared.accountProfileViewed()
            },
            onDismiss: {
                Analytics.shared.accountProfileDismissed()
            }
        )

        let hostingController = UIHostingController(rootView: profileView)
        hostingController.modalPresentationStyle = .pageSheet

        if let sheet = hostingController.sheetPresentationController {
            sheet.detents = [UISheetPresentationController.Detent.large()]
            sheet.prefersGrabberVisible = true
        }

        present(hostingController, animated: true) {
            EcosiaLogger.auth.info("🔐 [WEB-PROFILE] Profile modal presented successfully")
        }
    }
}
