// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MLPAKit

/// The provider model that backs the Quick Answers feature.
public enum QuickAnswersModel: String, CaseIterable, Sendable {
    case exa
    case liner

    /// The MLPA service backing the model, sent as the service type of every request so the proxy
    /// routes it to the right provider.
    var serviceType: MLPAServiceType {
        return switch self {
        case .exa: .quickAnswersExa
        case .liner: .quickAnswersLiner
        }
    }

    /// Whether the provider accepts `assistant` messages. Exa's answer endpoint doesn't: it answers the
    /// last user message, so for it the conversation history is inlined into the question instead.
    var supportsAssistantRole: Bool {
        return switch self {
        case .exa: false
        case .liner: true
        }
    }

    /// The user-facing name of the model.
    public var displayName: String {
        return switch self {
        case .exa: "Exa"
        case .liner: "Liner"
        }
    }
}
