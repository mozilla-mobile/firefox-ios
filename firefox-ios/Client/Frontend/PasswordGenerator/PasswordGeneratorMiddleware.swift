// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Shared
import Common
import WebKit

@MainActor
final class PasswordGeneratorMiddleware {
    private let logger: Logger
    private let generatedPasswordStorage: GeneratedPasswordStorageProtocol
    private let passwordGeneratorTelemetry = PasswordGeneratorTelemetry()

    // The JS password generator generates a password using a list of DEFAULT_RULES.
    // Some websites, however, fail when generating the password using the default rules.
    // For these websites we have specific rules hosted in remote settings in the password-rules collection.
    // We cache them so we don't have to parse the JSON every time.
    // TODO: FXIOS-12590 This global property is not concurrency safe
    nonisolated(unsafe) private static var cachedPasswordRules: [PasswordRuleRecord]?

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
            guard let frameContext = (action as? PasswordGeneratorAction)?.frameContext else { return }
            self.showPasswordGenerator(frameContext: frameContext, windowUUID: windowUUID)

        case PasswordGeneratorActionType.userTappedUsePassword:
            guard let frameContext = (action as? PasswordGeneratorAction)?.frameContext else { return }
            guard let password = state.screenState(PasswordGeneratorState.self,
                                                   for: .passwordGenerator,
                                                   window: action.windowUUID)?.password else {return}
            self.userTappedUsePassword(frameContext: frameContext, password: password)

        case PasswordGeneratorActionType.userTappedRefreshPassword:
            guard let frameContext = (action as? PasswordGeneratorAction)?.frameContext else { return }
            self.userTappedRefreshPassword(frameContext: frameContext, windowUUID: windowUUID)

        case PasswordGeneratorActionType.clearGeneratedPasswordForSite:
            guard let origin = (action as? PasswordGeneratorAction)?.loginEntryOrigin else { return }
            self.clearGeneratedPasswordForSite(origin: origin, windowUUID: windowUUID)

        default:
            break
        }
    }

    private func showPasswordGenerator(frameContext: PasswordGeneratorFrameContext, windowUUID: WindowUUID) {
        guard let origin = frameContext.origin else { return }
        passwordGeneratorTelemetry.passwordGeneratorDialogShown()
        if let password = generatedPasswordStorage.getPasswordForOrigin(origin: origin) {
            let newAction = PasswordGeneratorAction(
                windowUUID: windowUUID,
                actionType: PasswordGeneratorActionType.updateGeneratedPassword,
                password: password
            )
            store.dispatch(newAction)
        } else {
            generateNewPassword(frameContext: frameContext, completion: { generatedPassword in
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

    private func generateNewPassword(frameContext: PasswordGeneratorFrameContext,
                                     completion: @MainActor @escaping (String) -> Void) {
        let originRules = PasswordGeneratorMiddleware.getPasswordRule(for: frameContext.host)
        let jsFunctionCall = "window.__firefox__.logins.generatePassword(\(originRules ?? "" ))"
        frameContext.scriptEvaluator.evaluateJavascriptInDefaultContentWorld(jsFunctionCall,
                                                                             frameContext.frameInfo) { (result, error) in
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

    private func userTappedUsePassword(frameContext: PasswordGeneratorFrameContext, password: String) {
        passwordGeneratorTelemetry.usePasswordButtonPressed()
        guard let escapedPassword = escapeString(string: password) else { return }

        let jsFunctionCall = "window.__firefox__.logins.fillGeneratedPassword(\(escapedPassword))"
        frameContext.scriptEvaluator.evaluateJavascriptInDefaultContentWorld(jsFunctionCall,
                                                                             frameContext.frameInfo) { (result, error) in
            if error != nil {
                self.logger.log("Error filling in password info",
                                level: .warning,
                                category: .passwordGenerator)
            }
        }
    }

    private func escapeString(string: String) -> String? {
        guard let jsonData = try? JSONEncoder().encode(string),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            self.logger.log("Error encoding generated password to JSON",
                            level: .warning,
                            category: .passwordGenerator)
            return nil
        }
        return jsonString
    }

    private func userTappedRefreshPassword(frameContext: PasswordGeneratorFrameContext, windowUUID: WindowUUID) {
        guard let origin = frameContext.origin else {return}
        generateNewPassword(frameContext: frameContext, completion: { generatedPassword in
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
