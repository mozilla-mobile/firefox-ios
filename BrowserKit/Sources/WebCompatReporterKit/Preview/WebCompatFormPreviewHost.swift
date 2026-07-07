// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if DEBUG
import Common
import UIKit

/// A category and its sub-options, mirroring the Client's `WebCompatIssueCategory`
/// with literal copy so the package preview stays store-agnostic.
struct WebCompatPreviewCategory {
    let id: String
    let title: String
    let subOptions: [(id: String, title: String)]
}

let webCompatPreviewCategories: [WebCompatPreviewCategory] = [
    WebCompatPreviewCategory(id: "siteNotUsable", title: "Site is not usable", subOptions: [
        (id: "browser_blocked", title: "Browser is blocked or unsupported"),
        (id: "page_not_loading", title: "Page not loading correctly"),
        (id: "missing_items", title: "Missing items"),
        (id: "buttons_not_working", title: "Buttons or links not working")
    ]),
    WebCompatPreviewCategory(id: "designBroken", title: "Design is broken", subOptions: [
        (id: "images_not_loaded", title: "Images not loaded"),
        (id: "items_overlapped", title: "Items are overlapped"),
        (id: "items_misaligned", title: "Items are misaligned"),
        (id: "items_not_visible", title: "Items not fully visible")
    ]),
    WebCompatPreviewCategory(id: "videoOrAudio", title: "Video or audio does not play", subOptions: [
        (id: "no_video", title: "There is no video"),
        (id: "no_audio", title: "There is no audio"),
        (id: "media_controls_broken", title: "Media controls are broken or missing"),
        (id: "playback_fails", title: "The video or audio does not play"),
        (id: "captions_missing", title: "Captions are missing")
    ]),
    WebCompatPreviewCategory(id: "other", title: "Other", subOptions: [])
]

/// Preview host that fakes the store loop: holds the draft and reconfigures the
/// sheet on each intent, so the canvas behaves like the connected screen. Lives
/// outside the `#Preview` file so its `super.init` isn't rewritten by design-time
/// instrumentation (which only rewrites the previewed primary file).
final class WebCompatFormPreviewController: UINavigationController, WebCompatReportSheetDelegate {
    private var url: String
    private var selectedCategoryID: String?
    private var selectedSubOptionID: String?
    private var additionalDetails: String
    private var includeScreenshot: Bool
    private var includeBlockedList: Bool

    private lazy var sheet = WebCompatReportSheetViewController(
        viewModel: makeViewModel(),
        theme: LightTheme()
    )

    init(url: String = "",
         selectedCategoryID: String? = nil,
         selectedSubOptionID: String? = nil,
         additionalDetails: String = "",
         includeScreenshot: Bool = true,
         includeBlockedList: Bool = false) {
        self.url = url
        self.selectedCategoryID = selectedCategoryID
        self.selectedSubOptionID = selectedSubOptionID
        self.additionalDetails = additionalDetails
        self.includeScreenshot = includeScreenshot
        self.includeBlockedList = includeBlockedList
        super.init(nibName: nil, bundle: nil)
        setViewControllers([sheet], animated: false)
        sheet.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makeViewModel() -> WebCompatReportViewModel {
        let selected = webCompatPreviewCategories.first { $0.id == selectedCategoryID }
        let options = webCompatPreviewCategories.map {
            WebCompatReportViewModel.Row.MenuOption(id: $0.id, title: $0.title, isSelected: $0.id == selectedCategoryID)
        }

        var sections = [
            WebCompatReportViewModel.Section(id: "url", rows: [
                WebCompatReportViewModel.Row(
                    id: "url",
                    title: "URL",
                    kind: .urlField(text: url, placeholder: "Website address")
                )
            ]),
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

        if selected != nil {
            sections.append(WebCompatReportViewModel.Section(id: "details", rows: [
                WebCompatReportViewModel.Row(
                    id: "details",
                    title: "Describe the issue in detail",
                    kind: .detailsField(text: additionalDetails, placeholder: "Describe the issue in detail (optional)")
                )
            ]))
        }

        sections.append(WebCompatReportViewModel.Section(
            id: "advanced",
            title: "Additional Info",
            footer: WebCompatReportViewModel.Footer(
                text: "Your report helps us understand and fix issues in Firefox to make it better for everyone. Learn More",
                linkText: "Learn More"
            ),
            rows: [
                WebCompatReportViewModel.Row(
                    id: "screenshot",
                    title: "Automatically include a screenshot to show the problem",
                    kind: .toggle(isOn: includeScreenshot)
                ),
                WebCompatReportViewModel.Row(
                    id: "blocklist",
                    title: "Send list of items blocked by tracking protection",
                    kind: .toggle(isOn: includeBlockedList)
                )
            ]
        ))

        sections.append(WebCompatReportViewModel.Section(id: "send", rows: [
            WebCompatReportViewModel.Row(
                id: "send",
                title: "Send Report",
                kind: .sendButton(isEnabled: selectedCategoryID != nil)
            )
        ]))

        return WebCompatReportViewModel(
            navigationTitle: "Report Broken Site",
            closeButtonAccessibilityLabel: "Close",
            previewButtonTitle: "Preview",
            isPreviewEnabled: selectedCategoryID != nil,
            sections: sections
        )
    }

    func webCompatReportSheetDidTapClose() {}
    func webCompatReportSheetDidTapPreview() {}
    func webCompatReportSheetDidTapLearnMore() {}

    func webCompatReportSheetDidSelectCategory(id: String) {
        selectedCategoryID = id
        selectedSubOptionID = nil
        sheet.configure(with: makeViewModel())
    }

    func webCompatReportSheetDidSelectSubOption(id: String) {
        selectedSubOptionID = id
        sheet.configure(with: makeViewModel())
    }

    func webCompatReportSheetDidEditText(id: String, text: String) {
        switch id {
        case "url": url = text
        case "details": additionalDetails = text
        default: break
        }
        sheet.configure(with: makeViewModel())
    }

    func webCompatReportSheetDidToggle(id: String, isOn: Bool) {
        switch id {
        case "screenshot": includeScreenshot = isOn
        case "blocklist": includeBlockedList = isOn
        default: break
        }
        sheet.configure(with: makeViewModel())
    }

    func webCompatReportSheetDidTapButton(id: String) {}
}
#endif
