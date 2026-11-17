// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

final class TabCellCustomImage: UIImageView {
    private var lastBounds: CGRect = .zero
    private var lastImageSize: CGSize = .zero
    private var lastUsesTopAlignment: Bool?

    override var image: UIImage? {
        didSet { setNeedsLayout() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .scaleAspectFill
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Used to display an image content starting from the top left corner instead of image center
    override func layoutSubviews() {
        super.layoutSubviews()

        let usesTopAlignment = traitCollection.horizontalSizeClass == .regular &&
            traitCollection.verticalSizeClass == .regular
        guard let image = image,
              bounds != lastBounds || image.size != lastImageSize || usesTopAlignment != lastUsesTopAlignment
        else { return }

        lastBounds = bounds
        lastImageSize = image.size
        lastUsesTopAlignment = usesTopAlignment

        if usesTopAlignment {
            updateContentsRect(for: image)
        } else {
            layer.contentsRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsLayout()
    }

    private func updateContentsRect(for image: UIImage) {
        let viewSize = bounds.size
        let imageSize = image.size

        let scale = max(
            viewSize.width / imageSize.width,
            viewSize.height / imageSize.height
        )

        let scaledHeight = imageSize.height * scale
        let cropHeight = viewSize.height / scaledHeight

        layer.contentsRect = CGRect(x: 0, y: 0, width: 1, height: cropHeight)
    }
}
