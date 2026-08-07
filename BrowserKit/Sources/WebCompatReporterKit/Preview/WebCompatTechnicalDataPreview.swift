// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if DEBUG
import Common
import SwiftUI
import UIKit

/// Hosts the screen over sample sections matching the designed payload view. Plain literals, so
/// the preview doesn't depend on the Client.
private struct WebCompatTechnicalDataHost: UIViewControllerRepresentable {
    typealias PreviewRow = WebCompatTechnicalDataViewModel.PreviewRow
    typealias PreviewSection = WebCompatTechnicalDataViewModel.PreviewSection
    typealias PreviewValue = WebCompatTechnicalDataViewModel.PreviewValue

    let screenshot: UIImage?
    var themeType: ThemeType = .light

    func makeUIViewController(context: Context) -> UINavigationController {
        let viewModel = WebCompatTechnicalDataViewModel(
            title: "Technical Data",
            closeAccessibilityLabel: "Close",
            closeA11yIdentifier: "WebCompatReporter.Preview.Close",
            screenshotAccessibilityLabel: "Screenshot of the page you are reporting",
            screenshotA11yIdentifier: "WebCompatReporter.Preview.Screenshot",
            sections: Self.sampleSections
        )
        // The screen reads its colors from the manager, so the canvas appearance alone can't
        // darken it; the manager has to be told.
        let themeManager = DefaultThemeManager(sharedContainerIdentifier: "")
        themeManager.setSystemTheme(isOn: false)
        themeManager.setManualTheme(to: themeType)
        let controller = WebCompatTechnicalDataViewController(
            viewModel: viewModel,
            windowUUID: .DefaultUITestingUUID,
            themeManager: themeManager
        )
        controller.updateScreenshot(screenshot)
        return UINavigationController(rootViewController: controller)
    }

    func updateUIViewController(_ navigationController: UINavigationController, context: Context) {}

    private static func section(_ key: String, _ fields: [(String, PreviewValue)]) -> PreviewSection {
        return PreviewSection(
            id: key,
            title: key,
            a11yIdentifier: "WebCompatReporter.Preview.Section.\(key)",
            contentA11yIdentifier: "WebCompatReporter.Preview.Section.\(key).content",
            rows: fields.map { PreviewRow(id: "\(key).\($0.0)", label: $0.0, value: $0.1) }
        )
    }

    private static let sampleSections: [PreviewSection] = [
        section("basic", [
            ("url", .string("https://houseandhome.com/recipe/croque-monsieur")),
            ("breakage_category", .string("images_not_loaded")),
            ("description", .string("The recipe images never load on this page."))
        ]),
        section("tabInfo", [
            ("languages", .list(["en-US"])),
            ("useragent_string", .string("Mozilla/5.0 (iPhone; CPU iPhone OS 26_0…)"))
        ]),
        section("graphics", [
            ("device_pixel_ratio", .quantity(3)),
            ("has_touch_screen", .bool(true))
        ]),
        section("antiTracking", [
            ("block_list", .string("basic")),
            ("blocked_origins", .null),
            ("etp_category", .string("standard")),
            ("is_private_browsing", .bool(false))
        ]),
        section("frameworks", [
            ("fastclick", .bool(false)),
            ("marfeel", .bool(false)),
            ("mobify", .bool(false))
        ]),
        section("browserInfo", [
            ("is_tablet", .bool(false)),
            ("memory", .quantity(6144))
        ]),
        section("app", [
            ("default_locales", .list(["en-US"])),
            ("default_useragent_string", .string("Mozilla/5.0 (iPhone…)"))
        ])
    ]
}

private func previewSampleScreenshot() -> UIImage {
    let size = CGSize(width: 320, height: 1400)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
        UIColor.white.setFill()
        context.fill(CGRect(origin: .zero, size: size))

        "Croque Monsieur".draw(
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

@available(iOS 17.0, *)
#Preview("With screenshot") {
    WebCompatTechnicalDataHost(screenshot: previewSampleScreenshot())
        .ignoresSafeArea()
}

@available(iOS 17.0, *)
#Preview("Screenshot off") {
    WebCompatTechnicalDataHost(screenshot: nil)
        .ignoresSafeArea()
}

@available(iOS 17.0, *)
#Preview("With screenshot (dark)") {
    WebCompatTechnicalDataHost(screenshot: previewSampleScreenshot(), themeType: .dark)
        .ignoresSafeArea()
}
#endif
