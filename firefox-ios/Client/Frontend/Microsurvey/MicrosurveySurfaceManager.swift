// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

protocol MicrosurveyManager: MobileMessageSurfaceProtocol {
    func showMicrosurveyPrompt() -> MicrosurveyModel?
}

class MicrosurveySurfaceManager: MicrosurveyManager {
    private var message: GleanPlumbMessage?
    private var messagingManager: GleanPlumbMessageManagerProtocol

    private let defaultSurveyOptions: [String] = [
        .Microsurvey.Survey.Options.LikertScaleOption1,
        .Microsurvey.Survey.Options.LikertScaleOption2,
        .Microsurvey.Survey.Options.LikertScaleOption3,
        .Microsurvey.Survey.Options.LikertScaleOption4,
        .Microsurvey.Survey.Options.LikertScaleOption5,
        .Microsurvey.Survey.Options.LikertScaleOption6
    ]

    init(
        messagingManager: GleanPlumbMessageManagerProtocol = Experiments.messaging
    ) {
        self.messagingManager = messagingManager
    }

    // MARK: - Functionality
    /// Checks whether a message exists, and is not expired, and attempts to
    /// build a `MicrosurveyPromptView` to be presented.
    func showMicrosurveyPrompt() -> MicrosurveyModel? {
        retrieveMessage()
        guard let message else { return nil }
        let surveyQuestion = message.text
        let promptTitle = String(
            format: message.title ?? .Microsurvey.Prompt.TitleLabel,
            AppName.shortName.rawValue
        )
        let promptButtonLabel = message.buttonLabel ?? .Microsurvey.Prompt.TakeSurveyButton
        let options = !message.options.isEmpty ? message.options : defaultSurveyOptions
        let icon = message.icon
        let utmContent = message.utmContent

        return MicrosurveyModel(
            id: message.id,
            promptTitle: promptTitle,
            promptButtonLabel: promptButtonLabel,
            surveyQuestion: surveyQuestion,
            surveyOptions: options,
            icon: icon,
            utmContent: utmContent
        )
    }

    private func retrieveMessage() {
        message = messagingManager.getNextMessage(for: .microsurvey)
    }

    // MARK: - MobileMessageSurfaceProtocol
    func handleMessageDisplayed() {
        message.map(messagingManager.onMessageDisplayed)
    }

    func handleMessagePressed() {
        guard let message else { return }
        messagingManager.onMessagePressed(message, window: nil, shouldExpire: false)
    }

    func handleMessageDismiss() {
        message.map(messagingManager.onMessageDismissed)
    }
}
