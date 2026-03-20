// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import LocalAuthentication
import WebKit

enum AuthenticationError: Error {
    case failedEvaluation(message: String)
    case failedAuthentication(message: String)
}

enum AuthenticationState {
    case deviceOwnerAuthenticated
    case deviceOwnerFailed
    case passCodeRequired
}

@MainActor
protocol AppAuthenticationProtocol {
    var canAuthenticateDeviceOwner: Bool { get }
    var isAuthenticating: Bool { get }

    func getAuthenticationState(completion: @MainActor @escaping (AuthenticationState) -> Void)
    func authenticateWithDeviceOwnerAuthentication(
        _ completion: @MainActor @escaping (Result<Void, AuthenticationError>) -> Void
    )
}

final class AppAuthenticator: AppAuthenticationProtocol {
    private(set) var isAuthenticating = false

    func getAuthenticationState(completion: @MainActor @escaping (AuthenticationState) -> Void) {
        if canAuthenticateDeviceOwner {
            isAuthenticating = true
            authenticateWithDeviceOwnerAuthentication { result in
                DispatchQueue.main.async {
                    self.isAuthenticating = false
                    switch result {
                    case .success:
                        completion(.deviceOwnerAuthenticated)
                    case .failure:
                        completion(.deviceOwnerFailed)
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                self.isAuthenticating = false
                completion(.passCodeRequired)
            }
        }
    }

    func authenticateWithDeviceOwnerAuthentication(
        _ completion: @MainActor @escaping (Result<Void, AuthenticationError>) -> Void
    ) {
        // Get a fresh context for each login. If you use the same context on multiple attempts
        //  (by commenting out the next line), then a previously successful authentication
        //  causes the next policy evaluation to succeed without testing biometry again.
        //  That's usually not what you want.

        // TODO: This was recently changed in PR #31888 for FXIOS-14501, but it causes an issue with our biometrics,
        // similar to the bug described above; we need to use a new LAContext for each authentication.
        let context = LAContext()

        isAuthenticating = true

        // First check if we have the needed hardware support.
        var error: NSError?
        let localizedErrorMessage = String.Biometry.Screen.UniversalAuthenticationReasonV2
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: localizedErrorMessage
            ) { success, error in
                if success {
                    DispatchQueue.main.async {
                        self.isAuthenticating = false
                        completion(.success(()))
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isAuthenticating = false
                        completion(
                            .failure(
                                .failedAuthentication(message: error?.localizedDescription ?? "Failed to authenticate")
                            )
                        )
                    }
                }
            }
        } else {
            let failureError = error
            DispatchQueue.main.async {
                self.isAuthenticating = false
                completion(.failure(
                    .failedEvaluation(
                        message: failureError?.localizedDescription ?? "Can't evaluate policy"
                    )
                ))
            }
        }
    }

    var canAuthenticateDeviceOwner: Bool {
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }
}
