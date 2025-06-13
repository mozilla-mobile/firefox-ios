// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

/// FeedbackType represents the type of feedback a user can submit
public enum FeedbackType: String, CaseIterable, Identifiable {
    case reportIssue = "Report an issue"
    case suggestionOrFeedback = "Suggestion or feedback"

    public var id: String { self.rawValue }

    var analyticsIdentfier: String {
        switch self {
        case .reportIssue:
            return "report_issue"
        case .suggestionOrFeedback:
            return "suggestion_or_feedback"
        }
    }

    var localizedString: String {
        switch self {
        case .reportIssue:
            return String.localized(.reportIssue)
        case .suggestionOrFeedback:
            return String.localized(.suggestionOrFeedback)
        }
    }
}
