// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

class TemporaryDocumentLoadingView: UIView, ThemeApplicable {
    private struct UX {
        static let loadingBackgroundViewCornerRadius: CGFloat = 12.0
        static let loadingContainerViewSpacing: CGFloat = 8.0
        static let loadingContainerViewSidePadding: CGFloat = 20.0
        static let backgroundColorAlpha: CGFloat = 0.3
        static let animationDuration: CGFloat = 0.3
    }

    private let loadingBackgroundView: UIView = .build { view in
        view.layer.cornerRadius = UX.loadingBackgroundViewCornerRadius
    }

    private let loadingContainerView: UIStackView = .build { view in
        view.axis = .vertical
        view.spacing = UX.loadingContainerViewSpacing
    }

    private let loadingView: UIActivityIndicatorView = .build { view in
        view.style = .medium
    }

    private let backgroundView: UIVisualEffectView = .build { view in
        view.effect = UIBlurEffect(style: .systemThinMaterial)
    }

    private let loadingLabel: UILabel = .build { view in
        view.text = .WebView.DocumentLoadingLabel
        view.accessibilityLabel = .WebView.DocumentLoadingAccessibilityLabel
        view.accessibilityIdentifier = AccessibilityIdentifiers.Browser.WebView.documentLoadingLabel
        view.font = FXFontStyles.Regular.footnote.scaledFont()
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private var appearanceAnimator: UIViewPropertyAnimator?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    private func setup() {
        addSubviews(backgroundView, loadingBackgroundView)

        loadingContainerView.addArrangedSubview(loadingView)
        loadingContainerView.addArrangedSubview(loadingLabel)

        loadingBackgroundView.addSubview(loadingContainerView)

        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),

            loadingBackgroundView.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingBackgroundView.centerYAnchor.constraint(equalTo: centerYAnchor),

            loadingContainerView.leadingAnchor.constraint(equalTo: loadingBackgroundView.leadingAnchor,
                                                          constant: UX.loadingContainerViewSidePadding),
            loadingContainerView.trailingAnchor.constraint(equalTo: loadingBackgroundView.trailingAnchor,
                                                           constant: -UX.loadingContainerViewSidePadding),
            loadingContainerView.topAnchor.constraint(equalTo: loadingBackgroundView.topAnchor,
                                                      constant: UX.loadingContainerViewSidePadding),
            loadingContainerView.bottomAnchor.constraint(equalTo: loadingBackgroundView.bottomAnchor,
                                                         constant: -UX.loadingContainerViewSidePadding)
        ])

        backgroundView.alpha = 0.0
        loadingBackgroundView.alpha = 0.0
        loadingView.startAnimating()
    }

    func animateLoadingAppearanceIfNeeded(_ completion: (() -> Void)? = nil) {
        appearanceAnimator?.stopAnimation(true)
        appearanceAnimator = UIViewPropertyAnimator(duration: UX.animationDuration, curve: .easeOut) {
            self.backgroundView.alpha = 1
            self.loadingBackgroundView.alpha = 1
        }
        appearanceAnimator?.addCompletion { _ in
            completion?()
        }
        appearanceAnimator?.startAnimation()
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: any Theme) {
        backgroundColor = theme.colors.layerScrim.withAlphaComponent(UX.backgroundColorAlpha)
        loadingBackgroundView.backgroundColor = theme.colors.layer2
        loadingView.color = theme.colors.iconPrimary
        loadingLabel.textColor = theme.colors.textPrimary
    }
}
