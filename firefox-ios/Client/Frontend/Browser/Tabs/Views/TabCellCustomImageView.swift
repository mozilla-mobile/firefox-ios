// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

final class TabCellCustomImage: UIImageView {
    // Used to display an image content starting from the top left corner instead of image center
    override func layoutSubviews() {
        super.layoutSubviews()

        guard let image = image else { return }

        let viewSize = bounds.size
        let imageSize = image.size

        let scale = max(
            viewSize.width / imageSize.width,
            viewSize.height / imageSize.height
        )

        let scaledHeight = imageSize.height * scale
        let cropHeight = viewSize.height / scaledHeight

        layer.contentsRect = CGRect(x: 0, y: 0, width: 1, height: cropHeight)
        contentMode = .scaleAspectFill
        clipsToBounds = true
    }
}
