/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import LocalAuthentication

class AuthenticationManager {

    enum AuthenticationState {
        case loggedin, loggedout, canceled
    }
    @Published private(set) var authenticationState = AuthenticationState.loggedout
    private(set) var biometricType = LABiometryType.none
    private(set) var canEvaluatePolicy = false
    private(set) var context = LAContext()
    var userEnabledBiometrics: Bool {  Settings.getToggle(SettingsToggle.biometricLogin) }

    init() {
        canEvaluatePolicy = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        biometricType = context.biometryType
    }

    @MainActor
    func authenticateWithBiometrics() async {
        context = LAContext()
        canEvaluatePolicy = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)

        guard userEnabledBiometrics, canEvaluatePolicy else {
            authenticationState = .loggedin
            return
        }

        context.localizedReason = String(format: UIConstants.strings.authenticationReason, AppInfo.productName)
        // TODO: Check what is the best name for cancellation
//        context.localizedCancelTitle = UIConstants.strings.newSessionFromBiometricFailure

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: context.localizedReason
            )
            authenticationState = success ? .loggedin : .loggedout

        } catch {
            authenticationState = .canceled
        }
    }

    func logout() {
        // Biometrics is not enrolled in system settings/user did not enable biometrics in app Settings, ignore user logout
        guard canEvaluatePolicy, userEnabledBiometrics else { return }
        authenticationState =  .loggedout
    }
}
