// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// The whole page mapped into a narrow strip, with a spotlight marking the part of it a viewer is
/// showing.
final class WebCompatScreenshotRailView: UIView, ThemeApplicable {
    enum UX {
        static let width: CGFloat = 44
        static let gap: CGFloat = 12
        static let cornerRadius: CGFloat = 10
        static let borderWidth: CGFloat = 2
        static let dimOpacity: CGFloat = 0.4
        /// Comfortably above `minimumHighlightHeight`, or a wide page leaves the spotlight no room
        /// to travel and it sits frozen and overhanging.
        static let minimumHeight: CGFloat = 64
        static let highlightCornerRadius: CGFloat = 8
        static let highlightBorderWidth: CGFloat = 3
        static let highlightShadowOpacity: Float = 0.5
        static let highlightShadowRadius: CGFloat = 3
        static let minimumHighlightHeight: CGFloat = 24
    }

    private let pageHeightToWidthRatio: CGFloat
    private var scrollFraction: CGFloat = 0
    private var visibleFraction: CGFloat = 1
    private var highlightHeightConstraint: NSLayoutConstraint?

    private var highlightHeight: CGFloat {
        guard bounds.height > 0 else { return UX.minimumHighlightHeight }
        return max(UX.minimumHighlightHeight, bounds.height * min(1, max(0, visibleFraction)))
    }

    private lazy var clipView: UIView = .build { view in
        view.clipsToBounds = true
        view.layer.cornerRadius = UX.cornerRadius
        view.layer.borderWidth = UX.borderWidth
    }

    private lazy var dimmedPageView: UIImageView = makePageView(alpha: UX.dimOpacity)

    /// Crops the bright copy to the window, which is what gives the spotlight effect.
    private lazy var spotlightContainer: UIView = .build { view in
        view.clipsToBounds = true
        view.layer.cornerRadius = UX.highlightCornerRadius
    }

    private lazy var spotlightPageView: UIImageView = makePageView()

    private lazy var highlightView: UIView = .build { view in
        view.layer.cornerRadius = UX.highlightCornerRadius
        view.layer.borderWidth = UX.highlightBorderWidth
        view.layer.shadowOpacity = UX.highlightShadowOpacity
        view.layer.shadowRadius = UX.highlightShadowRadius
        view.layer.shadowOffset = .zero
    }

