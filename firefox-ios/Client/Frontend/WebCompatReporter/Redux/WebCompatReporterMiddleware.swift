// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

@MainActor
final class WebCompatReporterMiddleware {
    lazy var webCompatReporterProvider: Middleware<AppState> = { state, action in
        guard let action = action as? WebCompatReporterViewAction else { return }
        self.handleAction(action, state: state)
    }

    private func handleAction(_ action: WebCompatReporterViewAction, state: AppState) {
        switch action.actionType {
        case WebCompatReporterViewActionType.viewDidLoad:
            // The presenting layer passes the current tab URL. Payload collection
            // for the Glean ping is FXIOS-16177.
            store.dispatch(WebCompatReporterMiddlewareAction(
                url: action.url,
                windowUUID: action.windowUUID,
                actionType: WebCompatReporterMiddlewareActionType.didLoadInitialDraft
            ))

        case WebCompatReporterViewActionType.submit:
            // TODO: FXIOS-16177 collect the payload and send the broken-site-report ping.
            break

        default:
            break
        }
    }
}
