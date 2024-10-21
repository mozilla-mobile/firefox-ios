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

    init(logger: Logger = DefaultLogger.shared,
         generatedPasswordStorage: GeneratedPasswordStorageProtocol = GeneratedPasswordStorage()) {
        self.logger = logger
        self.generatedPasswordStorage = generatedPasswordStorage
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
        // TODO: FXIOS-10279 - change password to be associated with the iframe origin that
        // contains the password field rather than tab origin
        guard let origin = frame.request.url?.origin else {return}
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
        let jsFunctionCall = "window.__firefox__.logins.generatePassword()"
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
        guard let origin = frame.request.url?.origin else {return}
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
}
