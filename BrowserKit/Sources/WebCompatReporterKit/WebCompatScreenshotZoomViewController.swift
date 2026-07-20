// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// Full-screen "Full Page" screenshot viewer presented over the Report Preview
/// sheet. Pure UIKit; the view controller never dismisses itself — `onClose`
/// routes back to the coordinator.
public final class WebCompatScreenshotZoomViewController: UIViewController {
    private let screenshotView: WebCompatFullPageScreenshotView

    public init(image: UIImage?, closeAccessibilityLabel: String, theme: Theme, onClose: @escaping () -> Void) {
        screenshotView = WebCompatFullPageScreenshotView(
            image: image,
            closeAccessibilityLabel: closeAccessibilityLabel,
            theme: theme,
            onClose: onClose
        )
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadView() {
        view = screenshotView
    }
}

/// Mimics the iOS "Full Page" screenshot preview (Figma 23608-67772): the
/// captured page is centered and scrollable, with a compact device-style
/// thumbnail of the whole page floating in the right margin and a viewport
/// highlight that tracks the scroll. Layout guards against inf/NaN geometry
/// while the presentation is still sizing up.
final class WebCompatFullPageScreenshotView: UIView, UIScrollViewDelegate {
    private enum UX {
        static let edgeInset: CGFloat = 16
        static let topInset: CGFloat = 72
        static let bottomInset: CGFloat = 24
        static let railGap: CGFloat = 12
        static let captureCornerRadius: CGFloat = 12
        static let thumbnailCornerRadius: CGFloat = 10
        static let thumbnailWidth: CGFloat = 44
        /// Opacity of the whole-page thumbnail outside the current viewport.
        static let thumbnailDimOpacity: CGFloat = 0.4
        static let indicatorCornerRadius: CGFloat = 8
        static let indicatorBorderWidth: CGFloat = 3
        static let minimumIndicatorHeight: CGFloat = 24
        static let closeButtonTapTarget: CGFloat = 44
        static let closeButtonTopInset: CGFloat = 24
        /// Below this the presentation is still transitioning; laying out with
        /// tiny/zero geometry would make scale/frames inf/NaN and abort rendering.
        static let minimumUsableSide: CGFloat = 80
    }

    private let image: UIImage?
    private let imageAspect: CGFloat
    private let theme: Theme
    private var onClose: () -> Void

    private var scrollFraction: CGFloat = 0

    private lazy var mainContainer: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.layer.cornerRadius = UX.captureCornerRadius
        return view
    }()

    private lazy var scrollView: UIScrollView = {
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

    private lazy var thumbnailContainer: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.layer.cornerRadius = UX.thumbnailCornerRadius
        view.layer.borderWidth = 2
        view.layer.borderColor = self.theme.colors.iconSecondary.cgColor
        return view
    }()

    /// The whole page shown dimmed (reduced opacity) as the thumbnail base.
    private lazy var thumbnailImageView: UIImageView = {
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleToFill
        imageView.alpha = UX.thumbnailDimOpacity
        return imageView
    }()

