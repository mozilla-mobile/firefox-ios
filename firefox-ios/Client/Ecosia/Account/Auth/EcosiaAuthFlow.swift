// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Ecosia

/// Result of authentication flow operations
public enum EcosiaAuthFlowResult {
    case success
    case failure(error: AuthError)
}

/// Orchestrates complete authentication flows with invisible tab sessions
/// Provides core functionality for authentication operations
@MainActor
final class EcosiaAuthFlow {

    public enum FlowType {
        case login
        case signUp
        case logout
    }

    // MARK: - Core Properties

    private let authService: EcosiaAuthenticationService
    private weak var browserViewController: BrowserViewController?
    private let type: FlowType

    // Active session (retained until completion)
    private var activeSession: InvisibleTabSession?

    // MARK: - Initialization

    /// Initializes the auth flow coordinator
    /// - Parameters:
    ///   - type: Type of authentication flow (login or logout)
    ///   - authService: Authentication service for auth operations
    ///   - browserViewController: Browser view controller for tab operations
    init(type: FlowType,
         authService: Ecosia.EcosiaAuthenticationService,
         browserViewController: BrowserViewController) {
        self.type = type
        self.authService = authService
        self.browserViewController = browserViewController

        EcosiaLogger.auth.info("AuthFlow initialized for \(type)")
    }

    // MARK: - Public Core API

    /// Starts the login authentication flow
    /// - Parameters:
    ///   - delayedCompletion: Delay before calling onNativeAuthCompleted
    ///   - onNativeAuthCompleted: Callback when Auth0 authentication completes
    ///   - onFlowCompleted: Callback when entire flow completes
    ///   - onError: Callback when authentication fails
    /// - Returns: Result of the authentication operation
    public func startLogin(
        delayedCompletion: TimeInterval = 0.0,
        onNativeAuthCompleted: (() -> Void)? = nil,
        onFlowCompleted: ((Bool) -> Void)? = nil,
        onError: ((AuthError) -> Void)? = nil
    ) async -> EcosiaAuthFlowResult {
        return await performAuthentication(
            type: .login,
            delayedCompletion: delayedCompletion,
            onNativeAuthCompleted: onNativeAuthCompleted,
            onFlowCompleted: onFlowCompleted,
            onError: onError
        )
    }

    public func startSignUp(
        delayedCompletion: TimeInterval = 0.0,
        onNativeAuthCompleted: (() -> Void)? = nil,
        onFlowCompleted: ((Bool) -> Void)? = nil,
        onError: ((AuthError) -> Void)? = nil
    ) async -> EcosiaAuthFlowResult {
        return await performAuthentication(
            type: .signUp,
            delayedCompletion: delayedCompletion,
            onNativeAuthCompleted: onNativeAuthCompleted,
            onFlowCompleted: onFlowCompleted,
            onError: onError
        )
    }

    /// Starts the logout authentication flow
    /// - Parameters:
    ///   - delayedCompletion: Delay before calling onNativeAuthCompleted
    ///   - onNativeAuthCompleted: Callback when Auth0 authentication completes
    ///   - onFlowCompleted: Callback when entire flow completes
    ///   - onError: Callback when authentication fails
    /// - Returns: Result of the authentication operation
    public func startLogout(
        delayedCompletion: TimeInterval = 0.0,
        onNativeAuthCompleted: (() -> Void)? = nil,
        onFlowCompleted: ((Bool) -> Void)? = nil,
        onError: ((AuthError) -> Void)? = nil
    ) async -> EcosiaAuthFlowResult {
        return await performAuthentication(
            type: .logout,
            delayedCompletion: delayedCompletion,
            onNativeAuthCompleted: onNativeAuthCompleted,
            onFlowCompleted: onFlowCompleted,
            onError: onError
        )
    }

    // MARK: - Private Implementation

    private func performAuthentication(type: FlowType,
                                       delayedCompletion: TimeInterval = 0.0,
                                       onNativeAuthCompleted: (() -> Void)? = nil,
                                       onFlowCompleted: ((Bool) -> Void)? = nil,
                                       onError: ((AuthError) -> Void)? = nil
    ) async -> EcosiaAuthFlowResult {

        EcosiaLogger.auth.info("Starting \(type) flow")

        do {
            switch type {
            case .login:
                // Step 1: Native Auth0 authentication
                try await performNativeAuthentication(screenHint: .login)

                // Step 2: Handle native auth completion callback
                await handleNativeAuthCompleted(
                    delayedCompletion: delayedCompletion,
                    onNativeAuthCompleted: onNativeAuthCompleted
                )

                // Step 3: Session transfer and invisible tab flow
                try await performSessionTransfer(onFlowCompleted: onFlowCompleted)

            case .signUp:
                try await performNativeAuthentication(screenHint: .signUp)

                await handleNativeAuthCompleted(
                    delayedCompletion: delayedCompletion,
                    onNativeAuthCompleted: onNativeAuthCompleted
                )

                try await performSessionTransfer(onFlowCompleted: onFlowCompleted)

            case .logout:
                // Step 1: Native Auth0 logout
                try await performNativeLogout()

                // Step 2: Handle native logout completion callback
                await handleNativeAuthCompleted(
                    delayedCompletion: delayedCompletion,
                    onNativeAuthCompleted: onNativeAuthCompleted
                )

                // Step 3: Session cleanup and invisible tab flow
                try await performSessionCleanup(onFlowCompleted: onFlowCompleted)
            }

            return .success
        } catch {
            let authError = mapToAuthError(error)
            await handleAuthFailure(authError, onError: onError)
            return .failure(error: authError)
        }
    }

