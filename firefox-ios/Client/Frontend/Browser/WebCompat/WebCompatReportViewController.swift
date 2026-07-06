// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared
import UIKit
import WebCompatReporterKit

@MainActor
protocol WebCompatReportCoordinatorDelegate: AnyObject {
    /// The user asked to dismiss the report sheet; the coordinator owns the dismissal.
    func webCompatReportViewControllerDidFinish()
}

/// Store-connected container for the "Report a Website Issue" bottom sheet.
/// It presents the store-agnostic `WebCompatReportSheetViewController` from
/// `WebCompatReporterKit` as its root, subscribes to `WebCompatReporterState`,
/// maps the state to the sheet's view model, and forwards the sheet's close and
/// preview intents to Redux and the coordinator. The sheet view controller never
/// dismisses or navigates itself.
final class WebCompatReportViewController: UINavigationController,
                                           StoreSubscriber,
                                           Themeable,
                                           WebCompatReportSheetDelegate {
    typealias SubscriberStateType = WebCompatReporterState

    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol
    var currentWindowUUID: UUID? { windowUUID }

    weak var reportCoordinator: WebCompatReportCoordinatorDelegate?

    private let windowUUID: WindowUUID
    private let reportedURL: URL?
    private let sheetViewController: WebCompatReportSheetViewController

    init(
        windowUUID: WindowUUID,
        reportedURL: URL?,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.windowUUID = windowUUID
        self.reportedURL = reportedURL
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        let initialState = WebCompatReporterState(windowUUID: windowUUID)
        self.sheetViewController = WebCompatReportSheetViewController(
            viewModel: WebCompatReportViewController.makeViewModel(from: initialState),
            theme: themeManager.getCurrentTheme(for: windowUUID)
        )
        super.init(nibName: nil, bundle: nil)
        setViewControllers([sheetViewController], animated: false)
        sheetViewController.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
        subscribeToRedux()
        store.dispatch(WebCompatReporterViewAction(
            url: reportedURL?.absoluteString,
            windowUUID: windowUUID,
            actionType: WebCompatReporterViewActionType.viewDidLoad
        ))
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unsubscribeFromRedux()
    }

    // MARK: - Redux

    func subscribeToRedux() {
        store.dispatch(ComponentAction(
            windowUUID: windowUUID,
            actionType: ComponentActionType.addComponent,
            component: .webCompatReporter
        ))
        let uuid = windowUUID
        store.subscribe(self, transform: {
            $0.select { appState in
                WebCompatReporterState(appState: appState, uuid: uuid)
            }
        })
    }

    func unsubscribeFromRedux() {
        store.dispatch(ComponentAction(
            windowUUID: windowUUID,
            actionType: ComponentActionType.removeComponent,
            component: .webCompatReporter
        ))
        store.unsubscribe(self)
    }

    func newState(state: WebCompatReporterState) {
        sheetViewController.configure(with: WebCompatReportViewController.makeViewModel(from: state))
    }

    // MARK: - View model

    private static func makeViewModel(from state: WebCompatReporterState) -> WebCompatReportViewModel {
        return WebCompatReportViewModel(
            navigationTitle: .MainMenu.ToolsSection.ReportBrokenSite,
            closeButtonAccessibilityLabel: .WebCompatReporter.Sheet.CloseButtonAccessibilityLabel,
            previewButtonTitle: .WebCompatReporter.Sheet.PreviewButton,
            isPreviewEnabled: state.canPreview
        )
    }

    // MARK: - WebCompatReportSheetDelegate

    func webCompatReportSheetDidTapClose() {
        store.dispatch(WebCompatReporterViewAction(
            windowUUID: windowUUID,
            actionType: WebCompatReporterViewActionType.cancel
        ))
        reportCoordinator?.webCompatReportViewControllerDidFinish()
    }

    func webCompatReportSheetDidTapPreview() {
        store.dispatch(WebCompatReporterViewAction(
            windowUUID: windowUUID,
            actionType: WebCompatReporterViewActionType.preview
        ))
    }

    // MARK: - Themeable

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
        navigationBar.tintColor = theme.colors.actionPrimary
        sheetViewController.applyTheme(theme: theme)
    }
}
