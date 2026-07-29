// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// The whole page mapped into a narrow strip, with a spotlight marking the part of it a viewer is
/// currently showing. The rail owns its own width and page ratio; where it sits and how far it may
/// grow are the caller's business.
///
/// The spotlight is a full-brightness copy of the page clipped to the visible window, floating over
/// a dimmed base. That is how the native iOS spotlight works, and it explains the hierarchy: the
/// clipping happens in `clipView` rather than on the rail itself, so the ring's border and shadow
/// aren't cropped away.
final class WebCompatScreenshotRailView: UIView, ThemeApplicable {
    // Not `private`: the layout tests assert against these rather than mirroring copies that drift.
    enum UX {
        static let width: CGFloat = 44
        /// Between the rail and the content it maps.
        static let gap: CGFloat = 12
        static let cornerRadius: CGFloat = 10
        static let borderWidth: CGFloat = 2
        /// The base page is dimmed to this; the bright copy clipped over it marks the window.
        static let dimOpacity: CGFloat = 0.4
        /// Comfortably above `minimumHighlightHeight`, otherwise a wide page gives the highlight no
        /// room to travel and it sits frozen and overhanging.
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

    /// Derived from the rail's own height, so it holds still while scrolling and changes only when
    /// the geometry does.
    private var highlightHeight: CGFloat {
        guard bounds.height > 0 else { return UX.minimumHighlightHeight }
        return max(UX.minimumHighlightHeight, bounds.height * min(1, max(0, visibleFraction)))
    }

    // `private(set)`: the module's layout tests read these frames, nothing outside reassigns them.
    private(set) lazy var clipView: UIView = .build { view in
        // Rounds the dimmed page and keeps it inside the rail.
        view.clipsToBounds = true
        view.layer.cornerRadius = UX.cornerRadius
        view.layer.borderWidth = UX.borderWidth
    }

    /// The dimmed whole page behind the spotlight.
    private(set) lazy var dimmedPageView: UIImageView = makePageView(alpha: UX.dimOpacity)

    /// A bright copy cropped to the window, which is what gives the spotlight effect.
    private(set) lazy var spotlightContainer: UIView = .build { view in
        // The crop *is* the spotlight: it cuts the bright page down to the visible window.
        view.clipsToBounds = true
        view.layer.cornerRadius = UX.highlightCornerRadius
    }

    private(set) lazy var spotlightPageView: UIImageView = makePageView()

    private(set) lazy var highlightView: UIView = .build { view in
        view.layer.cornerRadius = UX.highlightCornerRadius
        view.layer.borderWidth = UX.highlightBorderWidth
        view.layer.shadowOpacity = UX.highlightShadowOpacity
        view.layer.shadowRadius = UX.highlightShadowRadius
        view.layer.shadowOffset = .zero
    }

    /// - Parameters:
    ///   - image: the whole page. Downsampled once for the two copies the rail draws.
    ///   - pageHeightToWidthRatio: the page's height over its width, which the caller has already
    ///     had to derive and sanitise for its own layout.
    init(image: UIImage?, pageHeightToWidthRatio: CGFloat) {
        self.pageHeightToWidthRatio = pageHeightToWidthRatio
        super.init(frame: .zero)

        // Not built through `.build`, so it has to opt out of the autoresizing mask itself or the
        // constraints below fight the ones UIKit synthesises for it.
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
            // Its size comes from the rail and never the other way round. At the default priority a
            // long page's intrinsic height ties with the rail's own height constraint and wins,
            // stretching the rail down the screen.
            imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
            imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        }
    }

    /// Both copies draw at rail width, so carrying the full capture would leave two extra layers
    /// holding a bitmap of the whole page. A tall enough capture also exceeds the maximum texture
    /// size, at which point the layer draws nothing at all.
    private func setupPageCopies(from image: UIImage?) {
        let railImage = image?.preparingThumbnail(
            of: CGSize(width: UX.width, height: UX.width * pageHeightToWidthRatio)
        ) ?? image
        dimmedPageView.image = railImage
        spotlightPageView.image = railImage
    }