    private func performNativeAuthentication(screenHint: AuthScreenHint) async throws {
        // Debug: Simulate auth error if enabled
        if UserDefaults.standard.bool(forKey: SimulateAuthErrorSetting.debugKey) {
            EcosiaLogger.auth.info("🐛 [DEBUG] Simulating login error")
            throw AuthError.authenticationFailed(NSError(domain: "EcosiaDebug", code: -1, userInfo: [NSLocalizedDescriptionKey: "Debug: Simulated authentication error"]))
        }

        EcosiaLogger.auth.info("Performing native Auth0 authentication (\(screenHint.rawValue))")
        switch screenHint {
        case .login:
            try await authService.login()
        case .signUp:
            try await authService.signUp()
        }
        EcosiaLogger.auth.info("Native Auth0 authentication completed")
    }

    private func performNativeLogout() async throws {
        // Debug: Simulate auth error if enabled
        if UserDefaults.standard.bool(forKey: SimulateAuthErrorSetting.debugKey) {
            EcosiaLogger.auth.info("🐛 [DEBUG] Simulating logout error")
            throw AuthError.sessionClearingFailed(NSError(domain: "EcosiaDebug", code: -1, userInfo: [NSLocalizedDescriptionKey: "Debug: Simulated logout error"]))
        }

        EcosiaLogger.auth.info("Performing native Auth0 logout")
        try await authService.logout()
        EcosiaLogger.auth.info("Native Auth0 logout completed")
    }

    private func handleNativeAuthCompleted(delayedCompletion: TimeInterval,
                                           onNativeAuthCompleted: (() -> Void)?) async {
        if delayedCompletion > 0 {
            // Ecosia: Use nanoseconds for iOS 15 compatibility (Task.sleep(for: .seconds) is iOS 16+)
            try? await Task.sleep(nanoseconds: UInt64(delayedCompletion * 1_000_000_000))
            onNativeAuthCompleted?()
        } else {
            onNativeAuthCompleted?()
        }
    }

    private func performSessionTransfer(onFlowCompleted: ((Bool) -> Void)?) async throws {

        guard let browserViewController = browserViewController else {
            throw AuthError.authFlowConfigurationError("BrowserViewController not available")
        }

        // Get session transfer URL.
        // Debug hook: loads /accounts/error directly instead of the real sign-up URL.
        let signUpURL = SimulateSessionTransferFailureSetting.isEnabled
            ? SimulateSessionTransferFailureSetting.forcedErrorPageURL
            : EcosiaEnvironment.current.urlProvider.signUpURL

        EcosiaLogger.session.info("Retrieving session transfer token for SSO")
        await authService.getSessionTransferToken()

        // Create invisible tab session (must be on main thread for UI operations)
        EcosiaLogger.invisibleTabs.info("Creating invisible tab session for login")
        let session = try await MainActor.run {
            try InvisibleTabSession(
                url: signUpURL,
                browserViewController: browserViewController,
                authService: authService,
                timeout: 10.0
            )
        }

        // Retain session until completion
        activeSession = session

        // Set up session cookies (main-actor isolated)
        await MainActor.run { session.setupSessionCookies() }

        // Wait for session completion (startMonitoring is main-actor isolated)
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                session.startMonitoring { [weak self] success in
                    Task { @MainActor in
                        self?.activeSession = nil // Release session
                        EcosiaLogger.auth.info("Ecosia auth flow completed: \(success)")
                        if !success {
                            await self?.logOutNativelyAfterFailedSessionTransfer()
                        }
                        onFlowCompleted?(success)
                        continuation.resume()
                    }
                }
            }
        }
    }

    /// A failed session transfer means the web session was never actually authenticated,
    /// so clear native credentials too instead of leaving native "logged in" with no working web session.
    /// `triggerWebLogout: false` since the web side already failed to authenticate; nothing there to log out of.
    private func logOutNativelyAfterFailedSessionTransfer() async {
        do {
            try await authService.logout(triggerWebLogout: false)
        } catch {
            EcosiaLogger.auth.error("Native-only logout after failed session transfer also failed: \(error)")
        }
    }

    private func performSessionCleanup(onFlowCompleted: ((Bool) -> Void)?) async throws {

        guard let browserViewController = browserViewController else {
            throw AuthError.authFlowConfigurationError("BrowserViewController not available")
        }

        // Get logout URL
        // Debug hook: loads /accounts/error directly instead of the real sign-up URL.
        let logoutURL = SimulateSessionTransferFailureSetting.isEnabled
            ? SimulateSessionTransferFailureSetting.forcedErrorPageURL
            : EcosiaEnvironment.current.urlProvider.logoutURL

        // Create invisible tab session for logout (must be on main thread for UI operations)
        EcosiaLogger.invisibleTabs.info("Creating invisible tab session for logout")
        let session = try await MainActor.run {
            try InvisibleTabSession(
                url: logoutURL,
                browserViewController: browserViewController,
                authService: authService,
                timeout: 10.0
            )
        }

        // Retain session until completion
        activeSession = session

        // Wait for session completion (startMonitoring is main-actor isolated)
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                session.startMonitoring { [weak self] success in
                    self?.activeSession = nil // Release session
                    EcosiaLogger.auth.info("Ecosia logout flow completed: \(success)")
                    onFlowCompleted?(success)
                    continuation.resume()
                }
            }
        }
    }

    private func handleAuthFailure(_ error: AuthError,
                                   onError: ((AuthError) -> Void)?) async {
        activeSession = nil

        EcosiaLogger.auth.error("Auth flow failed: \(error)")
        onError?(error)
    }

    private func mapToAuthError(_ error: Error) -> AuthError {
        if let authError = error as? AuthError {
            return authError
        }
        return AuthError.authFlowConfigurationError(error.localizedDescription)
    }
}
