// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared
import UIKit
import WebCompatReporterKit

/// What the coordinator needs to build and present the preview: the report
/// payload plus the user's advanced-toggle choices.
struct WebCompatPreviewRequest {
    let payload: WebCompatReportPayload
    let includeScreenshot: Bool
    let includeBlockedList: Bool
}

@MainActor
protocol WebCompatReportCoordinatorDelegate: AnyObject {
    /// Sheet asked to finish; the coordinator owns the dismissal.
    func webCompatReportViewControllerDidFinish()
    /// User tapped the "Learn More…" link; the coordinator opens the explainer page.
    func webCompatReportViewControllerDidTapLearnMore()
    /// User tapped "Preview"; the coordinator enriches the payload with device/tab
    /// data, captures the full-page screenshot, and presents the preview sheet over the form.
    func webCompatReportViewControllerDidTapPreview(_ request: WebCompatPreviewRequest)
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
    private var currentState: WebCompatReporterState

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
        self.currentState = initialState
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
        currentState = state
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
        // Only show details once a category is selected.
        if state.selectedCategory != nil {
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
                    kind: .urlField(text: state.url, placeholder: .WebCompatReporter.Fields.URLPlaceholder)
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
                    title: .WebCompatReporter.Fields.DetailsAccessibilityLabel,
                    kind: .detailsField(
                        text: state.additionalDetails,
                        placeholder: .WebCompatReporter.Fields.DetailsPlaceholder
                    )
                )
            ]
        )
    }

    private static func advancedOptionsSection(
        from state: WebCompatReporterState
    ) -> WebCompatReportViewModel.Section {
        let learnMore: String = .WebCompatReporter.AdditionalInfo.LearnMore
        let footerText = String(
            format: .WebCompatReporter.AdditionalInfo.FooterText,
            AppName.shortName.rawValue,
            learnMore
        )
        return WebCompatReportViewModel.Section(
            id: SectionID.advancedOptions.rawValue,
            title: .WebCompatReporter.AdditionalInfo.Title,
            footer: WebCompatReportViewModel.Footer(text: footerText, linkText: learnMore),
            rows: [
                WebCompatReportViewModel.Row(
                    id: RowID.includeScreenshot.rawValue,
                    title: .WebCompatReporter.AdditionalInfo.IncludeScreenshot,
                    kind: .toggle(isOn: state.includeScreenshot)
                ),
                WebCompatReportViewModel.Row(
                    id: RowID.includeBlockedList.rawValue,
                    title: .WebCompatReporter.AdditionalInfo.IncludeBlockedList,
                    kind: .toggle(isOn: state.includeBlockedList)
                )
            ]
        )
    }

    private static func sendSection(from state: WebCompatReporterState) -> WebCompatReportViewModel.Section {
        return WebCompatReportViewModel.Section(
            id: SectionID.send.rawValue,
            rows: [
                WebCompatReportViewModel.Row(
                    id: RowID.send.rawValue,
                    title: .WebCompatReporter.SendButton.Title,
                    kind: .sendButton(isEnabled: state.canSubmit)
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
                    kind: .categoryMenu(isPlaceholder: selectedTitle == nil, options: options)
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
                kind: .subOption(isSelected: subOption.rawValue == state.selectedSubOptionID)
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

    // MARK: - Preview view model

    /// Projects the report payload onto the store-agnostic preview view model.
    /// Sections/keys come from `WebCompatReportPayload` (aligned to the Glean
    /// `broken-site-report` metrics) — the same model the send code will submit —
    /// so the preview never hand-types field names. Not-yet-collected fields
    /// (native = FXIOS-16183, JS = FXIOS-16184, screenshot = FXIOS-16185) show as
    /// `null`. A plain-language presentation is a follow-up.
    static func makePreviewViewModel(payload: WebCompatReportPayload) -> WebCompatReportPreviewViewModel {
        let sections = payload.previewGroups.map { group in
            WebCompatReportPreviewViewModel.PreviewSection(
                id: group.title,
                title: group.title,
                rows: group.fields.map { field in
                    WebCompatReportPreviewViewModel.PreviewRow(
                        id: "\(group.title).\(field.key)",
                        label: field.key,
                        value: field.value
                    )
                }
            )
        }
        return WebCompatReportPreviewViewModel(
            title: .WebCompatReporter.Preview.Title,
            closeAccessibilityLabel: .WebCompatReporter.Sheet.CloseButtonAccessibilityLabel,
            screenshotAccessibilityLabel: .WebCompatReporter.Preview.ScreenshotAccessibilityLabel,
            screenshot: nil,
            sections: sections
        )
    }

    static func makePreviewViewModel(from state: WebCompatReporterState) -> WebCompatReportPreviewViewModel {
        return makePreviewViewModel(payload: WebCompatReportPayload.make(from: state))
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
        let payload = WebCompatReportPayload.make(from: currentState)
        // Keep dispatching for telemetry (FXIOS-16187); the coordinator presents the screen.
        store.dispatch(WebCompatReporterViewAction(
            windowUUID: windowUUID,
            actionType: WebCompatReporterViewActionType.preview
        ))
        // The coordinator enriches the payload with device/tab data and captures
        // the full-page screenshot (it owns the tab); the VC only knows Redux state.
        reportCoordinator?.webCompatReportViewControllerDidTapPreview(
            WebCompatPreviewRequest(
                payload: payload,
                includeScreenshot: currentState.includeScreenshot,
                includeBlockedList: currentState.includeBlockedList
            )
        )
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
        default:
            break
        }
    }

    func webCompatReportSheetDidToggle(id: String, isOn: Bool) {
        switch RowID(rawValue: id) {
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
        guard RowID(rawValue: id) == .send else { return }
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
