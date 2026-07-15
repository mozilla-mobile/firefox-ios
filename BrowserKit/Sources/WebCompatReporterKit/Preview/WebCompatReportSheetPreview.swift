// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if DEBUG
import Common
import SwiftUI
import UIKit

@MainActor
private func previewSheet(sections: [WebCompatReportViewModel.Section]) -> UIViewController {
    let viewModel = WebCompatReportViewModel(
        navigationTitle: "Report a Website Issue",
        closeButtonAccessibilityLabel: "Close",
        previewButtonTitle: "Preview",
        isPreviewEnabled: !sections.isEmpty,
        sections: sections
    )
    let sheet = WebCompatReportSheetViewController(viewModel: viewModel, theme: LightTheme())
    return UINavigationController(rootViewController: sheet)
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
                )
            )
        ]
    )
}

private func previewSubOption(_ id: String, _ title: String, selected: Bool = false)
-> WebCompatReportViewModel.Row {
    return WebCompatReportViewModel.Row(id: id, title: title, kind: .subOption(isSelected: selected))
}

@available(iOS 17.0, *)
#Preview("Placeholder") {
    previewSheet(sections: [previewCategorySection(selectedTitle: nil)])
}

@available(iOS 17.0, *)
#Preview("Category selected") {
    previewSheet(sections: [
        previewCategorySection(selectedTitle: "Site is not usable"),
        WebCompatReportViewModel.Section(id: "issue-suboptions", rows: [
            previewSubOption("browser_blocked", "Browser is blocked or unsupported"),
            previewSubOption("page_not_loading", "Page not loading correctly", selected: true),
            previewSubOption("missing_items", "Missing items"),
            previewSubOption("buttons_not_working", "Buttons or links not working")
        ])
    ])
}
#endif
