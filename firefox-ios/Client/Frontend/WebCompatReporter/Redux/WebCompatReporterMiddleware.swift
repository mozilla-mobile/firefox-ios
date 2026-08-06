// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

@MainActor
final class WebCompatReporterMiddleware {
    private let windowManager: WindowManager
    private let recorder: WebCompatReportRecorder

    init(windowManager: WindowManager = AppContainer.shared.resolve(),
         recorder: WebCompatReportRecorder = WebCompatReportRecorder()) {
        self.windowManager = windowManager
        self.recorder = recorder
    }

    lazy var webCompatReporterProvider: Middleware<AppState> = (legacyProvider, modernProvider)

    lazy var modernProvider: MiddlewareClosure<AppState> = { [self] state, action, windowUUID in
        // Does not test any modern actions
    }

    lazy var legacyProvider: LegacyMiddlewareClosure<AppState> = { [self] state, action in
        guard let action = action as? WebCompatReporterViewAction else { return }
        self.handleAction(action, state: state)
    }

    private func handleAction(_ action: WebCompatReporterViewAction, state: AppState) {
        switch action.actionType {
        case WebCompatReporterViewActionType.viewDidLoad:
            // The presenting layer passes the current tab URL.
            store.dispatch(WebCompatReporterMiddlewareAction(
                url: action.url,
                windowUUID: action.windowUUID,
                actionType: WebCompatReporterMiddlewareActionType.didLoadInitialDraft
            ))

        case WebCompatReporterViewActionType.submit:
            submitReport(windowUUID: action.windowUUID, state: state)

        default:
            break
        }
    }

    private func submitReport(windowUUID: WindowUUID, state: AppState) {
        let reporterState = WebCompatReporterState(appState: state, uuid: windowUUID)
        var payload = WebCompatReportPayload.make(from: reporterState)
        if let tab = selectedTab(for: windowUUID) {
            payload = WebCompatReportDataCollector.enrich(
                payload,
                tab: tab,
                includeBlockedList: reporterState.includeBlockedList,
                includeTabSpecificInfo: isReporting(reporterState.url, on: tab)
            )
        }
        recorder.submit(payload)

        store.dispatch(WebCompatReporterMiddlewareAction(
            windowUUID: windowUUID,
            actionType: WebCompatReporterMiddlewareActionType.didSubmit
        ))
    }

    private func selectedTab(for windowUUID: WindowUUID) -> Tab? {
        return windowManager.tabManager(for: windowUUID)?.selectedTab
    }

    /// Origin and path, as desktop does.
    private func isReporting(_ reportedURL: String, on tab: Tab) -> Bool {
        guard let reported = URL(string: reportedURL), let current = tab.url else { return false }
        return reported.scheme == current.scheme
            && reported.host == current.host
            && reported.port == current.port
            && reported.path == current.path
    }
}
