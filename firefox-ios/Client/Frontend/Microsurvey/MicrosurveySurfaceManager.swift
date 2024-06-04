// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class MicrosurveySurfaceManager: MobileMessageSurfaceProtocol {
    private var message: GleanPlumbMessage?
    private var messagingManager: GleanPlumbMessageManagerProtocol

    private let defaultSurveyOptions: [String] = [
        .Microsurvey.Survey.Options.LikertScaleOption1,
        .Microsurvey.Survey.Options.LikertScaleOption2,
        .Microsurvey.Survey.Options.LikertScaleOption3,
        .Microsurvey.Survey.Options.LikertScaleOption4,
        .Microsurvey.Survey.Options.LikertScaleOption5
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
        guard let surveyQuestion = message?.text else {
            return nil
        }

        let promptTitle = message?.title ?? String(
            format: .Microsurvey.Prompt.TitleLabel,
            AppName.shortName.rawValue
        )
        let promptButtonLabel = message?.buttonLabel ?? .Microsurvey.Prompt.TakeSurveyButton
        let options: [String] = message?.options ?? defaultSurveyOptions

        return MicrosurveyModel(
            promptTitle: promptTitle,
            promptButtonLabel: promptButtonLabel,
            surveyQuestion: surveyQuestion,
            surveyOptions: options
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
        // TODO: FXIOS-8797: Add telemetry to capture user responses
        message.map(messagingManager.onMessagePressed)
    }

    func handleMessageDismiss() {
        message.map(messagingManager.onMessageDismissed)
    }
}
