// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SiteImageView
import Common

final class TabWebViewPreview: UIView {
    private struct UX {
        static let faviconCornerRadius: CGFloat = 20.0
        static let faviconImageViewSize: CGFloat = 45.0
    }
    private lazy var webPageScreenshotImageView: UIImageView = .build {
        $0.contentMode = .top
        $0.clipsToBounds = true
    }
    private lazy var faviconImageView: FaviconImageView = .build()
    /// Wether the next screenshot has invalid layout. When this is true we draw only the Favicon in the preview
    private var layoutWasInvalidated = false
    private var screenCornerRadius: CGFloat {
        return UIScreen.main.value(forKey: "_displayCornerRadius") as? CGFloat ?? 0.0
    }

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
        webPageScreenshotImageView.layer.cornerRadius = screenCornerRadius
        addSubviews(webPageScreenshotImageView, faviconImageView)

        NSLayoutConstraint.activate([
            webPageScreenshotImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webPageScreenshotImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webPageScreenshotImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            webPageScreenshotImageView.topAnchor.constraint(equalTo: topAnchor),

            faviconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            faviconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            faviconImageView.heightAnchor.constraint(equalToConstant: UX.faviconImageViewSize),
            faviconImageView.widthAnchor.constraint(equalToConstant: UX.faviconImageViewSize)
        ])
    }

    // MARK: - Public Functions

    /// Invalidates the current screenshot data, thus showing only the Favicon as the preview for the website.
    func invalidateScreenshotData() {
        layoutWasInvalidated = true
    }

    func setScreenshot(_ tab: Tab?) {
        guard let tab else {
            faviconImageView.isHidden = true
            webPageScreenshotImageView.isHidden = true
            return
        }
        faviconImageView.isHidden = !layoutWasInvalidated
        webPageScreenshotImageView.isHidden = layoutWasInvalidated

        if layoutWasInvalidated {
            if tab.isFxHomeTab {
                faviconImageView.manuallySetImage(UIImage(resource: .faviconFox))
            } else {
                faviconImageView.setFavicon(FaviconImageViewModel(siteURLString: tab.url?.absoluteString,
                                                                  faviconCornerRadius: UX.faviconCornerRadius))
            }
        } else if let screenshot = tab.screenshot {
            if screenshot.size.width > webPageScreenshotImageView.bounds.size.width {
                webPageScreenshotImageView.contentMode = .scaleAspectFill
            } else {
                webPageScreenshotImageView.contentMode = .top
            }
            webPageScreenshotImageView.image = screenshot
        }
    }

    func setScreenshot(_ image: UIImage?) {
        faviconImageView.isHidden = true
        webPageScreenshotImageView.isHidden = false
        webPageScreenshotImageView.image = image
    }

    func applyTransform(translationX: CGFloat) {
        webPageScreenshotImageView.transform = CGAffineTransform(translationX: translationX, y: 0)
    }

    func transitionDidEnd() {
        layoutWasInvalidated = false
    }
}
