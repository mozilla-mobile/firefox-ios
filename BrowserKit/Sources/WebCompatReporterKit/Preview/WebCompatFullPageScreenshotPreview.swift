// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if DEBUG
import Common
import ComponentLibrary
import SwiftUI
import UIKit

@MainActor
private func previewFullPageScreenshot(pageHeight: CGFloat) -> UIViewController {
    return WebCompatFullPageScreenshotViewController(
        image: previewSampleCapture(pageHeight: pageHeight),
        closeButtonViewModel: CloseButtonViewModel(
            a11yLabel: "Close",
            a11yIdentifier: "WebCompatReporter.Preview.ScreenshotClose"
        ),
        theme: LightTheme()
    )
}

/// A stand-in page: heading, image block, filler lines. Enough for the rail and
/// the highlight to track something.
private func previewSampleCapture(pageHeight: CGFloat) -> UIImage {
    let size = CGSize(width: 320, height: pageHeight)
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
#Preview("Tall page") {
    previewFullPageScreenshot(pageHeight: 2400)
}

@available(iOS 17.0, *)
#Preview("Short page") {
    previewFullPageScreenshot(pageHeight: 400)
}
#endif
