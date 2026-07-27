// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit

/// Mirrors the iOS "Full Page" screenshot preview (Figma 23608-67772): the capture
/// scrolls in the middle, a thumbnail of the whole page sits in the right margin
/// with a highlight that follows the scroll.
final class WebCompatFullPageScreenshotView: UIView, ThemeApplicable, UIScrollViewDelegate {
    private enum UX {
        static let topInset: CGFloat = 72
        static let bottomInset: CGFloat = 24
        static let railGap: CGFloat = 12
        static let captureCornerRadius: CGFloat = 12
        static let thumbnailCornerRadius: CGFloat = 10
        static let thumbnailBorderWidth: CGFloat = 2
        static let thumbnailWidth: CGFloat = 44
        /// The base thumbnail is dimmed to this; a bright copy clipped over it marks the viewport.
        static let thumbnailDimOpacity: CGFloat = 0.4
        static let highlightCornerRadius: CGFloat = 8
        static let highlightBorderWidth: CGFloat = 3
        static let highlightShadowOpacity: Float = 0.5
        static let highlightShadowRadius: CGFloat = 3
        static let minimumHighlightHeight: CGFloat = 24
        static let closeButtonTopInset: CGFloat = 24
        /// Below this we're still mid-presentation and the proportions are meaningless.
        static let minimumUsableSide: CGFloat = 80
    }

    var onClose: (() -> Void)?

    private let image: UIImage?
    private let imageAspect: CGFloat

    private var scrollFraction: CGFloat = 0
    /// Cached in `layoutSubviews` so scrolling only moves the highlight.
    private struct HighlightGeometry {
        let thumbnailHeight: CGFloat
        let viewportHeight: CGFloat
        let pageHeight: CGFloat
    }

    private var highlightGeometry: HighlightGeometry?

