// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// The provider model that backs the Quick Answers feature.
/// The selected model determines whether a system prompt is injected into the request.
public enum QuickAnswersModel: String, Sendable {
    case exa
    case liner

    /// The user-facing name of the model, used by the "Powered by" footer.
    public var displayName: String {
        switch self {
        case .exa: return "Exa"
        case .liner: return "Liner"
        }
    }

    /// Whether a system prompt should be injected into the request for this model.
    public var injectsSystemPrompt: Bool {
        switch self {
        case .exa: return true
        case .liner: return false
        }
    }
}
