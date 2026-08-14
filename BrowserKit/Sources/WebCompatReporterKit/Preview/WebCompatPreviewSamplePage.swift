// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if DEBUG
import UIKit

/// A stand-in captured page for the previews. Its colours are the page's own and deliberately not
/// the app theme, because a real capture doesn't follow the theme either.
enum WebCompatPreviewSamplePage {
    private enum UX {
        static let width: CGFloat = 320
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

    static func image(height: CGFloat) -> UIImage {
        let size = CGSize(width: UX.width, height: height)
        let contentWidth = size.width - UX.horizontalInset * 2
        return UIGraphicsImageRenderer(size: size).image { context in
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
#endif
