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
    /// Report was sent; the coordinator dismisses and confirms it.
    func webCompatReportViewControllerDidSubmit()
    /// User tapped the "Learn More…" link; the coordinator shows the explainer page without dismissing the sheet.
    func webCompatReportViewControllerDidTapLearnMore(url: URL)
    /// The middleware assembled the report; the coordinator presents it.
    func webCompatReportViewControllerDidTapPreview(payload: WebCompatReportPayload)
}

/// Store-connected container that hosts the `WebCompatReporterKit` sheet, maps
/// `WebCompatReporterState` to its view model, and forwards its intents to Redux
/// and the coordinator.
final class WebCompatReportViewController: UINavigationController,
                                           StoreSubscriber,
                                           Themeable,
                                           UIAdaptivePresentationControllerDelegate,
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
        presentationController?.delegate = self
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
        guard !state.shouldDismiss else {
            reportCoordinator?.webCompatReportViewControllerDidSubmit()
            return
        }
        if let payload = state.previewPayload {
            reportCoordinator?.webCompatReportViewControllerDidTapPreview(payload: payload)
        }
        sheetViewController.configure(with: WebCompatReportViewController.makeViewModel(from: state))
    }

    // MARK: - View model

    private static func makeViewModel(from state: WebCompatReporterState) -> WebCompatReportViewModel {
        return WebCompatReportViewModel(
            navigationTitle: .MainMenu.ToolsSection.ReportBrokenSite,
            closeButtonAccessibilityLabel: .WebCompatReporter.Sheet.CloseButtonAccessibilityLabel,
            previewButtonTitle: .WebCompatReporter.Sheet.PreviewButton,
            isPreviewEnabled: state.canPreview,
            sections: makeSections(from: state)
        )
    }

    private enum SectionID: String {
        case url
        case issueCategory
        case issueSubOptions
        case additionalDetails
        case advancedOptions
        case send
    }

    private enum RowID: String {
        case url
        case additionalDetails
        case includeScreenshot
        case includeBlockedList
        case send
    }

    static func makeSections(
        from state: WebCompatReporterState
    ) -> [WebCompatReportViewModel.Section] {
        var sections = [urlSection(from: state)]
        sections.append(contentsOf: makeIssueSections(from: state))
        if state.showsAdditionalDetails {
            sections.append(detailsSection(from: state))
        }
        sections.append(advancedOptionsSection(from: state))
        sections.append(sendSection(from: state))
        return sections
    }

    private static func urlSection(from state: WebCompatReporterState) -> WebCompatReportViewModel.Section {
        return WebCompatReportViewModel.Section(
            id: SectionID.url.rawValue,
            rows: [
                WebCompatReportViewModel.Row(
                    id: RowID.url.rawValue,
                    title: .WebCompatReporter.Fields.URLLabel,
                    kind: .urlField(
                        text: state.url,
                        errorMessage: state.showsURLError ? .WebCompatReporter.Fields.URLError : nil
                    ),
                    a11yIdentifier: AccessibilityIdentifiers.WebCompatReporter.urlField
                )
            ]
        )
    }

    private static func detailsSection(from state: WebCompatReporterState) -> WebCompatReportViewModel.Section {
        return WebCompatReportViewModel.Section(
            id: SectionID.additionalDetails.rawValue,
            rows: [
                WebCompatReportViewModel.Row(
                    id: RowID.additionalDetails.rawValue,
                    title: .WebCompatReporter.Fields.DetailsPlaceholder,
                    kind: .detailsField(
                        text: state.additionalDetails,
                        placeholder: .WebCompatReporter.Fields.DetailsPlaceholder
                    ),
                    a11yIdentifier: AccessibilityIdentifiers.WebCompatReporter.additionalDetails
                )
            ]
        )
    }

    private static func advancedOptionsSection(
        from state: WebCompatReporterState
    ) -> WebCompatReportViewModel.Section {
        return WebCompatReportViewModel.Section(
            id: SectionID.advancedOptions.rawValue,
            title: .WebCompatReporter.AdditionalInfo.Title,
            footer: learnMoreFooter(),
            // The screenshot row is parked (FXIOS-16450): the image has no transport yet.
            rows: [
                WebCompatReportViewModel.Row(
                    id: RowID.includeBlockedList.rawValue,
                    title: .WebCompatReporter.AdditionalInfo.IncludeBlockedList,
                    kind: .checkbox(isChecked: state.includeBlockedList),
                    a11yIdentifier: AccessibilityIdentifiers.WebCompatReporter.includeBlockedList
                )
            ]
        )
    }

    private static func learnMoreFooter() -> WebCompatReportViewModel.Footer {
        let linkText: String = .WebCompatReporter.AdditionalInfo.LearnMore
        return WebCompatReportViewModel.Footer(
            text: String(
                format: .WebCompatReporter.AdditionalInfo.FooterText,
                AppName.shortName.rawValue,
                linkText
            ),
            linkText: linkText,
            linkURL: SupportUtils.URLForTopic("report-broken-site"),
            linkA11yIdentifier: AccessibilityIdentifiers.WebCompatReporter.learnMore
        )
    }

    private static func sendSection(from state: WebCompatReporterState) -> WebCompatReportViewModel.Section {
        return WebCompatReportViewModel.Section(
            id: SectionID.send.rawValue,
            rows: [
                WebCompatReportViewModel.Row(
                    id: RowID.send.rawValue,
                    title: .WebCompatReporter.SendButton.Title,
                    kind: .sendButton(isEnabled: state.canSubmit),
                    a11yIdentifier: AccessibilityIdentifiers.WebCompatReporter.sendButton
                )
            ]
        )
    }

    static func makeIssueSections(
        from state: WebCompatReporterState
    ) -> [WebCompatReportViewModel.Section] {
        let options = WebCompatIssueCategory.allCases.map { category in
            WebCompatReportViewModel.Row.MenuOption(
                id: category.id,
                title: title(for: category),
                isSelected: category == state.selectedCategory
            )
        }
        let selectedTitle = state.selectedCategory.map(title(for:))
        let categorySection = WebCompatReportViewModel.Section(
            id: SectionID.issueCategory.rawValue,
            title: .WebCompatReporter.IssueSection.Title,
            rows: [
                WebCompatReportViewModel.Row(
                    id: SectionID.issueCategory.rawValue,
                    title: selectedTitle ?? .WebCompatReporter.IssueSection.CategoryPlaceholder,
                    kind: .categoryMenu(isPlaceholder: selectedTitle == nil, options: options),
                    a11yIdentifier: AccessibilityIdentifiers.WebCompatReporter.categoryMenu
                )
            ]
        )

        guard let selectedCategory = state.selectedCategory,
              !selectedCategory.subOptions.isEmpty else {
            return [categorySection]
        }

        let subOptionRows = selectedCategory.subOptions.map { subOption in
            WebCompatReportViewModel.Row(
                id: subOption.rawValue,
                title: title(for: subOption),
                kind: .subOption(isSelected: subOption.rawValue == state.selectedSubOptionID),
                a11yIdentifier: "\(AccessibilityIdentifiers.WebCompatReporter.subOption).\(subOption.rawValue)"
            )
        }
        let subOptionSection = WebCompatReportViewModel.Section(
            id: SectionID.issueSubOptions.rawValue,
            rows: subOptionRows
        )
        return [categorySection, subOptionSection]
    }

    // MARK: - Enum → localized title

    private static func title(for category: WebCompatIssueCategory) -> String {
        switch category {
        case .siteNotUsable: return .WebCompatReporter.Category.SiteNotUsable
        case .designBroken: return .WebCompatReporter.Category.DesignBroken
        case .videoOrAudio: return .WebCompatReporter.Category.VideoOrAudio
        case .other: return .WebCompatReporter.Category.Other
        }
    }

    private static func title(for subOption: WebCompatSubOption) -> String {
        switch subOption {
        case .browserBlocked: return .WebCompatReporter.SubOption.BrowserBlocked
        case .pageNotLoading: return .WebCompatReporter.SubOption.PageNotLoading
        case .missingItems: return .WebCompatReporter.SubOption.MissingItems
        case .buttonsNotWorking: return .WebCompatReporter.SubOption.ButtonsNotWorking
        case .imagesNotLoaded: return .WebCompatReporter.SubOption.ImagesNotLoaded
        case .itemsOverlapped: return .WebCompatReporter.SubOption.ItemsOverlapped
        case .itemsMisaligned: return .WebCompatReporter.SubOption.ItemsMisaligned
        case .itemsNotVisible: return .WebCompatReporter.SubOption.ItemsNotVisible
        case .noVideo: return .WebCompatReporter.SubOption.NoVideo
        case .noAudio: return .WebCompatReporter.SubOption.NoAudio
        case .mediaControlsBroken: return .WebCompatReporter.SubOption.MediaControlsBroken
        case .playbackFails: return .WebCompatReporter.SubOption.PlaybackFails
        case .captionsMissing: return .WebCompatReporter.SubOption.CaptionsMissing
        }
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    /// UIKit calls this only for the interactive swipe, not for programmatic dismissal.
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        store.dispatch(WebCompatReporterViewAction(
            windowUUID: windowUUID,
            actionType: WebCompatReporterViewActionType.cancel
        ))
    }

    /// Kept here so the cancel action is dispatched from the one place that talks to the store.
    func finishReport() {
        store.dispatch(WebCompatReporterViewAction(
            windowUUID: windowUUID,
            actionType: WebCompatReporterViewActionType.cancel
        ))
        reportCoordinator?.webCompatReportViewControllerDidFinish()
    }

    // MARK: - WebCompatReportSheetDelegate

    func webCompatReportSheetDidTapClose() {
        finishReport()
    }

    func webCompatReportSheetDidTapPreview() {
        // The report comes back through newState, not from here.
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

    func webCompatReportSheetDidTapButton(id: String) {
        guard RowID(rawValue: id) == .send else { return }
        store.dispatch(WebCompatReporterViewAction(
            windowUUID: windowUUID,
            actionType: WebCompatReporterViewActionType.submit
        ))
    }

    func webCompatReportSheetDidToggleCheckbox(id: String, isChecked: Bool) {
        switch RowID(rawValue: id) {
        case .includeScreenshot:
            store.dispatch(WebCompatReporterViewAction(
                includeScreenshot: isChecked,
                windowUUID: windowUUID,
                actionType: WebCompatReporterViewActionType.toggleScreenshot
            ))
        case .includeBlockedList:
            store.dispatch(WebCompatReporterViewAction(
                includeBlockedList: isChecked,
                windowUUID: windowUUID,
                actionType: WebCompatReporterViewActionType.toggleBlockedList
            ))
        case .url, .additionalDetails, .send, .none:
            break
        }
    }

    func webCompatReportSheetDidEditText(id: String, text: String) {
        switch RowID(rawValue: id) {
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
        case .includeScreenshot, .includeBlockedList, .send, .none:
            break
        }
    }

    func webCompatReportSheetDidTapLearnMore(url: URL) {
        store.dispatch(WebCompatReporterViewAction(
            windowUUID: windowUUID,
            actionType: WebCompatReporterViewActionType.learnMore
        ))
        reportCoordinator?.webCompatReportViewControllerDidTapLearnMore(url: url)
    }

    // MARK: - Themeable

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
        navigationBar.tintColor = theme.colors.actionPrimary
        sheetViewController.applyTheme(theme: theme)
    }
}
