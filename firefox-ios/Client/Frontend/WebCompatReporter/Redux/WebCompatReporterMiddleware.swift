// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

@MainActor
final class WebCompatReporterMiddleware {
    private let windowManager: WindowManager
    private let recorder: WebCompatReportRecorder
    private let telemetry: WebCompatReporterTelemetry
    private let pageContextReader: WebCompatPageContextReading

    init(windowManager: WindowManager = AppContainer.shared.resolve(),
         recorder: WebCompatReportRecorder = WebCompatReportRecorder(),
         telemetry: WebCompatReporterTelemetry = WebCompatReporterTelemetry(),
         pageContextReader: WebCompatPageContextReading = WebCompatPageContextReader()) {
        self.windowManager = windowManager
        self.recorder = recorder
        self.telemetry = telemetry
        self.pageContextReader = pageContextReader
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
            readPageContext(windowUUID: action.windowUUID)

        case WebCompatReporterViewActionType.selectCategory:
            guard let category = action.category else { return }
            telemetry.reasonSelected(category: category)

        case WebCompatReporterViewActionType.preview:
            previewReport(windowUUID: action.windowUUID, state: state)

        case WebCompatReporterViewActionType.cancel:
            telemetry.cancelled()

        case WebCompatReporterViewActionType.learnMore:
            telemetry.learnMoreTapped()

        case WebCompatReporterViewActionType.submit:
            submitReport(windowUUID: action.windowUUID, state: state)

        default:
            break
        }
    }

    /// Preview and Send commit the field's edit before firing, so a rejected address can still arrive.
    private func previewReport(windowUUID: WindowUUID, state: AppState) {
        guard WebCompatReporterState(appState: state, uuid: windowUUID).isURLValid else { return }
        telemetry.previewed()
        store.dispatch(WebCompatReporterMiddlewareAction(
            previewPayload: makeReport(windowUUID: windowUUID, state: state),
            windowUUID: windowUUID,
            actionType: WebCompatReporterMiddlewareActionType.didBuildPreview
        ))
    }

    /// Read while the user fills in the form, so the preview and the ping stay synchronous.
    private func readPageContext(windowUUID: WindowUUID) {
        guard let tab = selectedTab(for: windowUUID) else { return }
        Task {
            let pageContext = await pageContextReader.read(from: tab)
            store.dispatch(WebCompatReporterMiddlewareAction(
                pageContext: pageContext,
                windowUUID: windowUUID,
                actionType: WebCompatReporterMiddlewareActionType.didReadPageContext
            ))
        }
    }

    private func submitReport(windowUUID: WindowUUID, state: AppState) {
        let reporterState = WebCompatReporterState(appState: state, uuid: windowUUID)
        guard reporterState.isURLValid else { return }
        recorder.submit(makeReport(windowUUID: windowUUID, state: state))
        // The screenshot option is parked (FXIOS-16450) and no image is transported yet.
        telemetry.created(withBlockedTrackers: reporterState.includeBlockedList, withScreenshot: false)

        store.dispatch(WebCompatReporterMiddlewareAction(
            windowUUID: windowUUID,
            actionType: WebCompatReporterMiddlewareActionType.didSubmit
        ))
    }

    /// The only place a report is assembled, so the preview can't differ from what's sent.
    private func makeReport(windowUUID: WindowUUID, state: AppState) -> WebCompatReportPayload {
        let reporterState = WebCompatReporterState(appState: state, uuid: windowUUID)
        let draft = WebCompatReportPayload.make(from: reporterState)
        guard let tab = selectedTab(for: windowUUID) else { return draft }
        let includeTabSpecificInfo = isReporting(reporterState.url, on: tab)
        let payload = WebCompatReportDataCollector.enrich(
            draft,
            tab: tab,
            includeBlockedList: reporterState.includeBlockedList,
            includeTabSpecificInfo: includeTabSpecificInfo
        )
        // Page context is `tab_info`, so it follows the same URL-match gate as that whole group.
        guard includeTabSpecificInfo, let pageContext = reporterState.pageContext else { return payload }
        return WebCompatReportDataCollector.enrich(payload, pageContext: pageContext)
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