    init(image: UIImage?, pageHeightToWidthRatio: CGFloat) {
        self.pageHeightToWidthRatio = pageHeightToWidthRatio
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false
        setupPageCopies(from: image)
        setupSubviews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func makePageView(alpha: CGFloat = 1) -> UIImageView {
        return .build { imageView in
            imageView.contentMode = .scaleToFill
            imageView.alpha = alpha
            // Its size comes from the rail, never the other way round: at the default priority a
            // long page's intrinsic height beats the rail's own height constraint.
            imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
            imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        }
    }

    private func setupPageCopies(from image: UIImage?) {
        // Both copies draw at rail width, so the full capture is wasted memory, and a tall enough
        // one is past the maximum texture size.
        let railImage = image?.preparingThumbnail(
            of: CGSize(width: UX.width, height: UX.width * pageHeightToWidthRatio)
        ) ?? image
        dimmedPageView.image = railImage
        spotlightPageView.image = railImage
    }

    private func setupSubviews() {
        clipView.addSubview(dimmedPageView)
        spotlightContainer.addSubview(spotlightPageView)
        // A sibling of `clipView` rather than inside it, so the ring isn't cropped away.
        addSubviews(clipView, spotlightContainer, highlightView)
        // The rail maps content VoiceOver already reads at the source.
        for view in [self, clipView, dimmedPageView, spotlightContainer, spotlightPageView, highlightView] {
            view.isAccessibilityElement = false
        }
    }

    private func setupConstraints() {
        let railHeight = heightAnchor.constraint(equalToConstant: UX.width * pageHeightToWidthRatio)
        // Breakable, so a caller that caps the rail squashes a long page rather than reporting
        // unsatisfiable constraints.
        railHeight.priority = .defaultHigh - 1
        let heightConstraint = highlightView.heightAnchor.constraint(
            equalToConstant: UX.minimumHighlightHeight
        )
        highlightHeightConstraint = heightConstraint

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: UX.width),
            heightAnchor.constraint(greaterThanOrEqualToConstant: UX.minimumHeight),
            railHeight,

            clipView.topAnchor.constraint(equalTo: topAnchor),
            clipView.leadingAnchor.constraint(equalTo: leadingAnchor),
            clipView.trailingAnchor.constraint(equalTo: trailingAnchor),
            clipView.bottomAnchor.constraint(equalTo: bottomAnchor),

            dimmedPageView.topAnchor.constraint(equalTo: clipView.topAnchor),
            dimmedPageView.leadingAnchor.constraint(equalTo: clipView.leadingAnchor),
            dimmedPageView.trailingAnchor.constraint(equalTo: clipView.trailingAnchor),
            dimmedPageView.bottomAnchor.constraint(equalTo: clipView.bottomAnchor),

            // Pinned to the top; `updateHighlightOffset()` slides it down from there.
            highlightView.topAnchor.constraint(equalTo: topAnchor),
            highlightView.leadingAnchor.constraint(equalTo: leadingAnchor),
            highlightView.trailingAnchor.constraint(equalTo: trailingAnchor),
            heightConstraint,

            spotlightContainer.topAnchor.constraint(equalTo: highlightView.topAnchor),
            spotlightContainer.leadingAnchor.constraint(equalTo: highlightView.leadingAnchor),
            spotlightContainer.trailingAnchor.constraint(equalTo: highlightView.trailingAnchor),
            spotlightContainer.bottomAnchor.constraint(equalTo: highlightView.bottomAnchor),

            spotlightPageView.leadingAnchor.constraint(equalTo: spotlightContainer.leadingAnchor),
            spotlightPageView.trailingAnchor.constraint(equalTo: spotlightContainer.trailingAnchor),
            spotlightPageView.topAnchor.constraint(equalTo: spotlightContainer.topAnchor),
            spotlightPageView.heightAnchor.constraint(equalTo: heightAnchor)
        ])
    }

    // MARK: - Updating

    /// - Parameters:
    ///   - scrollFraction: how far through the page the content is, 0 to 1.
    ///   - visibleFraction: how much of the page is on show, 0 to 1.
    func update(scrollFraction: CGFloat, visibleFraction: CGFloat) {
        self.scrollFraction = scrollFraction
        self.visibleFraction = visibleFraction

        applyHighlightHeight()
        updateHighlightOffset()
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        applyHighlightHeight()
        updateHighlightOffset()
        // From the height just resolved, not the layer's bounds, which is a pass behind.
        highlightView.layer.shadowPath = UIBezierPath(
            roundedRect: CGRect(x: 0, y: 0, width: bounds.width, height: highlightHeight),
            cornerRadius: UX.highlightCornerRadius
        ).cgPath
    }

    private func applyHighlightHeight() {
        guard highlightHeightConstraint?.constant != highlightHeight else { return }
        highlightHeightConstraint?.constant = highlightHeight
    }

    private func updateHighlightOffset() {
        let travel = max(0, bounds.height - highlightHeight)
        let offset = CGAffineTransform(translationX: 0, y: min(1, max(0, scrollFraction)) * travel)

        highlightView.transform = offset
        spotlightContainer.transform = offset
        // The inverse keeps the bright copy registered with the dimmed page underneath, so the
        // window moves while the page it exposes stays put.
        spotlightPageView.transform = offset.inverted()
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        // Both strokes sit over a page that doesn't follow the app theme, so they need a token that
        // stays light in every palette rather than one that flips.
        clipView.layer.borderColor = theme.colors.iconOnColor.cgColor
        highlightView.layer.borderColor = theme.colors.iconOnColor.cgColor
        highlightView.layer.shadowColor = theme.colors.shadowStrong.cgColor
    }
}
