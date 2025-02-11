// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

class TemporaryDocumentLoadingView: UIView, ThemeApplicable {
    private struct UX {
        static let loadingBackgroundViewCornerRadius: CGFloat = 12.0
    }

    private let loadingBackgroundView = UIView()
    private let loadingContainerView = UIStackView()
    private let loadingView = UIActivityIndicatorView(style: .large)
    private let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
    private let filenameLabel = UILabel()
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
        backgroundView.alpha = 0.0
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundView)
        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        loadingBackgroundView.alpha = 0.0
        loadingBackgroundView.layer.cornerRadius = UX.loadingBackgroundViewCornerRadius
        loadingBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(loadingBackgroundView)
        NSLayoutConstraint.activate([
            loadingBackgroundView.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingBackgroundView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        loadingContainerView.axis = .vertical
        loadingContainerView.spacing = 8.0
        loadingContainerView.translatesAutoresizingMaskIntoConstraints = false
        loadingBackgroundView.addSubview(loadingContainerView)
        NSLayoutConstraint.activate([
            loadingContainerView.leadingAnchor.constraint(equalTo: loadingBackgroundView.leadingAnchor, constant: 20.0),
            loadingContainerView.trailingAnchor.constraint(equalTo: loadingBackgroundView.trailingAnchor, constant: -20.0),
            loadingContainerView.topAnchor.constraint(equalTo: loadingBackgroundView.topAnchor, constant: 20.0),
            loadingContainerView.bottomAnchor.constraint(equalTo: loadingBackgroundView.bottomAnchor, constant: -20.0)
        ])

        loadingView.alpha = 0.0
        loadingView.style = .medium
        loadingView.startAnimating()
        loadingView.translatesAutoresizingMaskIntoConstraints = false

        filenameLabel.alpha = 0.0
        filenameLabel.translatesAutoresizingMaskIntoConstraints = false
        filenameLabel.text = "PDF Loading"
        filenameLabel.font = FXFontStyles.Regular.footnote.scaledFont()

        filenameLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        loadingContainerView.addArrangedSubview(loadingView)
        loadingContainerView.addArrangedSubview(filenameLabel)
    }

    func animateLoadingAppearanceIfNeeded(_ completion: (() -> Void)? = nil) {
        appearanceAnimator?.stopAnimation(true)
        appearanceAnimator = UIViewPropertyAnimator(duration: 0.3, curve: .easeIn) {
            self.backgroundView.alpha = 1
            self.filenameLabel.alpha = 1
            self.loadingView.alpha = 1
            self.loadingBackgroundView.alpha = 1
        }
        appearanceAnimator?.addCompletion { _ in
            completion?()
        }
        appearanceAnimator?.startAnimation()
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: any Theme) {
        backgroundColor = theme.colors.layerScrim.withAlphaComponent(0.4)
        loadingBackgroundView.backgroundColor = theme.colors.layer2
        loadingView.color = theme.colors.iconPrimary
        filenameLabel.textColor = theme.colors.textPrimary
    }
}
