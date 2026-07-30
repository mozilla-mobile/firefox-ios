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

    private var captureSize: CGSize {
        return captureContainer.bounds.size
    }

    private var pageHeight: CGFloat {
        return captureSize.width * imageHeightToWidthRatio
    }

    private var scrollFraction: CGFloat {
        let maximumOffset = max(1, pageHeight - captureSize.height)
        return min(max(scrollView.contentOffset.y / maximumOffset, 0), 1)
    }

    private var visibleFraction: CGFloat {
        guard pageHeight > 0 else { return 1 }
        return min(1, captureSize.height / pageHeight)
    }

    /// Owns the card's shape so the scroll view stays unrounded and unclipped.
    private lazy var captureContainer: UIView = .build { view in
        view.clipsToBounds = true
        view.layer.cornerRadius = UX.captureCornerRadius
    }

    private lazy var scrollView: UIScrollView = .build { scrollView in
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = self
    }

    private lazy var pageImageView: UIImageView = .build { imageView in
        imageView.image = self.image
        imageView.contentMode = .scaleToFill
        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = self.viewModel.captureAccessibilityLabel
        imageView.accessibilityIdentifier = self.viewModel.captureAccessibilityIdentifier
        // Its size comes from the constraints below, so it must not push back with its own.
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    private lazy var railView = WebCompatScreenshotRailView(
        image: image,
        pageHeightToWidthRatio: imageHeightToWidthRatio
    )

    private lazy var closeButton: CloseButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapClose), for: .touchUpInside)
    }

    init(
        image: UIImage?,
        viewModel: WebCompatFullPageScreenshotViewModel,
        closeButtonViewModel: CloseButtonViewModel
    ) {
        self.image = image
        self.viewModel = viewModel
        let size = image?.size ?? .zero
        self.imageHeightToWidthRatio = size != .zero ? size.height / size.width : 1
        super.init(frame: .zero)

        setupLayout()
        closeButton.configure(viewModel: closeButtonViewModel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupLayout() {
        scrollView.addSubview(pageImageView)
        captureContainer.addSubview(scrollView)
        addSubviews(captureContainer, railView, closeButton)

        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.leadingAnchor,
                constant: WebCompatReporterUX.Spacing.screenHorizontal
            ),
            closeButton.topAnchor.constraint(
                equalTo: safeAreaLayoutGuide.topAnchor,
                constant: UX.closeButtonTopInset
            ),

            captureContainer.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor),
            captureContainer.topAnchor.constraint(
                equalTo: safeAreaLayoutGuide.topAnchor,
                constant: UX.topInset
            ),
            // A floor rather than the whole story: at accessibility text sizes the close button
            // grows past the nominal inset above.
            captureContainer.topAnchor.constraint(
                greaterThanOrEqualTo: closeButton.bottomAnchor,
                constant: UX.captureCloseButtonGap
            ),
            captureContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: 0),
            captureContainer.widthAnchor.constraint(
                equalTo: safeAreaLayoutGuide.widthAnchor,
                constant: -UX.captureSideMargin * 2
            ).priority(.defaultHigh),
            captureContainer.bottomAnchor.constraint(
                lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor,
                constant: -UX.bottomInset
            ).priority(.defaultHigh),
            captureContainer.heightAnchor.constraint(
                equalTo: captureContainer.widthAnchor,
                multiplier: imageHeightToWidthRatio
            ).priority(.defaultHigh - 1),

            scrollView.topAnchor.constraint(equalTo: captureContainer.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: captureContainer.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: captureContainer.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: captureContainer.bottomAnchor),

            pageImageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            pageImageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            pageImageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            pageImageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            pageImageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            pageImageView.heightAnchor.constraint(
                equalTo: pageImageView.widthAnchor,
                multiplier: imageHeightToWidthRatio
            ),

            railView.trailingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.trailingAnchor,
                constant: -WebCompatReporterUX.Spacing.screenHorizontal
            ),
            railView.topAnchor.constraint(equalTo: captureContainer.topAnchor),
            railView.bottomAnchor.constraint(
                lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor,
                constant: -UX.bottomInset
            ).priority(.defaultHigh)
        ])
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        updateContentVisibility()
        railView.update(scrollFraction: scrollFraction, visibleFraction: visibleFraction)
    }

    private func updateContentVisibility() {
        let availableWidth = bounds.width - safeAreaInsets.left - safeAreaInsets.right
        let availableHeight = bounds.height - safeAreaInsets.top - safeAreaInsets.bottom
            - UX.topInset - UX.bottomInset
        // The capture only gets what the two margins leave, and the rail lives in one of them.
        // Under `minimumUsableSide` we're still mid-presentation.
        let isRenderable = image != nil
            && availableWidth - UX.captureSideMargin * 2 > UX.minimumUsableSide
            && availableHeight > UX.minimumUsableSide

        captureContainer.isHidden = !isRenderable
        railView.isHidden = !isRenderable
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
        closeButton.tintColor = theme.colors.iconOnColor
        railView.applyTheme(theme: theme)
    }
}
