// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux

class TermsOfUseMiddleware {
    lazy var termsOfUseProvider: Middleware<AppState> = { _, action in
        guard let action = action as? TermsOfUseAction,
              let type = action.actionType as? TermsOfUseActionType else { return }

        switch type {
        case .markAccepted:
            // Track telemetry here
            break
        case .markDismissed:
            // Track telemetry here
            break
        case .markShownThisLaunch:
            // Track telemetry here
            break
        }
    }
}
