// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import WebCompatReporterKit

/// Projects `WebCompatReporterState` onto the store-agnostic `WebCompatReportViewModel`
/// the sheet renders. Pure and stateless. `RowID` is the vocabulary the sheet emits
/// back through its delegate, so the container maps intents to actions with it.
enum WebCompatReportViewModelMapper {
    private enum SectionID: String {
        case url
        case issueCategory
        case issueSubOptions
        case additionalDetails
        case advancedOptions
        case send
    }

    enum RowID: String {
        case url
        case additionalDetails
        case includeScreenshot
        case includeBlockedList
        case send
    }

    static func map(from state: WebCompatReporterState) -> WebCompatReportViewModel {
        return WebCompatReportViewModel(
            navigationTitle: .MainMenu.ToolsSection.ReportBrokenSite,
            closeButtonAccessibilityLabel: .WebCompatReporter.Sheet.CloseButtonAccessibilityLabel,
            previewButtonTitle: .WebCompatReporter.Sheet.PreviewButton,
            isPreviewEnabled: state.canPreview,
            sections: makeSections(from: state)
        )
    }

    static func makeSections(from state: WebCompatReporterState) -> [WebCompatReportViewModel.Section] {
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
        let footerText = String(format: .WebCompatReporter.AdditionalInfo.FooterText, learnMore)
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
}
