// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if DEBUG
import Common
import SwiftUI
import UIKit

/// Plain literals, so the canvas doesn't depend on the Client. The shipping copy arrives through
/// the view model.
private struct WebCompatReportPreviewHost: UIViewControllerRepresentable {
    let screenshot: UIImage?
    var themeType: ThemeType = .light
    /// Trimmed so the Technical Data row lands above the fold.
    var bulletLimit: Int?

    func makeUIViewController(context: Context) -> UINavigationController {
        let viewModel = WebCompatReportPreviewViewModel(
            title: "Report Preview",
            closeAccessibilityLabel: "Close",
            closeA11yIdentifier: "WebCompatReporter.Preview.Close",
            screenshotAccessibilityLabel: "Screenshot of the page you are reporting",
            screenshotA11yIdentifier: "WebCompatReporter.Preview.Screenshot",
            bullets: bulletLimit.map { Array(Self.sampleBullets.prefix($0)) } ?? Self.sampleBullets,
            bulletsA11yIdentifier: "WebCompatReporter.Preview.Bullets",
            technicalDataTitle: "Technical Data",
            technicalDataA11yIdentifier: "WebCompatReporter.Preview.TechnicalData"
        )
        // The screen reads colours from the manager, so the canvas appearance alone can't darken it.
        let themeManager = DefaultThemeManager(sharedContainerIdentifier: "")
        themeManager.setSystemTheme(isOn: false)
        themeManager.setManualTheme(to: themeType)
        let controller = WebCompatReportPreviewViewController(
            viewModel: viewModel,
            windowUUID: .DefaultUITestingUUID,
            themeManager: themeManager
        )
        controller.updateScreenshot(screenshot)
        let navigationController = UINavigationController(rootViewController: controller)
        // Matches the nav bar the coordinator sets up in the app.
        navigationController.navigationBar.prefersLargeTitles = false
        return navigationController
    }

    func updateUIViewController(_ navigationController: UINavigationController, context: Context) {}

    private static let sampleBulletTexts = [
        // A line separator, not a newline: same paragraph, so it keeps the hanging indent and
        // skips the inter-bullet gap.
        "Page URL\u{2028}[https://www.highsnobiety.com/p/why-do-we-destroy-good-brands-the-row-sample-sale/]",
        "Device make, model, and manufacturer",
        "Operating system version number",
        "App version number",
        "Anonymous experiment groups for feature testing",
        "Information about which versions of our protections were active",
        "Web browser engine version number",
        "List of which browser features were active",
        "Hostnames of trackers blocked, surrogate requests, ignored requests, and requests not in "
            + "tracker blocking list",
        "Browser-reported errors",
        "Website response status (HTTP) codes",
        "Date of last report sent for this site",
        "How quickly parts of the page loaded",
        "How you got to this page, either: \u{201C}SERP\u{201D} (Google search), "
            + "\u{201C}Navigation\u{201D} (link/URL), or \u{201C}External\u{201D} (other means)",
        "Number of refreshed since page load",
        "Primary language and country of your device",
        "Information about page elements that have been known to cause site issues"
    ]

    private static let sampleBullets: [WebCompatReportPreviewViewModel.Bullet] =
        sampleBulletTexts.enumerated().map { index, text in
            WebCompatReportPreviewViewModel.Bullet(
                id: "WebCompatReporter.Preview.Bullet.\(index)",
                text: text
            )
        }
}

private func previewSampleScreenshot() -> UIImage {
    return WebCompatPreviewSamplePage.image(height: 1400)
}

@available(iOS 17.0, *)
#Preview("With screenshot") {
    WebCompatReportPreviewHost(screenshot: previewSampleScreenshot())
        .ignoresSafeArea()
}

@available(iOS 17.0, *)
#Preview("Technical Data row") {
    WebCompatReportPreviewHost(screenshot: previewSampleScreenshot(), bulletLimit: 4)
        .ignoresSafeArea()
}

@available(iOS 17.0, *)
#Preview("Screenshot off") {
    WebCompatReportPreviewHost(screenshot: nil)
        .ignoresSafeArea()
}

@available(iOS 17.0, *)
#Preview("With screenshot (dark)") {
    WebCompatReportPreviewHost(screenshot: previewSampleScreenshot(), themeType: .dark)
        .ignoresSafeArea()
}
#endif
