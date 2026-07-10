// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if DEBUG
import Common
import SwiftUI
import UIKit

/// Preview host for the Report Preview screen: embeds the view controller and,
/// like the real coordinator, presents the full-screen viewer when the
/// thumbnail is tapped. Lives outside the `#Preview` file so its `super.init`
/// isn't rewritten by design-time instrumentation.
final class WebCompatReportPreviewPreviewController: UIViewController, WebCompatReportPreviewDelegate {
    private let showsScreenshot: Bool
    private let theme: Theme = LightTheme()

    private lazy var previewController = WebCompatReportPreviewViewController(
        viewModel: makeViewModel(),
        theme: theme
    )

    init(showsScreenshot: Bool) {
        self.showsScreenshot = showsScreenshot
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        previewController.delegate = self
        // Wrap in a navigation controller so the close/title bar shows, matching
        // how the coordinator presents it.
        let navigationController = UINavigationController(rootViewController: previewController)
        addChild(navigationController)
        navigationController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationController.view)
        NSLayoutConstraint.activate([
            navigationController.view.topAnchor.constraint(equalTo: view.topAnchor),
            navigationController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        navigationController.didMove(toParent: self)
    }

    private func makeViewModel() -> WebCompatReportPreviewViewModel {
        return WebCompatReportPreviewViewModel(
            title: "Report Preview",
            closeAccessibilityLabel: "Close",
            screenshotAccessibilityLabel: "Screenshot of the page you are reporting. Double tap to view full screen.",
            screenshot: showsScreenshot ? webCompatPreviewSampleScreenshot() : nil,
            sections: webCompatPreviewSampleSections
        )
    }

    func webCompatReportPreviewDidTapClose() {
        dismiss(animated: true)
    }

    func webCompatReportPreviewDidTapScreenshot() {
        let viewer = WebCompatScreenshotZoomViewController(
            image: webCompatPreviewSampleScreenshot(),
            closeAccessibilityLabel: "Close",
            theme: theme
        ) { [weak self] in
            self?.dismiss(animated: true)
        }
        present(viewer, animated: true)
    }
}

private func webCompatPreviewSampleSection(
    _ key: String,
    _ fields: [(String, String)]
) -> WebCompatReportPreviewViewModel.PreviewSection {
    return WebCompatReportPreviewViewModel.PreviewSection(
        id: key,
        title: key,
        rows: fields.map { WebCompatReportPreviewViewModel.PreviewRow(id: "\(key).\($0.0)", label: $0.0, value: $0.1) }
    )
}

/// Raw-JSON sample sections mirroring the Figma preview and the Client mapping
/// (report payload grouped by its JSON keys). Store-agnostic literals so the
/// package preview stays independent of the Client.
let webCompatPreviewSampleSections: [WebCompatReportPreviewViewModel.PreviewSection] = [
    webCompatPreviewSampleSection("basic", [
        ("url", "\"https://houseandhome.com/recipe/croque-monsieur\""),
        ("breakage_category", "\"media\""),
        ("description", "\"The recipe images never load on this page.\"")
    ]),
    webCompatPreviewSampleSection("tabInfo", [
        ("languages", "[\"en-US\"]"),
        ("useragent_string", "\"Mozilla/5.0 (iPhone; CPU iPhone OS 26_0…)\"")
    ]),
    webCompatPreviewSampleSection("antitracking", [
        ("block_list", "\"basic\""),
        ("blocked_origins", "null"),
        ("etp_category", "\"standard\""),
        ("is_private_browsing", "false")
    ]),
    webCompatPreviewSampleSection("frameworks", [
        ("fastclick", "false"),
        ("marfeel", "false"),
        ("mobify", "false")
    ]),
    webCompatPreviewSampleSection("app", [
        ("default_locales", "[\"en-US\"]"),
        ("default_useragent_string", "\"Mozilla/5.0 (iPhone…)\"")
    ]),
    webCompatPreviewSampleSection("graphics", [
        ("device_pixel_ratio", "\"3\""),
        ("has_touch_screen", "true")
    ]),
    webCompatPreviewSampleSection("system", [
        ("is_tablet", "false"),
        ("memory", "6144")
    ])
]

/// A tall sample capture drawn once for the thumbnail and viewer previews.
func webCompatPreviewSampleScreenshot() -> UIImage? {
    let size = CGSize(width: 320, height: 1400)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
        UIColor.white.setFill()
        context.fill(CGRect(origin: .zero, size: size))

        let title = "Croque Monsieur"
        title.draw(
            at: CGPoint(x: 16, y: 24),
            withAttributes: [.font: UIFont.boldSystemFont(ofSize: 28), .foregroundColor: UIColor.black]
        )

        UIColor(red: 0.72, green: 0.55, blue: 0.36, alpha: 1).setFill()
        UIBezierPath(
            roundedRect: CGRect(x: 16, y: 72, width: size.width - 32, height: 180),
            cornerRadius: 8
        ).fill()

        UIColor.black.withAlphaComponent(0.12).setFill()
        var lineY: CGFloat = 280
        while lineY < size.height - 20 {
            UIBezierPath(
                roundedRect: CGRect(x: 16, y: lineY, width: size.width - 32, height: 10),
                cornerRadius: 3
            ).fill()
            lineY += 26
        }
    }
}
#endif
