// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if DEBUG
import Common
import SwiftUI
import UIKit

/// A category and its sub-options, mirroring the Client's `WebCompatIssueCategory`
/// with literal copy so the package preview stays store-agnostic.
private struct PreviewCategory {
    let id: String
    let title: String
    let subOptions: [(id: String, title: String)]
}

private let previewCategories: [PreviewCategory] = [
    PreviewCategory(id: "siteNotUsable", title: "Site is not usable", subOptions: [
        (id: "browser_blocked", title: "Browser is blocked or unsupported"),
        (id: "page_not_loading", title: "Page not loading correctly"),
        (id: "missing_items", title: "Missing items"),
        (id: "buttons_not_working", title: "Buttons or links not working")
    ]),
    PreviewCategory(id: "designBroken", title: "Design is broken", subOptions: [
        (id: "images_not_loaded", title: "Images not loaded"),
        (id: "items_overlapped", title: "Items are overlapped"),
        (id: "items_misaligned", title: "Items are misaligned"),
        (id: "items_not_visible", title: "Items not fully visible")
    ]),
    PreviewCategory(id: "videoOrAudio", title: "Video or audio does not play", subOptions: [
        (id: "no_video", title: "There is no video"),
        (id: "no_audio", title: "There is no audio"),
        (id: "media_controls_broken", title: "Media controls are broken or missing"),
        (id: "playback_fails", title: "The video or audio does not play"),
        (id: "captions_missing", title: "Captions are missing")
    ]),
    PreviewCategory(id: "other", title: "Other", subOptions: [])
]

/// Preview host that fakes the store loop: holds the selection and reconfigures
/// the sheet on each intent, so the canvas behaves like the connected screen.
private final class WebCompatPickerPreviewController: UINavigationController, WebCompatReportSheetDelegate {
    private var selectedCategoryID: String?
    private var selectedSubOptionID: String?

    private lazy var sheet = WebCompatReportSheetViewController(
        viewModel: makeViewModel(),
        theme: LightTheme()
    )

    init(selectedCategoryID: String? = nil, selectedSubOptionID: String? = nil) {
        self.selectedCategoryID = selectedCategoryID
        self.selectedSubOptionID = selectedSubOptionID
        super.init(nibName: nil, bundle: nil)
        setViewControllers([sheet], animated: false)
        sheet.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makeViewModel() -> WebCompatReportViewModel {
        let selected = previewCategories.first { $0.id == selectedCategoryID }
        let options = previewCategories.map {
            WebCompatReportViewModel.Row.MenuOption(id: $0.id, title: $0.title, isSelected: $0.id == selectedCategoryID)
        }
        var sections = [
            WebCompatReportViewModel.Section(
                id: "issue-category",
                title: "Site Issue",
                rows: [
                    WebCompatReportViewModel.Row(
                        id: "issue-category",
                        title: selected?.title ?? "Choose issue type…",
                        kind: .categoryMenu(isPlaceholder: selected == nil, options: options)
                    )
                ]
            )
        ]
        if let selected, !selected.subOptions.isEmpty {
            sections.append(WebCompatReportViewModel.Section(
                id: "issue-suboptions",
                rows: selected.subOptions.map {
                    WebCompatReportViewModel.Row(
                        id: $0.id,
                        title: $0.title,
                        kind: .subOption(isSelected: $0.id == selectedSubOptionID)
                    )
                }
            ))
        }
        return WebCompatReportViewModel(
            navigationTitle: "Report a Website Issue",
            closeButtonAccessibilityLabel: "Close",
            previewButtonTitle: "Preview",
            isPreviewEnabled: selectedCategoryID != nil,
            sections: sections
        )
    }

    func webCompatReportSheetDidTapClose() {}
    func webCompatReportSheetDidTapPreview() {}

    func webCompatReportSheetDidSelectCategory(id: String) {
        selectedCategoryID = id
        selectedSubOptionID = nil
        sheet.configure(with: makeViewModel())
    }

    func webCompatReportSheetDidSelectSubOption(id: String) {
        selectedSubOptionID = id
        sheet.configure(with: makeViewModel())
    }
}

@available(iOS 17.0, *)
#Preview("Site Issue picker") {
    WebCompatPickerPreviewController(selectedCategoryID: "siteNotUsable", selectedSubOptionID: "page_not_loading")
}
#endif
