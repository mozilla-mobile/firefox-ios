// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if DEBUG
import Common
import ComponentLibrary
import SwiftUI
import UIKit

/// Hosts the viewer over `WebCompatPreviewSamplePage`.
private struct FullPageScreenshotPreview: UIViewControllerRepresentable {
    enum PageLength: CGFloat {
        case short = 400
        case tall = 2400
        /// Past the point where the rail runs out of vertical room.
        case long = 8000
    }

    let pageLength: PageLength

    func makeUIViewController(context: Context) -> WebCompatFullPageScreenshotViewController {
        return WebCompatFullPageScreenshotViewController(
            image: WebCompatPreviewSamplePage.image(height: pageLength.rawValue),
            viewModel: WebCompatFullPageScreenshotViewModel(
                captureAccessibilityLabel: "Screenshot of the page",
                captureAccessibilityIdentifier: "WebCompatReporter.Preview.ScreenshotCapture"
            ),
            closeButtonViewModel: CloseButtonViewModel(
                a11yLabel: "Close",
                a11yIdentifier: "WebCompatReporter.Preview.ScreenshotClose"
            ),
            windowUUID: .DefaultUITestingUUID,
            themeManager: DefaultThemeManager(sharedContainerIdentifier: "")
        )
    }

    func updateUIViewController(_ viewController: WebCompatFullPageScreenshotViewController, context: Context) {}
}

@available(iOS 17.0, *)
#Preview("Tall page") {
    FullPageScreenshotPreview(pageLength: .tall)
        .ignoresSafeArea()
}

@available(iOS 17.0, *)
#Preview("Short page") {
    FullPageScreenshotPreview(pageLength: .short)
        .ignoresSafeArea()
}

@available(iOS 17.0, *)
#Preview("Long page") {
    FullPageScreenshotPreview(pageLength: .long)
        .ignoresSafeArea()
}
#endif
