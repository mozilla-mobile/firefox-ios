// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if DEBUG
import Common
import SwiftUI
import UIKit

/// Hosts the screen over sample sections matching the designed payload view. Plain literals, so
/// the preview doesn't depend on the Client.
private struct WebCompatReportPreviewHost: UIViewControllerRepresentable {
    typealias PreviewRow = WebCompatReportPreviewViewModel.PreviewRow
    typealias PreviewSection = WebCompatReportPreviewViewModel.PreviewSection
    typealias PreviewValue = WebCompatReportPreviewViewModel.PreviewValue

    let theme: Theme

    func makeUIViewController(context: Context) -> UINavigationController {
        let viewModel = WebCompatReportPreviewViewModel(
            title: "Report Preview",
            closeAccessibilityLabel: "Close",
            closeA11yIdentifier: "WebCompatReporter.Preview.Close",
            sections: Self.sampleSections
        )
        let controller = WebCompatReportPreviewViewController(viewModel: viewModel, theme: theme)
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

@available(iOS 17.0, *)
#Preview("Raw payload") {
    WebCompatReportPreviewHost(theme: LightTheme())
        .ignoresSafeArea()
}

@available(iOS 17.0, *)
#Preview("Raw payload (dark)") {
    WebCompatReportPreviewHost(theme: DarkTheme())
        .ignoresSafeArea()
}
#endif
