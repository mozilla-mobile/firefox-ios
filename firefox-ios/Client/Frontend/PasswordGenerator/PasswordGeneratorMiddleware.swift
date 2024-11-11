// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Shared
import Common
import WebKit

final class PasswordGeneratorMiddleware {
    private let logger: Logger
    private let generatedPasswordStorage: GeneratedPasswordStorageProtocol
    private let passwordGeneratorTelemetry = PasswordGeneratorTelemetry()

    // The JS password generator generates a password using a list of DEFAULT_RULES.
    // Some websites, however, fail when generating the password using the default rules.
    // For these websites we have specific rules hosted in remote settings in the password-rules collection.
    // We cache them so we don't have to parse the JSON everytime.
    private static var cachedPasswordRules: [PasswordRuleRecord]?

    init(logger: Logger = DefaultLogger.shared,
         generatedPasswordStorage: GeneratedPasswordStorageProtocol = GeneratedPasswordStorage()) {
        self.logger = logger
        self.generatedPasswordStorage = generatedPasswordStorage
        // Preload password rules and cache them in cachedPasswordRules
        PasswordGeneratorMiddleware.loadPasswordRules()
    }

    lazy var passwordGeneratorProvider: Middleware<AppState> = { state, action in
        let windowUUID = action.windowUUID

        switch action.actionType {
        case PasswordGeneratorActionType.showPasswordGenerator:
            guard let currentFrame = (action as? PasswordGeneratorAction)?.currentFrame else { return }
            self.showPasswordGenerator(frame: currentFrame, windowUUID: windowUUID)

        case PasswordGeneratorActionType.userTappedUsePassword:
            guard let currentFrame = (action as? PasswordGeneratorAction)?.currentFrame else { return }
            guard let password = state.screenState(PasswordGeneratorState.self,
                                                   for: .passwordGenerator,
                                                   window: action.windowUUID)?.password else {return}
            self.userTappedUsePassword(frame: currentFrame, password: password)

        case PasswordGeneratorActionType.userTappedRefreshPassword:
            guard let currentFrame = (action as? PasswordGeneratorAction)?.currentFrame else { return }
            self.userTappedRefreshPassword(frame: currentFrame, windowUUID: windowUUID)

        case PasswordGeneratorActionType.clearGeneratedPasswordForSite:
            guard let origin = (action as? PasswordGeneratorAction)?.origin else { return }
            self.clearGeneratedPasswordForSite(origin: origin, windowUUID: windowUUID)

        default:
            break
        }
    }

    private func showPasswordGenerator(frame: WKFrameInfo, windowUUID: WindowUUID) {
        guard let origin = frame.webView?.url?.origin else {return}
        passwordGeneratorTelemetry.passwordGeneratorDialogShown()
        if let password = generatedPasswordStorage.getPasswordForOrigin(origin: origin) {
            let newAction = PasswordGeneratorAction(
                windowUUID: windowUUID,
                actionType: PasswordGeneratorActionType.updateGeneratedPassword,
                password: password
            )
            store.dispatch(newAction)
        } else {
            generateNewPassword(frame: frame, completion: { generatedPassword in
                self.generatedPasswordStorage.setPasswordForOrigin(origin: origin, password: generatedPassword)
                let newAction = PasswordGeneratorAction(
                    windowUUID: windowUUID,
                    actionType: PasswordGeneratorActionType.updateGeneratedPassword,
                    password: generatedPassword
                )
                store.dispatch(newAction)
            })
        }
    }

    private func generateNewPassword(frame: WKFrameInfo, completion: @escaping (String) -> Void) {
        let originRules = PasswordGeneratorMiddleware.getPasswordRule(for: frame.securityOrigin.host)
        let jsFunctionCall = "window.__firefox__.logins.generatePassword(\(originRules ?? "" ))"
        frame.webView?.evaluateJavascriptInDefaultContentWorld(jsFunctionCall, frame) { (result, error) in
            if let error = error {
                self.logger.log("JavaScript evaluation error",
                                level: .warning,
                                category: .webview,
                                description: "\(error.localizedDescription)")
            } else if let result = result as? String {
                completion(result)
            }
        }
    }

    private func userTappedUsePassword(frame: WKFrameInfo, password: String) {
        passwordGeneratorTelemetry.usePasswordButtonPressed()
        let jsFunctionCall = "window.__firefox__.logins.fillGeneratedPassword(\"\(password)\")"
        frame.webView?.evaluateJavascriptInDefaultContentWorld(jsFunctionCall, frame) { (result, error) in
            if error != nil {
                self.logger.log("Error filling in password info",
                                level: .warning,
                                category: .webview)
            }
        }
    }

    private func userTappedRefreshPassword(frame: WKFrameInfo, windowUUID: WindowUUID) {
        guard let origin = frame.webView?.url?.origin else {return}
        generateNewPassword(frame: frame, completion: { generatedPassword in
            self.generatedPasswordStorage.setPasswordForOrigin(origin: origin, password: generatedPassword)
            let newAction = PasswordGeneratorAction(
                windowUUID: windowUUID,
                actionType: PasswordGeneratorActionType.updateGeneratedPassword,
                password: generatedPassword
            )
            store.dispatch(newAction)
        })
    }

    private func clearGeneratedPasswordForSite(origin: String, windowUUID: WindowUUID) {
        generatedPasswordStorage.deletePasswordForOrigin(origin: origin)
    }

    private static func loadPasswordRules() {
        // If we have already fetched the password rules, return early since we have them in cache
        guard cachedPasswordRules == nil else { return }

        Task {
            let remoteSettingsUtils = RemoteSettingsUtils()
            let rules: [PasswordRuleRecord]? = await remoteSettingsUtils.fetchLocalRecords(for: .passwordRules)
            cachedPasswordRules = rules
        }
    }

    private static func getPasswordRule(for frameOrigin: String) -> String? {
        let matchingRecord = cachedPasswordRules?.first(where: { frameOrigin.hasSuffix($0.domain) })
        guard let record = matchingRecord,
              let jsonData = try? JSONEncoder().encode(record),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        return jsonString
    }
}
