// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import Combine

/// ViewModel for the EcosiaAccountImpactView that uses centralized auth state
@available(iOS 16.0, *)
@MainActor
public class EcosiaAccountImpactViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published public var isLoading: Bool = false

    // MARK: - Private Properties
    private let onLoginAction: () -> Void
    private let onDismissAction: () -> Void
    private let authStateProvider: EcosiaAuthUIStateProvider
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    public init(
        onLogin: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.onLoginAction = onLogin
        self.onDismissAction = onDismiss
        self.authStateProvider = EcosiaAuthUIStateProvider.shared

        // Forward objectWillChange notifications from authStateProvider
        // This ensures SwiftUI knows to update the view when auth state changes
        authStateProvider.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    // MARK: - Computed Properties

    /// Current authentication status from centralized provider
    public var isLoggedIn: Bool {
        authStateProvider.isLoggedIn
    }

    /// Current username from centralized provider
    public var username: String? {
        authStateProvider.username
    }

    /// Current avatar URL from centralized provider
    public var avatarURL: URL? {
        authStateProvider.avatarURL
    }

    /// Current seed count from centralized provider
    public var seedCount: Int {
        authStateProvider.seedCount
    }

    // MARK: - Public Methods

    /// Handles the main CTA button tap (login for guests, or custom action for logged-in users)
    public func handleMainCTATap() {
        Analytics.shared.accountImpactSignUpClicked()

        if isLoggedIn {
            // For logged-in users, this could be a different action
            // For now, we'll just dismiss
            handleDismiss()
        } else {
            handleLogin()
        }
    }

    /// Handles the login action
    public func handleLogin() {
        isLoading = true
        onLoginAction()
        // Note: The loading state will be updated when the parent view updates the auth state
    }

    /// Handles dismissing the view
    public func handleDismiss() {
        Analytics.shared.accountImpactCloseClicked()
        onDismissAction()
    }

    /// Handles the "Learn more about seeds" link tap
    public func handleLearnMoreTap() {
        Analytics.shared.accountImpactCardCtaClicked()
    }

    /// Handles the logout action by delegating to Auth.shared
    public func handleLogout() async {
        do {
            try await EcosiaAuthenticationService.shared.logout()
        } catch {
            EcosiaLogger.auth.error("Failed to logout: \(error)")
        }
    }
}

// MARK: - Computed Properties
@available(iOS 16.0, *)
extension EcosiaAccountImpactViewModel {

    /// The text to display for the user section
    public var userDisplayText: String {
        authStateProvider.userDisplayText
    }

    /// The text for the main CTA button
    public var mainCTAText: String {
        String.localized(.signUp)
    }

    /// The level text to display - always shows the level based on seed count
    public var levelDisplayText: String {
        authStateProvider.levelDisplayText
    }

    /// Progress for the avatar (0.0 to 1.0)
    public var levelProgress: Double {
        authStateProvider.levelProgress
    }
}