    // `private(set)` so the layout tests can read these frames without walking the hierarchy.
    private(set) lazy var captureContainer: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.layer.cornerRadius = UX.captureCornerRadius
        return view
    }()

    private(set) lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = self
        return scrollView
    }()

    private lazy var pageImageView: UIImageView = {
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private(set) lazy var thumbnailContainer: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.layer.cornerRadius = UX.thumbnailCornerRadius
        view.layer.borderWidth = UX.thumbnailBorderWidth
        return view
    }()

    /// The dimmed whole page behind the highlight.
    private lazy var thumbnailImageView: UIImageView = {
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleToFill
        imageView.alpha = UX.thumbnailDimOpacity
        return imageView
    }()

    /// A bright copy clipped to the viewport, which gives the spotlight effect.
    private lazy var brightWindowContainer: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.layer.cornerRadius = UX.highlightCornerRadius
        return view
    }()

    private(set) lazy var brightWindowImageView: UIImageView = {
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleToFill
        return imageView
    }()

    private(set) lazy var highlightView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = UX.highlightCornerRadius
        view.layer.borderWidth = UX.highlightBorderWidth
        view.layer.shadowOpacity = UX.highlightShadowOpacity
        view.layer.shadowRadius = UX.highlightShadowRadius
        view.layer.shadowOffset = .zero
        return view
    }()

    private lazy var closeButton: CloseButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapClose), for: .touchUpInside)
    }

    init(image: UIImage?, closeButtonViewModel: CloseButtonViewModel) {
        self.image = image
        let size = image?.size ?? .zero
        let aspect = size.height / size.width
        self.imageAspect = (size.width > 0 && aspect.isFinite) ? aspect : 1
        super.init(frame: .zero)

        captureContainer.addSubview(scrollView)
        scrollView.addSubview(pageImageView)
        thumbnailContainer.addSubview(thumbnailImageView)
        brightWindowContainer.addSubview(brightWindowImageView)
        addSubview(captureContainer)
        addSubview(thumbnailContainer)
        // Siblings of the thumbnail, not children: it clips, which would eat the border and shadow.
        addSubview(brightWindowContainer)
        addSubview(highlightView)
        addSubview(closeButton)

        closeButton.configure(viewModel: closeButtonViewModel)
        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.leadingAnchor,
                constant: WebCompatReporterUX.Spacing.screenHorizontal
            ),
            closeButton.topAnchor.constraint(
                equalTo: safeAreaLayoutGuide.topAnchor,
                constant: UX.closeButtonTopInset
            )
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        let contentTop = safeAreaInsets.top + UX.topInset
        let availableHeight = max(1, bounds.height - contentTop - safeAreaInsets.bottom - UX.bottomInset)
        // The thumbnail shows the whole page, so cap its height or a tall page overflows.
        var thumbnailWidth = UX.thumbnailWidth
        var thumbnailHeight = thumbnailWidth * imageAspect
        if thumbnailHeight > availableHeight {
            thumbnailHeight = availableHeight
            thumbnailWidth = max(1, thumbnailHeight / imageAspect)
        }
        // Equal margins either side keep the capture centered, with the rail in the right one.
        let sideMargin = WebCompatReporterUX.Spacing.screenHorizontal + thumbnailWidth + UX.railGap
        let captureWidth = max(1, bounds.width - sideMargin * 2)
        let hasUsableSize = captureWidth > UX.minimumUsableSide && availableHeight > UX.minimumUsableSide
        let isRenderable = hasUsableSize && image != nil
        for view in [captureContainer, thumbnailContainer, brightWindowContainer, highlightView] {
            view.isHidden = !isRenderable
        }
        guard isRenderable else {
            highlightGeometry = nil
            return
        }

        let pageHeight = max(1, captureWidth * imageAspect)
        captureContainer.frame = CGRect(x: sideMargin, y: contentTop, width: captureWidth, height: availableHeight)
        scrollView.frame = captureContainer.bounds
        pageImageView.frame = CGRect(x: 0, y: 0, width: captureWidth, height: pageHeight)
        scrollView.contentSize = CGSize(width: captureWidth, height: pageHeight)

        thumbnailContainer.frame = CGRect(
            x: bounds.width - WebCompatReporterUX.Spacing.screenHorizontal - thumbnailWidth,
            y: contentTop,
            width: thumbnailWidth,
            height: thumbnailHeight
        )
        thumbnailImageView.frame = thumbnailContainer.bounds
        highlightGeometry = HighlightGeometry(
            thumbnailHeight: thumbnailHeight,
            viewportHeight: availableHeight,
            pageHeight: pageHeight
        )
        layoutViewportHighlight()
    }

    private func layoutViewportHighlight() {
        guard let geometry = highlightGeometry else { return }
        let thumbnailFrame = thumbnailContainer.frame
        let width = thumbnailFrame.width
        let visibleFraction = min(1, geometry.viewportHeight / geometry.pageHeight)
        let highlightHeight = max(UX.minimumHighlightHeight, geometry.thumbnailHeight * visibleFraction)
        let travel = max(0, geometry.thumbnailHeight - highlightHeight)
        let highlightTop = scrollFraction * travel

        let windowFrame = CGRect(
            x: thumbnailFrame.minX,
            y: thumbnailFrame.minY + highlightTop,
            width: width,
            height: highlightHeight
        )
        highlightView.frame = windowFrame
        // Shift the bright copy so its visible slice registers with the dimmed page underneath.
        brightWindowContainer.frame = windowFrame
        brightWindowImageView.frame = CGRect(x: 0, y: -highlightTop, width: width, height: geometry.thumbnailHeight)
    }

    // MARK: - Scroll sync

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let maximumOffset = max(1, scrollView.contentSize.height - scrollView.bounds.height)
        let fraction = scrollView.contentOffset.y / maximumOffset
        scrollFraction = min(max(fraction.isFinite ? fraction : 0, 0), 1)
        layoutViewportHighlight()
    }

    // MARK: - Actions

    @objc
    private func didTapClose() {
        onClose?()
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layerScrim
        thumbnailContainer.layer.borderColor = theme.colors.iconSecondary.cgColor
        highlightView.layer.borderColor = theme.colors.borderInverted.cgColor
        highlightView.layer.shadowColor = theme.colors.shadowStrong.cgColor
    }
}
