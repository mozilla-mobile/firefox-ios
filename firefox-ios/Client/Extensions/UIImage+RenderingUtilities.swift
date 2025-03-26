// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import PDFKit

extension UIImage {
    /// Renders PDF data as a UIImage.
    /// - Parameters:
    ///   - data: the PDF data.
    ///   - targetSize: the target size for the image. Leave nil to use the default.
    ///   - minimumSize: the minimum size for the image. It will be scaled up to this size
    ///   if needed (keeping proportions).
    /// - Returns: an image of the PDF. Returns nil if an issue occurs or the PDF data is invalid.
    static func imageFromPDF(data: Data, targetSize: CGSize? = nil, minimumSize: CGSize? = nil) -> UIImage? {
        guard let document = PDFDocument(data: data), let page = document.page(at: 0) else {
            return nil
        }

        // Get target size for output image
        let pageRect = page.bounds(for: .mediaBox)
        let baseSize = targetSize ?? pageRect.size

        // Scale proportionately to optional minimum size.
        let size: CGSize
        if let minSize = minimumSize {
            let xScaleRatio = minSize.width / baseSize.width
            let yScaleRatio = minSize.height / baseSize.height
            let scaleRatio = max(max(xScaleRatio, yScaleRatio), 1.0)
            size = CGSize(width: baseSize.width * scaleRatio, height: baseSize.height * scaleRatio)
        } else {
            size = baseSize
        }

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cgContext = context.cgContext

            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Coordinate system must be flipped to match PDF rendering
            cgContext.translateBy(x: 0, y: size.height)
            cgContext.scaleBy(x: 1, y: -1)
            page.draw(with: .mediaBox, to: cgContext)
        }
    }
}
