// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Ecosia
import Common

/**
 EcosiaAuth provides authentication management for the Ecosia browser.

 This class provides a clean chainable API and delegates to specialized components
 for improved maintainability and testability.

 ## Usage

 ```swift
 ecosiaAuth
     .onNativeAuthCompleted {
         // Called when Auth0 authentication completes
     }
     .onAuthFlowCompleted { success in
         // Called when entire flow completes
     }
     .onError { error in
         // Called when authentication fails
     }
     .login() // Starts login authentication
 ```

 ## Architecture

 - **EcosiaAuth**: Main entry point with chainable API
 - **AuthFlow**: Core authentication orchestration
 - **InvisibleTabSession**: Web session management
 - **TabAutoCloseManager**: Automatic tab cleanup
 */
final class EcosiaAuth {

    // MARK: - Dependencies

    private let authService: Ecosia.EcosiaAuthenticationService
    private weak var browserViewController: BrowserViewController?

    // MARK: - Authentication Flow Properties

    private var onNativeAuthCompletedCallback: (() -> Void)?
    private var onAuthFlowCompletedCallback: ((Bool) -> Void)?
    private var onErrorCallback: ((AuthError) -> Void)?
    private var delayedCompletionTime: TimeInterval = 0.0

    // MARK: - Initialization

    /// Initializes EcosiaAuth with required dependencies
    /// - Parameters:
    ///   - browserViewController: The browser view controller for tab operations
    ///   - authService: The authentication service for auth operations (defaults to Ecosia.EcosiaAuthenticationService.shared)
    init(browserViewController: BrowserViewController,
         authService: Ecosia.EcosiaAuthenticationService = Ecosia.EcosiaAuthenticationService.shared) {
        self.authService = authService
        self.browserViewController = browserViewController
        self.browserViewController?.ecosiaAuth = self
        EcosiaLogger.auth.info("EcosiaAuth initialized")
    }

    // MARK: - Authentication Flow

    /// Sets callback for when native Auth0 authentication completes
    /// - Parameter callback: Closure called when Auth0 authentication finishes
    /// - Returns: Self for chaining
    @discardableResult
    func onNativeAuthCompleted(_ callback: @escaping () -> Void) -> EcosiaAuth {
        onNativeAuthCompletedCallback = callback
        return self
    }

    /// Sets callback for when the complete authentication flow finishes
    /// - Parameter callback: Closure called with success status when entire flow completes
    /// - Returns: Self for chaining
    @discardableResult
    func onAuthFlowCompleted(_ callback: @escaping (Bool) -> Void) -> EcosiaAuth {
        onAuthFlowCompletedCallback = callback
        return self
    }

    /// Sets callback for when an error occurs during the authentication flow
    /// - Parameter callback: Closure called with the error when authentication fails
    /// - Returns: Self for chaining
    @discardableResult
    func onError(_ callback: @escaping (AuthError) -> Void) -> EcosiaAuth {
        onErrorCallback = callback
        return self
    }

    /// Sets the delay before firing the onNativeAuthCompleted callback
    /// - Parameter delay: Delay in seconds before calling onNativeAuthCompleted
    /// - Returns: Self for chaining
    @discardableResult
    func withDelayedCompletion(_ delay: TimeInterval) -> EcosiaAuth {
        delayedCompletionTime = delay
        return self
    }

    /// Starts the login authentication flow
    func login() {
        guard let browserViewController = browserViewController else {
            fatalError("BrowserViewController not available for auth flow")
        }

        let flow = EcosiaAuthFlow(
            type: .login,
            authService: authService,
            browserViewController: browserViewController
        )

        // Start the authentication process
        Task {
            await performLogin(flow)
        }
    }

    /// Starts the logout authentication flow
    func logout() {
        guard let browserViewController = browserViewController else {
            fatalError("BrowserViewController not available for auth flow")
        }

        let flow = EcosiaAuthFlow(
            type: .logout,
            authService: authService,
            browserViewController: browserViewController
        )

        // Start the authentication process
        Task {
            await performLogout(flow)
        }
    }

    // MARK: - Private Implementation

    private func performLogin(_ flow: EcosiaAuthFlow) async {
        let result = await flow.startLogin(
            delayedCompletion: delayedCompletionTime,
            onNativeAuthCompleted: onNativeAuthCompletedCallback,
            onFlowCompleted: onAuthFlowCompletedCallback,
            onError: onErrorCallback
        )

        switch result {
        case .success:
            EcosiaLogger.auth.debug("Login flow completed successfully")
        case .failure(let error):
            EcosiaLogger.auth.error("Login flow failed: \(error)")
            if case .userCancelled = error {
                Analytics.shared.accountSignInCancelled()
            } else {
                // Show error toast for non-cancellation errors
                await MainActor.run {
                    if #available(iOS 16.0, *) {
                        browserViewController?.showAuthFlowErrorToast(isLogin: true)
                    }
                }
            }
        }
    }

    private func performLogout(_ flow: EcosiaAuthFlow) async {
        let result = await flow.startLogout(
            delayedCompletion: delayedCompletionTime,
            onNativeAuthCompleted: onNativeAuthCompletedCallback,
            onFlowCompleted: onAuthFlowCompletedCallback,
            onError: onErrorCallback
        )

        switch result {
        case .success:
            EcosiaLogger.auth.info("Logout flow completed successfully")
        case .failure(let error):
            EcosiaLogger.auth.error("Logout flow failed: \(error)")
            // Show error toast for logout errors
            await MainActor.run {
                if #available(iOS 16.0, *) {
                    browserViewController?.showAuthFlowErrorToast(isLogin: false)
                }
            }
        }
    }

    // MARK: - State Queries

    var isLoggedIn: Bool {
        authService.isLoggedIn
    }

    var idToken: String? {
        authService.idToken
    }

    var accessToken: String? {
        authService.accessToken
    }

    var userProfile: UserProfile? {
        authService.userProfile
    }

    func renewCredentialsIfNeeded() async throws {
        try await authService.renewCredentialsIfNeeded()
    }
}
