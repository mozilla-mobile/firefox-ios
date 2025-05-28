// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class TabWebViewPreview: UIView,
                               ThemeApplicable {
    private struct UX {
        static let addressBarCornerRadius: CGFloat = 8
        static let addressBarBorderHeight: CGFloat = 1
        static let addressBarHeight: CGFloat = 44
        static let addressBarMaxHeight: CGFloat = 54
        static let edgePadding: CGFloat = 7
        static let addressBarOnTopLayoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        static let addressBarOnBottomLayoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 4, right: 16)
    }

    var notificationCenter: any NotificationProtocol = NotificationCenter.default

    private lazy var webPageScreenshotImageView: UIImageView = .build()
    private var previewTopConstraint: NSLayoutConstraint?

    // MARK: - Inits
    init() {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout
    private func setupLayout() {
        webPageScreenshotImageView.contentMode = .top
        webPageScreenshotImageView.clipsToBounds = true
        addSubview(webPageScreenshotImageView)

        previewTopConstraint = webPageScreenshotImageView.topAnchor.constraint(equalTo: topAnchor)
        previewTopConstraint?.isActive = true
        NSLayoutConstraint.activate([
            webPageScreenshotImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webPageScreenshotImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webPageScreenshotImageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Public Functions

    /// Updates the layout based on the given search bar position.
    ///
    /// - Parameter searchBarPosition: The position of the search bar, either `.top` or `.bottom`.
    func updateLayoutBasedOn(searchBarPosition: SearchBarPosition, anchor: NSLayoutYAxisAnchor) {
        previewTopConstraint?.isActive = false
        switch searchBarPosition {
        case .top:
            previewTopConstraint = webPageScreenshotImageView.topAnchor.constraint(equalTo: anchor)
        case .bottom:
            previewTopConstraint = webPageScreenshotImageView.topAnchor.constraint(equalTo: topAnchor)
        }
        previewTopConstraint?.isActive = true
    }

    func setScreenshot(_ image: UIImage?) {
        if image?.size.width ?? 0.0 > webPageScreenshotImageView.bounds.size.width {
            webPageScreenshotImageView.contentMode = .scaleAspectFill
        } else {
            webPageScreenshotImageView.contentMode = .top
        }
        webPageScreenshotImageView.image = image
    }

    func setHomepage(_ content: HomepageViewController) {
        guard content.view.superview != self else { return }
        addSubview(content.view)
        content.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.view.topAnchor.constraint(equalTo: topAnchor),
            content.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            content.view.bottomAnchor.constraint(equalTo: bottomAnchor),
            content.view.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    func applyTransform(translationX: CGFloat, velocityX: CGFloat) {
        webPageScreenshotImageView.transform = CGAffineTransform(translationX: translationX, y: 0)
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {}
}
