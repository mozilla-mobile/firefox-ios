// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class TabWebViewPreview: UIView, ThemeApplicable {
    // MARK: - UX Constants
    private struct UX {
        static let addressBarCornerRadius = CGFloat(8)
        static let layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        static let addressBarBorderHeight = CGFloat(1)
        static let addressBarHeight = CGFloat(43)
    }
    // MARK: - UI Properties
    private lazy var webPageScreenshotImageView: UIImageView = .build()
    private lazy var addressBarBorderView: UIView = .build()

    private lazy var topStackView = createStackView()
    private lazy var bottomStackView = createStackView()

    private lazy var skeletonAddressBar: UIView = .build { addressBar in
        addressBar.layer.cornerRadius = UX.addressBarCornerRadius
    }

    // MARK: - Constraint Properties
    private var webViewTopConstraint: NSLayoutConstraint?
    private var webViewBottomConstraint: NSLayoutConstraint?
    private var addressBarBorderViewTopBottomConstraint: NSLayoutConstraint?

    // MARK: Inits
    init() {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout
    private func setupLayout() {
        addSubviews(topStackView, webPageScreenshotImageView, addressBarBorderView, bottomStackView)

        NSLayoutConstraint.activate([
            addressBarBorderView.heightAnchor.constraint(equalToConstant: UX.addressBarBorderHeight),
            addressBarBorderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            addressBarBorderView.trailingAnchor.constraint(equalTo: trailingAnchor),

            skeletonAddressBar.heightAnchor.constraint(equalToConstant: UX.addressBarHeight),

            topStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            topStackView.topAnchor.constraint(equalTo: topAnchor),
            topStackView.rightAnchor.constraint(equalTo: rightAnchor),

            webPageScreenshotImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webPageScreenshotImageView.trailingAnchor.constraint(equalTo: trailingAnchor),

            bottomStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomStackView.rightAnchor.constraint(equalTo: rightAnchor)
        ])
    }

    func updateLayoutBasedOn(searchBarPosition: SearchBarPosition) {
        topStackView.removeAllArrangedViews()
        bottomStackView.removeAllArrangedViews()

        webViewTopConstraint?.isActive = false
        webViewBottomConstraint?.isActive = false
        addressBarBorderViewTopBottomConstraint?.isActive = false

        switch searchBarPosition {
        case .bottom:
            bottomStackView.addArrangedSubview(skeletonAddressBar)
            webViewTopConstraint = webPageScreenshotImageView.topAnchor.constraint(equalTo: topAnchor)
            webViewBottomConstraint = webPageScreenshotImageView.bottomAnchor.constraint(equalTo: bottomStackView.topAnchor)
            addressBarBorderViewTopBottomConstraint = addressBarBorderView.bottomAnchor
                .constraint(equalTo: bottomStackView.topAnchor)
        case .top:
            topStackView.addArrangedSubview(skeletonAddressBar)
            webViewBottomConstraint = webPageScreenshotImageView.bottomAnchor.constraint(equalTo: bottomAnchor)
            webViewTopConstraint = webPageScreenshotImageView.topAnchor.constraint(equalTo: topStackView.bottomAnchor)
            addressBarBorderViewTopBottomConstraint = addressBarBorderView.topAnchor
                .constraint(equalTo: topStackView.bottomAnchor)
        }

        webViewTopConstraint?.isActive = true
        webViewBottomConstraint?.isActive = true
        addressBarBorderViewTopBottomConstraint?.isActive = true
    }

    private func createStackView() -> UIStackView {
        return .build { stackView in
            stackView.axis = .vertical
            stackView.isLayoutMarginsRelativeArrangement = true
            stackView.layoutMargins = UX.layoutMargins
        }
    }

    func setScreenshot(_ image: UIImage?) {
        webPageScreenshotImageView.image = image
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Common.Theme) {
        let colors = theme.colors
        addressBarBorderView.backgroundColor = colors.borderPrimary
        bottomStackView.backgroundColor = colors.layer1
        skeletonAddressBar.backgroundColor = colors.layerSearch
    }
}
