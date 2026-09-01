// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// The provider model that backs the Quick Answers feature.
public enum QuickAnswersModel: String, Sendable {
    case exa
    case liner
    /// Answers on device from the tabs and the bookmarks indexed in Spotlight.
    case spotlight

    /// The user-facing name of the model.
    public var displayName: String {
        switch self {
        case .exa: return "Exa"
        case .liner: return "Liner"
        case .spotlight: return "Spotlight"
        }
    }
}