    private func setupSubviews() {
        clipView.addSubview(dimmedPageView)
        spotlightContainer.addSubview(spotlightPageView)
        addSubviews(clipView, spotlightContainer, highlightView)
        // The rail maps content it doesn't own, so VoiceOver reads that content once, at the source.
        for view in [self, clipView, dimmedPageView, spotlightContainer, spotlightPageView, highlightView] {
            view.isAccessibilityElement = false
        }
    }

    private func setupConstraints() {
        let height = heightAnchor.constraint(equalToConstant: UX.width * pageHeightToWidthRatio)
        // Breakable, so a caller that caps the rail squashes a long page rather than reporting
        // unsatisfiable constraints.
        height.priority = .defaultHigh
        let highlightHeightConstraint = highlightView.heightAnchor.constraint(
            equalToConstant: UX.minimumHighlightHeight
        )
        self.highlightHeightConstraint = highlightHeightConstraint

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: UX.width),
            heightAnchor.constraint(greaterThanOrEqualToConstant: UX.minimumHeight),
            height,

            clipView.topAnchor.constraint(equalTo: topAnchor),
            clipView.leadingAnchor.constraint(equalTo: leadingAnchor),
            clipView.trailingAnchor.constraint(equalTo: trailingAnchor),
            clipView.bottomAnchor.constraint(equalTo: bottomAnchor),

            dimmedPageView.topAnchor.constraint(equalTo: clipView.topAnchor),
            dimmedPageView.leadingAnchor.constraint(equalTo: clipView.leadingAnchor),
            dimmedPageView.trailingAnchor.constraint(equalTo: clipView.trailingAnchor),
            dimmedPageView.bottomAnchor.constraint(equalTo: clipView.bottomAnchor),

            // The highlight sits at the top of the rail; `updateHighlightOffset()` slides it down.
            highlightView.topAnchor.constraint(equalTo: topAnchor),
            highlightView.leadingAnchor.constraint(equalTo: leadingAnchor),
            highlightView.trailingAnchor.constraint(equalTo: trailingAnchor),
            highlightHeightConstraint,

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
        // Derived from the height just resolved rather than from the layer's bounds, which is still
        // a pass behind. Without a path Core Animation traces the shadow from the layer's contents.
        highlightView.layer.shadowPath = UIBezierPath(
            roundedRect: CGRect(x: 0, y: 0, width: bounds.width, height: highlightHeight),
            cornerRadius: UX.highlightCornerRadius
        ).cgPath
    }

    private func applyHighlightHeight() {
        // Guarded, or assigning it every pass would invalidate the layout it was just given.
        guard highlightHeightConstraint?.constant != highlightHeight else { return }
        highlightHeightConstraint?.constant = highlightHeight
        // A caller that changes the fractions outside a layout pass gets the new height on the next
        // one rather than whenever something else happens to dirty the tree.
        setNeedsLayout()
    }

    /// Slides the window down the rail. A translation rather than a constraint constant because the
    /// caller updates mid-scroll, where a constant only takes effect on the next layout pass and
    /// the spotlight visibly trails the content.
    private func updateHighlightOffset() {
        let travel = max(0, bounds.height - highlightHeight)
        let offset = CGAffineTransform(translationX: 0, y: min(1, max(0, scrollFraction)) * travel)

        highlightView.transform = offset
        spotlightContainer.transform = offset
        // The inverse keeps the bright copy registered with the dimmed page underneath, so the
        // window moves while the slice it exposes stays put.
        spotlightPageView.transform = offset.inverted()
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        // Both strokes sit over the page the rail maps, which doesn't follow the app theme, so they
        // need a token that stays light in every palette. `borderInverted` and `iconSecondary` flip,
        // which put a white ring on a white page in the light themes.
        clipView.layer.borderColor = theme.colors.iconOnColor.cgColor
        highlightView.layer.borderColor = theme.colors.iconOnColor.cgColor
        highlightView.layer.shadowColor = theme.colors.shadowStrong.cgColor
    }
}
