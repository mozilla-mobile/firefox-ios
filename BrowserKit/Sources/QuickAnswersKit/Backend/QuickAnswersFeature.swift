// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// The remotely configured Quick Answers feature, mirroring the `quick-answers-feature` Nimbus definition.
public struct QuickAnswersFeature: Equatable, Sendable {
    /// The provider model that backs the request.
    public let model: QuickAnswersModel
    /// Whether the redesigned opt-in is shown as a sheet over the browser.
    public let isOptInRedesignEnabled: Bool
    /// Whether follow up questions are enabled, so past exchanges are sent along with a new question.
    public let isFollowUpEnabled: Bool

    public init(model: QuickAnswersModel, isOptInRedesignEnabled: Bool, isFollowUpEnabled: Bool = false) {
        self.model = model
        self.isOptInRedesignEnabled = isOptInRedesignEnabled
        self.isFollowUpEnabled = isFollowUpEnabled
    }

    /// Whether a new question is sent along with the previous exchanges, so it can follow up on them.
    var supportsFollowUpQuestions: Bool {
        return isFollowUpEnabled && model.supportsAssistantRole
    }
}
