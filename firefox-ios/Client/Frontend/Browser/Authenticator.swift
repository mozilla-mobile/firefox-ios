// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage
import Common

import struct MozillaAppServices.LoginEntry
import struct MozillaAppServices.EncryptedLogin

class Authenticator {
    fileprivate static let MaxAuthenticationAttempts = 3

    static func handleAuthRequest(
        _ viewController: UIViewController,
        challenge: URLAuthenticationChallenge,
        loginsHelper: LoginsHelper?,
        completionHandler: @escaping ((Result<LoginEntry, Error>) -> Void)
    ) {
        // If there have already been too many login attempts, we'll just fail.
        if challenge.previousFailureCount >= Authenticator.MaxAuthenticationAttempts {
            completionHandler(.failure(LoginRecordError(description: "Too many attempts to open site")))
            return
        }

        var credential = challenge.proposedCredential

        // If we were passed an initial set of credentials from iOS, try and use them.
        if let proposed = credential {
            if !(proposed.user?.isEmpty ?? true) {
                if challenge.previousFailureCount == 0 {
                    completionHandler(.success(
                        LoginEntry(credentials: proposed, protectionSpace: challenge.protectionSpace)
                    ))
                    return
                }
            } else {
                credential = nil
            }
        }

        // If we have some credentials, we'll show a prompt with them.
        if let credential = credential {
            promptForUsernamePassword(
                viewController,
                credentials: credential,
                protectionSpace: challenge.protectionSpace,
                loginsHelper: loginsHelper,
                completionHandler: completionHandler
            )
            return
        }

        // Otherwise, try to look them up and show the prompt.
        if let loginsHelper = loginsHelper {
            findMatchingCredentialsForChallenge(
                challenge,
                fromLoginsProvider: loginsHelper.logins
            ) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let credentials):
                        self.promptForUsernamePassword(
                            viewController,
                            credentials: credentials,
                            protectionSpace: challenge.protectionSpace,
                            loginsHelper: loginsHelper,
                            completionHandler: completionHandler
                        )
                    case .failure:
                        sendLoginsAutofillFailedTelemetry()
                        completionHandler(.failure(
                            LoginRecordError(description: "Unknown error when finding credentials")
                        ))
                    }
                }
            }
            return
        }

        // No credentials, so show an empty prompt.
        self.promptForUsernamePassword(
            viewController,
            credentials: nil,
            protectionSpace: challenge.protectionSpace,
            loginsHelper: nil,
            completionHandler: completionHandler
        )
    }

    static func findMatchingCredentialsForChallenge(
        _ challenge: URLAuthenticationChallenge,
        fromLoginsProvider loginsProvider: RustLogins,
        logger: Logger = DefaultLogger.shared,
        completionHandler: @escaping (Result<URLCredential?, Error>) -> Void
    ) {
        loginsProvider.getLoginsFor(protectionSpace: challenge.protectionSpace, withUsername: nil) { result in
            switch result {
            case .success(let logins):
                guard logins.count >= 1 else {
                    completionHandler(.success(nil))
                    return
                }

                let logins = filterHttpAuthLogins(logins: logins)
                var credentials: URLCredential?

                // It is possible that we might have duplicate entries since we match against host and scheme://host.
                // This is a side effect of https://bugzilla.mozilla.org/show_bug.cgi?id=1238103.
                if logins.count > 1 {
                    credentials = handleDuplicatedEntries(logins: logins,
                                                          challenge: challenge,
                                                          loginsProvider: loginsProvider)
                }

                // Found a single entry but the schemes don't match. This is a result of a schemeless entry that we
                // saved in a previous iteration of the app so we need to migrate it. We only care about the
                // the username/password so we can rewrite the scheme to be correct.
                else if logins.count == 1 && logins[0].protectionSpace.`protocol` != challenge.protectionSpace.`protocol` {
                    handleUnmatchedSchemes(logins: logins,
                                           challenge: challenge,
                                           loginsProvider: loginsProvider,
                                           completionHandler: completionHandler)
                    return
                }

                // Found a single entry that matches the scheme and host - good to go.
                else if logins.count == 1 {
                    credentials = logins[0].credentials
                } else {
                    logger.log("No logins found for Authenticator", level: .info, category: .webview)
                }

                completionHandler(.success(credentials))

            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }

    private static func filterHttpAuthLogins(logins: [EncryptedLogin]) -> [EncryptedLogin] {
        return logins.compactMap {
            // HTTP Auth must have nil formSubmitUrl and a non-nil httpRealm.
            return $0.formSubmitUrl == nil && $0.httpRealm != nil ? $0 : nil
        }
    }

    private static func handleDuplicatedEntries(logins: [EncryptedLogin],
                                                challenge: URLAuthenticationChallenge,
                                                loginsProvider: RustLogins) -> URLCredential? {
        let credentials = (logins.first(where: { login in
            (login.protectionSpace.`protocol` == challenge.protectionSpace.`protocol`)
            && !login.hasMalformedHostname
        }))?.credentials

        let malformedGUIDs: [GUID] = logins.compactMap { login in
            if login.hasMalformedHostname {
                return login.id
            }
            return nil
        }
        loginsProvider.deleteLogins(ids: malformedGUIDs) { _ in }

        return credentials
    }

    private static func handleUnmatchedSchemes(logins: [EncryptedLogin],
                                               challenge: URLAuthenticationChallenge,
                                               loginsProvider: RustLogins,
                                               completionHandler: @escaping (Result<URLCredential?, Error>) -> Void) {
        let login = logins[0]
        let credentials = login.credentials
        let new = LoginEntry(credentials: login.credentials, protectionSpace: challenge.protectionSpace)
        loginsProvider.updateLogin(id: login.id, login: new) { result in
            switch result {
            case .success:
                completionHandler(.success(credentials))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }

    fileprivate static func promptForUsernamePassword(
        _ viewController: UIViewController,
        credentials: URLCredential?,
        protectionSpace: URLProtectionSpace,
        loginsHelper: LoginsHelper?,
        logger: Logger = DefaultLogger.shared,
        completionHandler: @escaping ((Result<LoginEntry, Error>) -> Void)
    ) {
        if protectionSpace.host.isEmpty {
            logger.log("Unable to show a password prompt without a hostname", level: .warning, category: .sync)
            completionHandler(.failure(LoginRecordError(description: "Unable to show a password prompt without a hostname")))
            return
        }

        let alert: AlertController
        let title: String = .AuthenticatorPromptTitle
        if !(protectionSpace.realm?.isEmpty ?? true) {
            let msg: String = .AuthenticatorPromptRealmMessage
            let formatted = NSString(
                format: msg as NSString,
                protectionSpace.host,
                protectionSpace.realm ?? ""
            ) as String
            alert = AlertController(title: title, message: formatted, preferredStyle: .alert)
        } else {
            let msg: String = .AuthenticatorPromptEmptyRealmMessage
            let formatted = NSString(format: msg as NSString, protectionSpace.host) as String
            alert = AlertController(title: title, message: formatted, preferredStyle: .alert)
        }

        // Add a button to log in.
        let action = UIAlertAction(
            title: .AuthenticatorLogin,
            style: .default
        ) { (action) in
            guard let user = alert.textFields?[0].text,
                  let pass = alert.textFields?[1].text
            else {
                completionHandler(.failure(LoginRecordError(description: "Username and Password required")))
                return
            }

            let login = LoginEntry(
                credentials: URLCredential(user: user, password: pass, persistence: .forSession),
                protectionSpace: protectionSpace
            )
                self.sendLoginsAutofilledTelemetry()
                completionHandler(.success(login))
                loginsHelper?.setCredentials(login)
        }
        alert.addAction(action, accessibilityIdentifier: "authenticationAlert.loginRequired")

        // Add a cancel button.
        let cancel = UIAlertAction(title: .AuthenticatorCancel, style: .cancel) { (action) in
            completionHandler(.failure(LoginRecordError(description: "Save password cancelled")))
        }
        alert.addAction(cancel, accessibilityIdentifier: "authenticationAlert.cancel")

        // Add a username textfield.
        alert.addTextField { (textfield) in
            textfield.placeholder = .AuthenticatorUsernamePlaceholder
            textfield.text = credentials?.user
        }

        // Add a password textfield.
        alert.addTextField { (textfield) in
            textfield.placeholder = .AuthenticatorPasswordPlaceholder
            textfield.isSecureTextEntry = true
            textfield.text = credentials?.password
        }

        viewController.present(alert, animated: true) { () in }
    }

    // MARK: Telemetry
    private static func sendLoginsAutofilledTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .loginsAutofilled)
    }

    private static func sendLoginsAutofillFailedTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .loginsAutofillFailed)
    }
}
