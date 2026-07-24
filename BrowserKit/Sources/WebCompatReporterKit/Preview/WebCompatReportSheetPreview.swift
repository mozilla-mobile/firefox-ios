// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if DEBUG
import Common
import SwiftUI
import UIKit

@MainActor
private func previewSheet(
    sections: [WebCompatReportViewModel.Section],
    isPreviewEnabled: Bool
) -> UIViewController {
    let viewModel = WebCompatReportViewModel(
        navigationTitle: "Report Broken Site",
        closeButtonAccessibilityLabel: "Close",
        previewButtonTitle: "Preview",
        isPreviewEnabled: isPreviewEnabled,
        sections: sections
    )
    let sheet = WebCompatReportSheetViewController(viewModel: viewModel, theme: LightTheme())
    return UINavigationController(rootViewController: sheet)
}

private func previewURLSection() -> WebCompatReportViewModel.Section {
    return WebCompatReportViewModel.Section(id: "url", rows: [
        WebCompatReportViewModel.Row(
            id: "url",
            title: "URL",
            kind: .urlField(text: "https://houseandhome.com/recipe/croque-monsieur", placeholder: "Website address"),
            a11yIdentifier: "url"
        )
    ])
}

private func previewCategoryOptions(selectedID: String?) -> [WebCompatReportViewModel.Row.MenuOption] {
    return [
        ("siteNotUsable", "Site is not usable"),
        ("designBroken", "Design is broken"),
        ("videoOrAudio", "Video or audio does not play"),
        ("other", "Other")
    ].map { id, title in
        WebCompatReportViewModel.Row.MenuOption(id: id, title: title, isSelected: id == selectedID)
    }
}

private func previewCategorySection(selectedTitle: String?) -> WebCompatReportViewModel.Section {
    let selectedID = selectedTitle == nil ? nil : "siteNotUsable"
    return WebCompatReportViewModel.Section(
        id: "issue-category",
        title: "Site Issue",
        rows: [
            WebCompatReportViewModel.Row(
                id: "issue-category",
                title: selectedTitle ?? "Choose issue type…",
                kind: .categoryMenu(
                    isPlaceholder: selectedTitle == nil,
                    options: previewCategoryOptions(selectedID: selectedID)
                ),
                a11yIdentifier: "issue-category"
            )
        ]
    )
}

private func previewSubOption(_ id: String, _ title: String, selected: Bool = false)
-> WebCompatReportViewModel.Row {
    return WebCompatReportViewModel.Row(id: id, title: title, kind: .subOption(isSelected: selected), a11yIdentifier: id)
}

private func previewDetailsSection() -> WebCompatReportViewModel.Section {
    return WebCompatReportViewModel.Section(id: "details", rows: [
        WebCompatReportViewModel.Row(
            id: "details",
            title: "Describe the issue in detail",
            kind: .detailsField(
                text: "The recipe images never load on this page.",
                placeholder: "Describe the issue in detail (optional)"
            ),
            a11yIdentifier: "details"
        )
    ])
}

private func previewAdvancedSection(includeScreenshot: Bool, includeBlockedList: Bool)
-> WebCompatReportViewModel.Section {
    return WebCompatReportViewModel.Section(
        id: "advanced",
        title: "Additional Info",
        footer: WebCompatReportViewModel.Footer(
            text: "Your report helps us understand and fix issues in Firefox to make it better for everyone. Learn More",
            linkText: "Learn More",
            linkURL: URL(string: "https://support.mozilla.org/kb/report-site-issues-firefox-ios"),
            linkA11yIdentifier: "learn-more"
        ),
        rows: [
            WebCompatReportViewModel.Row(
                id: "screenshot",
                title: "Automatically include a screenshot to show the problem",
                kind: .toggle(isOn: includeScreenshot),
                a11yIdentifier: "screenshot"
            ),
            WebCompatReportViewModel.Row(
                id: "blocklist",
                title: "Send list of items blocked by tracking protection",
                kind: .toggle(isOn: includeBlockedList),
                a11yIdentifier: "blocklist"
            )
        ]
    )
}

private func previewSendSection(isEnabled: Bool) -> WebCompatReportViewModel.Section {
    return WebCompatReportViewModel.Section(id: "send", rows: [
        WebCompatReportViewModel.Row(
            id: "send",
            title: "Send Report",
            kind: .sendButton(isEnabled: isEnabled),
            a11yIdentifier: "send"
        )
    ])
}

@available(iOS 17.0, *)
#Preview("Filled") {
    previewSheet(sections: [
        previewURLSection(),
        previewCategorySection(selectedTitle: "Site is not usable"),
        WebCompatReportViewModel.Section(id: "issue-suboptions", rows: [
            previewSubOption("browser_blocked", "Browser is blocked or unsupported"),
            previewSubOption("page_not_loading", "Page not loading correctly", selected: true),
            previewSubOption("missing_items", "Missing items"),
            previewSubOption("buttons_not_working", "Buttons or links not working")
        ]),
        previewDetailsSection(),
        previewAdvancedSection(includeScreenshot: true, includeBlockedList: true),
        previewSendSection(isEnabled: true)
    ], isPreviewEnabled: true)
}

@available(iOS 17.0, *)
#Preview("Empty / Send disabled") {
    previewSheet(sections: [
        previewURLSection(),
        previewCategorySection(selectedTitle: nil),
        previewAdvancedSection(includeScreenshot: true, includeBlockedList: false),
        previewSendSection(isEnabled: false)
    ], isPreviewEnabled: false)
}
#endif
