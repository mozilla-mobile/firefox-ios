// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if DEBUG
import Common
import ComponentLibrary
import SwiftUI
import UIKit

/// Hosts the viewer over a stand-in page: heading, image block, filler lines.
///
/// The page is drawn the way a website would render, so its colours are the page's own and
/// deliberately not the app theme — a real capture doesn't follow the theme either.
private struct FullPageScreenshotPreview: UIViewControllerRepresentable {
    enum PageLength: CGFloat {
        case short = 400
        case tall = 2400
        /// Past the point where the rail runs out of vertical room.
        case long = 8000
    }

    private enum UX {
        static let pageWidth: CGFloat = 320
        static let horizontalInset: CGFloat = 16

        enum Title {
            static let top: CGFloat = 24
            static let fontSize: CGFloat = 28
        }

        enum ImageBlock {
            static let top: CGFloat = 72
            static let height: CGFloat = 180
            static let cornerRadius: CGFloat = 8
            static let color = UIColor.systemBrown
        }

        enum TextLine {
            static let top: CGFloat = 280
            static let height: CGFloat = 10
            static let spacing: CGFloat = 26
            static let cornerRadius: CGFloat = 3
            static let opacity: CGFloat = 0.12
        }
    }

    let pageLength: PageLength

    func makeUIViewController(context: Context) -> WebCompatFullPageScreenshotViewController {
        return WebCompatFullPageScreenshotViewController(
            image: samplePage(),
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

    private func samplePage() -> UIImage {
        let size = CGSize(width: UX.pageWidth, height: pageLength.rawValue)
        let contentWidth = size.width - UX.horizontalInset * 2
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            "Croque Monsieur".draw(
                at: CGPoint(x: UX.horizontalInset, y: UX.Title.top),
                withAttributes: [
                    .font: UIFont.boldSystemFont(ofSize: UX.Title.fontSize),
                    .foregroundColor: UIColor.black
                ]
            )

            UX.ImageBlock.color.setFill()
            UIBezierPath(
                roundedRect: CGRect(
                    x: UX.horizontalInset,
                    y: UX.ImageBlock.top,
                    width: contentWidth,
                    height: UX.ImageBlock.height
                ),
                cornerRadius: UX.ImageBlock.cornerRadius
            ).fill()

            UIColor.black.withAlphaComponent(UX.TextLine.opacity).setFill()
            var lineY = UX.TextLine.top
            while lineY + UX.TextLine.height < size.height {
                UIBezierPath(
                    roundedRect: CGRect(
                        x: UX.horizontalInset,
                        y: lineY,
                        width: contentWidth,
                        height: UX.TextLine.height
                    ),
                    cornerRadius: UX.TextLine.cornerRadius
                ).fill()
                lineY += UX.TextLine.spacing
            }
        }
    }
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