    /// Clips a full-brightness copy of the page to the current viewport region,
    /// so only the visible slice is undimmed (the native spotlight effect).
    private lazy var brightWindowContainer: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.layer.cornerRadius = UX.indicatorCornerRadius
        return view
    }()

    private lazy var brightWindowImageView: UIImageView = {
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleToFill
        return imageView
    }()

    private lazy var indicatorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = UX.indicatorCornerRadius
        view.layer.borderWidth = UX.indicatorBorderWidth
        view.layer.borderColor = self.theme.colors.borderInverted.cgColor
        view.layer.shadowColor = self.theme.colors.shadowStrong.cgColor
        view.layer.shadowOpacity = 0.5
        view.layer.shadowRadius = 3
        view.layer.shadowOffset = .zero
        return view
    }()

    private lazy var closeButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(named: StandardImageIdentifiers.Large.cross)?.withRenderingMode(.alwaysTemplate)
        configuration.baseForegroundColor = self.theme.colors.iconPrimary
        configuration.background.backgroundColor = self.theme.colors.layer3
        configuration.cornerStyle = .capsule
        let button = UIButton(configuration: configuration)
        button.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        return button
    }()

    init(image: UIImage?, closeAccessibilityLabel: String, theme: Theme, onClose: @escaping () -> Void) {
        self.image = image
        let size = image?.size ?? .zero
        self.imageAspect = size.width > 0 ? size.height / size.width : 1
        self.theme = theme
        self.onClose = onClose
        super.init(frame: .zero)
        // Matches the native full-page screenshot preview scrim (Figma 23608-67772).
        backgroundColor = theme.colors.layerScrim

        mainContainer.addSubview(scrollView)
        scrollView.addSubview(pageImageView)
        thumbnailContainer.addSubview(thumbnailImageView)
        brightWindowContainer.addSubview(brightWindowImageView)
        addSubview(mainContainer)
        addSubview(thumbnailContainer)
        // The window floats on top of (not clipped by) the thumbnail, so its
        // border and shadow read as a floating overlay.
        addSubview(brightWindowContainer)
        addSubview(indicatorView)
        addSubview(closeButton)

        closeButton.accessibilityLabel = closeAccessibilityLabel
        closeButton.accessibilityTraits = [.button]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        closeButton.frame = CGRect(
            x: UX.edgeInset,
            y: safeAreaInsets.top + UX.closeButtonTopInset,
            width: UX.closeButtonTapTarget,
            height: UX.closeButtonTapTarget
        )

        let contentTop = safeAreaInsets.top + UX.topInset
        let availableHeight = max(1, bounds.height - contentTop - safeAreaInsets.bottom - UX.bottomInset)
        // A slim thumbnail shows the whole page; cap the height so very tall pages still fit.
        var thumbnailWidth = UX.thumbnailWidth
        var thumbnailHeight = thumbnailWidth * imageAspect
        if thumbnailHeight > availableHeight {
            thumbnailHeight = availableHeight
            thumbnailWidth = max(1, thumbnailHeight / imageAspect)
        }
        // Symmetric margins keep the capture centered; the thumbnail floats in the right margin.
        let sideMargin = UX.edgeInset + thumbnailWidth + UX.railGap
        let mainWidth = max(1, bounds.width - sideMargin * 2)
        // Skip the geometry-derived layout until the size is real; laying out with
        // tiny/zero bounds would produce inf/NaN scale and frames.
        let hasUsableSize = mainWidth > UX.minimumUsableSide && availableHeight > UX.minimumUsableSide
        mainContainer.isHidden = !hasUsableSize
        thumbnailContainer.isHidden = !hasUsableSize
        guard hasUsableSize, image != nil else { return }

        let pageHeight = max(1, mainWidth * imageAspect)
        mainContainer.frame = CGRect(x: sideMargin, y: contentTop, width: mainWidth, height: availableHeight)
        scrollView.frame = mainContainer.bounds
        pageImageView.frame = CGRect(x: 0, y: 0, width: mainWidth, height: pageHeight)
        scrollView.contentSize = CGSize(width: mainWidth, height: pageHeight)

        thumbnailContainer.frame = CGRect(
            x: bounds.width - UX.edgeInset - thumbnailWidth,
            y: contentTop,
            width: thumbnailWidth,
            height: thumbnailHeight
        )
        thumbnailImageView.frame = thumbnailContainer.bounds
        layoutIndicator(thumbnailHeight: thumbnailHeight, viewportHeight: availableHeight, pageHeight: pageHeight)
    }

    private func layoutIndicator(thumbnailHeight: CGFloat, viewportHeight: CGFloat, pageHeight: CGFloat) {
        // Position the window in the view's coordinate space (it's a sibling of the
        // thumbnail, not a child) so it floats on top and isn't clipped.
        let thumbnailFrame = thumbnailContainer.frame
        let width = thumbnailFrame.width
        let visibleFraction = min(1, viewportHeight / pageHeight)
        let indicatorHeight = max(UX.minimumIndicatorHeight, thumbnailHeight * visibleFraction)
        let indicatorTravel = max(0, thumbnailHeight - indicatorHeight)
        let indicatorTop = scrollFraction * indicatorTravel

        let windowFrame = CGRect(
            x: thumbnailFrame.minX,
            y: thumbnailFrame.minY + indicatorTop,
            width: width,
            height: indicatorHeight
        )
        indicatorView.frame = windowFrame
        // Undim only the current viewport: clip a full-brightness copy of the page
        // to the window, shifting it so the visible slice lines up with the dim page.
        brightWindowContainer.frame = windowFrame
        brightWindowImageView.frame = CGRect(x: 0, y: -indicatorTop, width: width, height: thumbnailHeight)
    }

    // MARK: - Scroll sync

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let maximumOffset = max(1, scrollView.contentSize.height - scrollView.bounds.height)
        let fraction = scrollView.contentOffset.y / maximumOffset
        scrollFraction = min(max(fraction.isFinite ? fraction : 0, 0), 1)
        setNeedsLayout()
    }

    // MARK: - Actions

    @objc
    private func didTapClose() {
        onClose()
    }
}
