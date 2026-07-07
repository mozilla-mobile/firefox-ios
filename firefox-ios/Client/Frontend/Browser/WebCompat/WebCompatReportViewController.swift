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
    /// Sheet asked to finish; the coordinator owns the dismissal.
    func webCompatReportViewControllerDidFinish()
    /// User tapped the "Learn More…" link; the coordinator opens the explainer page.
    func webCompatReportViewControllerDidTapLearnMore()
}

/// Store-connected container that hosts the `WebCompatReporterKit` sheet, maps
/// `WebCompatReporterState` to its view model, and forwards its intents to Redux
/// and the coordinator.
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
            viewModel: WebCompatReportViewModelMapper.map(from: initialState),
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
        sheetViewController.configure(with: WebCompatReportViewModelMapper.map(from: state))
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

    func webCompatReportSheetDidSelectCategory(id: String) {
        guard let category = WebCompatIssueCategory(rawValue: id) else { return }
        store.dispatch(WebCompatReporterViewAction(
            category: category,
            windowUUID: windowUUID,
            actionType: WebCompatReporterViewActionType.selectCategory
        ))
    }

    func webCompatReportSheetDidSelectSubOption(id: String) {
        guard let subOption = WebCompatSubOption(rawValue: id) else { return }
        store.dispatch(WebCompatReporterViewAction(
            subOptionID: subOption.rawValue,
            windowUUID: windowUUID,
            actionType: WebCompatReporterViewActionType.selectSubOption
        ))
    }

    func webCompatReportSheetDidEditText(id: String, text: String) {
        switch WebCompatReportViewModelMapper.RowID(rawValue: id) {
        case .url:
            store.dispatch(WebCompatReporterViewAction(
                url: text,
                windowUUID: windowUUID,
                actionType: WebCompatReporterViewActionType.editURL
            ))
        case .additionalDetails:
            store.dispatch(WebCompatReporterViewAction(
                additionalDetails: text,
                windowUUID: windowUUID,
                actionType: WebCompatReporterViewActionType.setAdditionalDetails
            ))
        default:
            break
        }
    }

    func webCompatReportSheetDidToggle(id: String, isOn: Bool) {
        switch WebCompatReportViewModelMapper.RowID(rawValue: id) {
        case .includeScreenshot:
            store.dispatch(WebCompatReporterViewAction(
                includeScreenshot: isOn,
                windowUUID: windowUUID,
                actionType: WebCompatReporterViewActionType.toggleScreenshot
            ))
        case .includeBlockedList:
            store.dispatch(WebCompatReporterViewAction(
                includeBlockedList: isOn,
                windowUUID: windowUUID,
                actionType: WebCompatReporterViewActionType.toggleBlockedList
            ))
        default:
            break
        }
    }

    func webCompatReportSheetDidTapButton(id: String) {
        guard WebCompatReportViewModelMapper.RowID(rawValue: id) == .send else { return }
        store.dispatch(WebCompatReporterViewAction(
            windowUUID: windowUUID,
            actionType: WebCompatReporterViewActionType.submit
        ))
    }

    func webCompatReportSheetDidTapLearnMore() {
        reportCoordinator?.webCompatReportViewControllerDidTapLearnMore()
    }

    // MARK: - Themeable

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
        navigationBar.tintColor = theme.colors.actionPrimary
        sheetViewController.applyTheme(theme: theme)
    }
}
