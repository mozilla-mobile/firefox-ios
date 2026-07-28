// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit

/// Mirrors the iOS "Full Page" screenshot preview: the capture scrolls in the middle,
/// a thumbnail of the whole page sits in the right margin with a highlight that follows
/// the scroll.
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
        /// Comfortably above `minimumHighlightHeight`, otherwise a wide page gives the
        /// highlight no room to travel and it sits frozen and overhanging.
        static let minimumRailHeight: CGFloat = 64
        static let closeButtonTopInset: CGFloat = 24
        /// Below this we're still mid-presentation and the proportions are meaningless.
        static let minimumUsableSide: CGFloat = 80
        /// Equal on both sides so the capture stays centered, with the rail in the right one.
        static let captureSideMargin: CGFloat = WebCompatReporterUX.Spacing.screenHorizontal
            + thumbnailWidth + railGap
    }

    var onClose: (() -> Void)?

    private let image: UIImage?
    private let imageAspect: CGFloat

    /// The page as the capture renders it, which is what the highlight measures itself against.
    private var pageHeight: CGFloat {
        return scrollView.bounds.width * imageAspect
    }

    private var scrollFraction: CGFloat {
        let maximumOffset = max(1, pageHeight - scrollView.bounds.height)
        let fraction = scrollView.contentOffset.y / maximumOffset
        return min(max(fraction.isFinite ? fraction : 0, 0), 1)
    }

    private var highlightHeightConstraint: NSLayoutConstraint?

    /// Set by the rail's height against how much of the page the capture shows, so it holds still
    /// while scrolling and only changes when the geometry does.
    private var highlightHeight: CGFloat {
        let railHeight = thumbnailContainer.bounds.height
        guard railHeight > 0, pageHeight > 0 else { return UX.minimumHighlightHeight }

        let visibleFraction = min(1, scrollView.bounds.height / pageHeight)
        return max(UX.minimumHighlightHeight, railHeight * visibleFraction)
    }

    // `private(set)` so the module's layout tests can read these frames without walking the
    // hierarchy. Nothing outside the view can mutate or replace them.
    private(set) lazy var scrollView: UIScrollView = .build { scrollView in
        scrollView.showsVerticalScrollIndicator = false
        // Rounds the capture's corners.
        scrollView.clipsToBounds = true
        scrollView.layer.cornerRadius = UX.captureCornerRadius
        scrollView.delegate = self
    }

    private lazy var pageImageView: UIImageView = .build { imageView in
        imageView.image = self.image
        imageView.contentMode = .scaleToFill
    }

    private(set) lazy var thumbnailContainer: UIView = .build { view in
        // Rounds the dimmed page inside it.
        view.clipsToBounds = true
        view.layer.cornerRadius = UX.thumbnailCornerRadius
        view.layer.borderWidth = UX.thumbnailBorderWidth
    }

    /// The dimmed whole page behind the highlight.
    private lazy var thumbnailImageView: UIImageView = .build { imageView in
        imageView.image = self.image
        imageView.contentMode = .scaleToFill
        imageView.alpha = UX.thumbnailDimOpacity
    }

    /// A bright copy clipped to the viewport, which gives the spotlight effect.
    private(set) lazy var brightWindowContainer: UIView = .build { view in
        // The clip *is* the spotlight: it crops the bright page down to the viewport window.
        view.clipsToBounds = true
        view.layer.cornerRadius = UX.highlightCornerRadius
    }

    private(set) lazy var brightWindowImageView: UIImageView = .build { imageView in
        imageView.image = self.image
        imageView.contentMode = .scaleToFill
    }

    private(set) lazy var highlightView: UIView = .build { view in
        view.layer.cornerRadius = UX.highlightCornerRadius
        view.layer.borderWidth = UX.highlightBorderWidth
        view.layer.shadowOpacity = UX.highlightShadowOpacity
        view.layer.shadowRadius = UX.highlightShadowRadius
        view.layer.shadowOffset = .zero
    }

    private(set) lazy var closeButton: CloseButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapClose), for: .touchUpInside)
    }

    init(image: UIImage?, closeButtonViewModel: CloseButtonViewModel) {
        self.image = image
        let size = image?.size ?? .zero
        let aspect = size.height / size.width
        self.imageAspect = (size.width > 0 && aspect.isFinite) ? aspect : 1
        super.init(frame: .zero)

        setupSubviews()
        setupConstraints()
        closeButton.configure(viewModel: closeButtonViewModel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupSubviews() {
        // Every copy of the page is sized by the constraints below, so none of them may push
        // back with its intrinsic size. A long page otherwise drags the rail down the screen:
        // the bright copy is required-equal to the rail's height, and at the default priority
        // its intrinsic height beats the rail's own height constraint.
        for imageView in [pageImageView, thumbnailImageView, brightWindowImageView] {
            imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
            imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        }

        scrollView.addSubview(pageImageView)
        thumbnailContainer.addSubview(thumbnailImageView)
        brightWindowContainer.addSubview(brightWindowImageView)
        // The bright window and the highlight are siblings of the thumbnail, not children:
        // it clips, which would eat the highlight's border and shadow.
        addSubviews(scrollView, thumbnailContainer, brightWindowContainer, highlightView, closeButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate(
            closeButtonConstraints() + captureConstraints() + railConstraints() + highlightConstraints()
        )
    }

    private func closeButtonConstraints() -> [NSLayoutConstraint] {
        return [
            closeButton.leadingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.leadingAnchor,
                constant: WebCompatReporterUX.Spacing.screenHorizontal
            ),
            closeButton.topAnchor.constraint(
                equalTo: safeAreaLayoutGuide.topAnchor,
                constant: UX.closeButtonTopInset
            )
        ]
    }

    private func captureConstraints() -> [NSLayoutConstraint] {
        // A page shorter than the space available gets a card its own size, so the ratio only
        // holds while it fits. Stretching it would round the top corners over scrim and leave
        // the image's bottom edge square.
        let ratio = scrollView.heightAnchor.constraint(
            equalTo: scrollView.widthAnchor,
            multiplier: imageAspect
        )
        ratio.priority = .defaultHigh
        let width = scrollView.widthAnchor.constraint(
            equalTo: safeAreaLayoutGuide.widthAnchor,
            constant: -UX.captureSideMargin * 2
        )
        let bottom = scrollView.bottomAnchor.constraint(
            lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor,
            constant: -UX.bottomInset
        )
        breakBeforeRequiredConstraints(width, bottom)

        return [
            scrollView.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor),
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: UX.topInset),
            scrollView.widthAnchor.constraint(greaterThanOrEqualToConstant: 0),
            width,
            bottom,
            ratio,

            pageImageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            pageImageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            pageImageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            pageImageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            pageImageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            pageImageView.heightAnchor.constraint(equalTo: pageImageView.widthAnchor, multiplier: imageAspect)
        ]
    }

    private func railConstraints() -> [NSLayoutConstraint] {
        // The rail keeps a fixed width and squashes a tall page rather than narrowing, which
        // would otherwise feed back into the margins and reflow the capture.
        let height = thumbnailContainer.heightAnchor.constraint(
            equalToConstant: max(UX.minimumRailHeight, UX.thumbnailWidth * imageAspect)
        )
        height.priority = .defaultHigh
        let bottom = thumbnailContainer.bottomAnchor.constraint(
            lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor,
            constant: -UX.bottomInset
        )
        breakBeforeRequiredConstraints(bottom)

        return [
            thumbnailContainer.trailingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.trailingAnchor,
                constant: -WebCompatReporterUX.Spacing.screenHorizontal
            ),
            thumbnailContainer.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: UX.topInset),
            thumbnailContainer.widthAnchor.constraint(equalToConstant: UX.thumbnailWidth),
            bottom,
            height,

            thumbnailImageView.topAnchor.constraint(equalTo: thumbnailContainer.topAnchor),
            thumbnailImageView.leadingAnchor.constraint(equalTo: thumbnailContainer.leadingAnchor),
            thumbnailImageView.trailingAnchor.constraint(equalTo: thumbnailContainer.trailingAnchor),
            thumbnailImageView.bottomAnchor.constraint(equalTo: thumbnailContainer.bottomAnchor)
        ]
    }

    /// The highlight sits at the top of the rail and `updateHighlightOffset()` translates it down
    /// from there, so its height is the only constant the layout owns.
    private func highlightConstraints() -> [NSLayoutConstraint] {
        let height = highlightView.heightAnchor.constraint(equalToConstant: UX.minimumHighlightHeight)
        highlightHeightConstraint = height

        return [
            highlightView.leadingAnchor.constraint(equalTo: thumbnailContainer.leadingAnchor),
            highlightView.trailingAnchor.constraint(equalTo: thumbnailContainer.trailingAnchor),
            highlightView.topAnchor.constraint(equalTo: thumbnailContainer.topAnchor),
            height,

            brightWindowContainer.topAnchor.constraint(equalTo: highlightView.topAnchor),
            brightWindowContainer.leadingAnchor.constraint(equalTo: highlightView.leadingAnchor),
            brightWindowContainer.trailingAnchor.constraint(equalTo: highlightView.trailingAnchor),
            brightWindowContainer.bottomAnchor.constraint(equalTo: highlightView.bottomAnchor),

            brightWindowImageView.leadingAnchor.constraint(equalTo: brightWindowContainer.leadingAnchor),
            brightWindowImageView.trailingAnchor.constraint(equalTo: brightWindowContainer.trailingAnchor),
            brightWindowImageView.topAnchor.constraint(equalTo: brightWindowContainer.topAnchor),
            brightWindowImageView.heightAnchor.constraint(equalTo: thumbnailContainer.heightAnchor)
        ]
    }

    /// Keeps the near-zero bounds we get mid-presentation from reporting unsatisfiable
    /// constraints, while still winning against the aspect-ratio constraints at a real size.
    private func breakBeforeRequiredConstraints(_ constraints: NSLayoutConstraint...) {
        for constraint in constraints {
            constraint.priority = .required - 1
        }
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        updateContentVisibility()
        // Guarded, or assigning it every pass would invalidate the layout it was just given.
        if highlightHeightConstraint?.constant != highlightHeight {
            highlightHeightConstraint?.constant = highlightHeight
        }
        updateHighlightOffset()
    }

    /// Bad geometry produces inf/NaN and kills rendering, so the derived views stay hidden
    /// until the bounds and the image can actually describe a page.
    private func updateContentVisibility() {
        let availableWidth = bounds.width - safeAreaInsets.left - safeAreaInsets.right
        let availableHeight = bounds.height - safeAreaInsets.top - safeAreaInsets.bottom
            - UX.topInset - UX.bottomInset
        let isRenderable = image != nil
            && availableWidth - UX.captureSideMargin * 2 > UX.minimumUsableSide
            && availableHeight > UX.minimumUsableSide

        let isHidden = !isRenderable
        for view in [scrollView, thumbnailContainer, brightWindowContainer, highlightView]
        where view.isHidden != isHidden {
            view.isHidden = isHidden
        }
    }

    /// Slides the window down the rail. A translation rather than a constraint constant because
    /// `scrollViewDidScroll` lands mid-layout, where a constant only takes effect on the next
    /// pass and the highlight visibly trails the capture.
    private func updateHighlightOffset() {
        let travel = max(0, thumbnailContainer.bounds.height - highlightHeight)
        let offset = CGAffineTransform(translationX: 0, y: scrollFraction * travel)

        highlightView.transform = offset
        brightWindowContainer.transform = offset
        // The inverse keeps the bright copy registered with the dimmed page underneath, so the
        // window moves while the slice it exposes stays put.
        brightWindowImageView.transform = offset.inverted()
    }

    // MARK: - Accessibility

    /// The sheet underneath stays mounted, so VoiceOver needs pointing at the viewer.
    func moveAccessibilityFocusToFirstElement() {
        UIAccessibility.post(notification: .screenChanged, argument: closeButton)
    }

    // MARK: - Scroll sync

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateHighlightOffset()
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
