// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit

/// Mirrors the iOS "Full Page" screenshot preview: the capture scrolls in the middle, and a rail in
/// the right margin maps the whole page with a spotlight that follows the scroll.
final class WebCompatFullPageScreenshotView: UIView, ThemeApplicable, UIScrollViewDelegate {
    private enum UX {
        static let topInset: CGFloat = 72
        static let bottomInset: CGFloat = 24
        static let captureCornerRadius: CGFloat = 12
        static let closeButtonTopInset: CGFloat = 24
        /// Keeps the capture clear of the close button once Dynamic Type has grown it.
        static let captureCloseButtonGap: CGFloat = 18
        /// Below this we're still mid-presentation and the proportions are meaningless.
        static let minimumUsableSide: CGFloat = 80
        /// Equal on both sides so the capture stays centered, with the rail in the right one.
        static let captureSideMargin: CGFloat = WebCompatReporterUX.Spacing.screenHorizontal
            + WebCompatScreenshotRailView.UX.width + WebCompatScreenshotRailView.UX.gap
    }

    var onClose: (() -> Void)?

    private let image: UIImage?
    private let viewModel: WebCompatFullPageScreenshotViewModel
    private let imageHeightToWidthRatio: CGFloat

    /// The page as the capture renders it, which is what the rail measures itself against.
    private var pageHeight: CGFloat {
        return scrollView.bounds.width * imageHeightToWidthRatio
    }

    private var scrollFraction: CGFloat {
        let maximumOffset = max(1, pageHeight - scrollView.bounds.height)
        return min(max(scrollView.contentOffset.y / maximumOffset, 0), 1)
    }

    private var visibleFraction: CGFloat {
        guard pageHeight > 0 else { return 1 }
        return min(1, scrollView.bounds.height / pageHeight)
    }

    private lazy var scrollView: UIScrollView = .build { scrollView in
        scrollView.showsVerticalScrollIndicator = false
        // Rounds the capture's corners.
        scrollView.clipsToBounds = true
        scrollView.layer.cornerRadius = UX.captureCornerRadius
        scrollView.delegate = self
    }

    /// The one element VoiceOver reads here. It sits inside the scroll view, so focusing it also
    /// lets the three-finger scroll move the page.
    private lazy var pageImageView: UIImageView = .build { imageView in
        imageView.image = self.image
        imageView.contentMode = .scaleToFill
        imageView.isAccessibilityElement = true
        imageView.accessibilityTraits = .image
        imageView.accessibilityLabel = self.viewModel.captureAccessibilityLabel
        imageView.accessibilityIdentifier = self.viewModel.captureAccessibilityIdentifier
        // Its size comes from the constraints below, so it must not push back with the whole
        // page's intrinsic size.
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    private lazy var railView = WebCompatScreenshotRailView(
        image: image,
        pageHeightToWidthRatio: imageHeightToWidthRatio
    )

    private lazy var closeButton: CloseButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapClose), for: .touchUpInside)
        // Its icon is an appearance-adaptive asset, not a template, so no tint reaches it. The dark
        // variant's circle all but disappears against the scrim, which is dark in every palette.
        button.overrideUserInterfaceStyle = .light
    }

    init(
        image: UIImage?,
        viewModel: WebCompatFullPageScreenshotViewModel,
        closeButtonViewModel: CloseButtonViewModel
    ) {
        self.image = image
        self.viewModel = viewModel
        let size = image?.size ?? .zero
        let ratio = size.height / size.width
        // Both dimensions, or a zero-height capture yields a ratio of 0 that passes `isFinite`
        // and then collapses the capture to nothing while still reporting itself renderable.
        self.imageHeightToWidthRatio = (size.width > 0 && size.height > 0 && ratio.isFinite) ? ratio : 1
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
        scrollView.addSubview(pageImageView)
        addSubviews(scrollView, railView, closeButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate(
            closeButtonConstraints() + captureConstraints() + railConstraints()
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
            multiplier: imageHeightToWidthRatio
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
            // A floor rather than the whole story: at accessibility text sizes the close button
            // grows past the nominal inset above.
            scrollView.topAnchor.constraint(
                greaterThanOrEqualTo: closeButton.bottomAnchor,
                constant: UX.captureCloseButtonGap
            ),
            scrollView.widthAnchor.constraint(greaterThanOrEqualToConstant: 0),
            width,
            bottom,
            ratio,

            pageImageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            pageImageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            pageImageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            pageImageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            pageImageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            pageImageView.heightAnchor.constraint(
                equalTo: pageImageView.widthAnchor,
                multiplier: imageHeightToWidthRatio
            )
        ]
    }

    /// The rail sizes itself; this only places it and says how far it may grow.
    private func railConstraints() -> [NSLayoutConstraint] {
        let bottom = railView.bottomAnchor.constraint(
            lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor,
            constant: -UX.bottomInset
        )
        breakBeforeRequiredConstraints(bottom)

        return [
            railView.trailingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.trailingAnchor,
                constant: -WebCompatReporterUX.Spacing.screenHorizontal
            ),
            railView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            bottom
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
        railView.update(scrollFraction: scrollFraction, visibleFraction: visibleFraction)
    }

    /// Bad geometry produces inf/NaN and kills rendering, so these stay hidden until the bounds and
    /// the image can describe a page.
    private func updateContentVisibility() {
        let availableWidth = bounds.width - safeAreaInsets.left - safeAreaInsets.right
        let availableHeight = bounds.height - safeAreaInsets.top - safeAreaInsets.bottom
            - UX.topInset - UX.bottomInset
        let isRenderable = image != nil
            && availableWidth - UX.captureSideMargin * 2 > UX.minimumUsableSide
            && availableHeight > UX.minimumUsableSide

        let isHidden = !isRenderable
        for view in [scrollView, railView] where view.isHidden != isHidden {
            view.isHidden = isHidden
        }
    }

    // MARK: - Accessibility

    /// The sheet underneath stays mounted, so VoiceOver needs pointing at the viewer.
    func moveAccessibilityFocusToCloseButton() {
        UIAccessibility.post(notification: .screenChanged, argument: closeButton)
    }

    // MARK: - Scroll sync

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        railView.update(scrollFraction: scrollFraction, visibleFraction: visibleFraction)
    }

    // MARK: - Actions

    @objc
    private func didTapClose() {
        onClose?()
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layerScrim
        railView.applyTheme(theme: theme)
    }
}
