// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a count of this file was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit

final class WorldcupCardCell: UICollectionViewCell, ReusableCell {
    struct UX {
        static let cornerRadius: CGFloat = 24
        static let paddingTop: CGFloat = 18
        static let paddingBottom: CGFloat = 18
        static let paddingLeading: CGFloat = 20
        static let paddingTrailing: CGFloat = 20
        static let contentSpacing: CGFloat = 10
        static let timerCornerRadius: CGFloat = 28
        static let timerContainerWidth: CGFloat = 250
        static let timerContainerHeight: CGFloat = 68
        static let heroWidth: CGFloat = 138
        static let dismissButtonSize = CGSize(width: 16, height: 16)
        static let shadowRadius: CGFloat = 4
        static let shadowOffset = CGSize(width: 0, height: 2)
        static let shadowOpacity: Float = 1
    }

    private var countdownTimer: Timer?
    private var targetDate: Date?
    private var kvoToken: NSKeyValueObservation?

    // MARK: - UI

    private lazy var cardView: UIView = .build { view in
        view.layer.cornerRadius = UX.cornerRadius
        view.clipsToBounds = true
    }

    private lazy var heroImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = FXFontStyles.Bold.subheadline.scaledFont()
        label.adjustsFontForContentSizeCategory = true
    }

    private lazy var timerContainer: UIView = .build { view in
        view.layer.cornerRadius = UX.timerCornerRadius
        view.clipsToBounds = true
    }

    private lazy var timerLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.title3.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
    }

    private lazy var ctaButton: PrimaryRoundedGlassButton = .build { button in
        button.addTarget(self, action: #selector(self.handleCTA), for: .touchUpInside)
    }

    private lazy var dismissButton: UIButton = .build { button in
        button.setImage(
            UIImage(named: StandardImageIdentifiers.Large.cross)?.withRenderingMode(.alwaysTemplate),
            for: .normal
        )
        button.addTarget(self, action: #selector(self.dismissCard), for: .touchUpInside)
    }

    private lazy var leftContentStack: UIStackView = .build { stack in
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = UX.contentSpacing
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        observeCardBounds()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        stopCountdownTimer()
        kvoToken?.invalidate()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopCountdownTimer()
        heroImageView.image = nil
        titleLabel.text = nil
        timerLabel.text = nil
    }

    // MARK: - Configure

    func configure(with config: WorldcupCardConfiguration, theme: Theme) {
        targetDate = config.targetDate
        titleLabel.text = config.title
        heroImageView.image = config.heroImage

        let buttonViewModel = PrimaryRoundedButtonViewModel(
            title: config.ctaButtonLabel,
            a11yIdentifier: "worldcupCTA"
        )
        ctaButton.configure(viewModel: buttonViewModel)

        updateCountdown()
        startCountdownTimer()
        applyTheme(theme: theme)
        ctaButton.applyTheme(theme: theme)
    }

    // MARK: - Countdown

    private func startCountdownTimer() {
        stopCountdownTimer()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateCountdown()
        }
    }

    private func stopCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    private func updateCountdown() {
        guard let targetDate else { return }
        let now = Date()
        let diff = Calendar.current.dateComponents([.day, .hour, .minute], from: now, to: targetDate)
        let days = max(diff.day ?? 0, 0)
        let hours = max(diff.hour ?? 0, 0)
        let minutes = max(diff.minute ?? 0, 0)
        timerLabel.text = String(format: "%dd %02dh %02dm", days, hours, minutes)
    }

    // MARK: - Layout

    private func setupLayout() {
        timerContainer.addSubview(timerLabel)
        leftContentStack.addArrangedSubview(titleLabel)
        leftContentStack.addArrangedSubview(timerContainer)

        // Hero is added first (bottom of z-order), content on top
        cardView.addSubviews(heroImageView, leftContentStack, ctaButton, dismissButton)
        contentView.addSubview(cardView)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            heroImageView.topAnchor.constraint(equalTo: cardView.topAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            heroImageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            heroImageView.widthAnchor.constraint(equalToConstant: UX.heroWidth),

            dismissButton.topAnchor.constraint(equalTo: cardView.topAnchor, constant: UX.paddingTop),
            dismissButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -UX.paddingTrailing),
            dismissButton.widthAnchor.constraint(equalToConstant: UX.dismissButtonSize.width),
            dismissButton.heightAnchor.constraint(equalToConstant: UX.dismissButtonSize.height),

            leftContentStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: UX.paddingTop),
            leftContentStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: UX.paddingLeading),
            leftContentStack.trailingAnchor.constraint(
                lessThanOrEqualTo: heroImageView.leadingAnchor,
                constant: -UX.paddingTrailing
            ),

            timerContainer.widthAnchor.constraint(equalToConstant: UX.timerContainerWidth),
            timerContainer.heightAnchor.constraint(equalToConstant: UX.timerContainerHeight),

            timerLabel.centerXAnchor.constraint(equalTo: timerContainer.centerXAnchor),
            timerLabel.centerYAnchor.constraint(equalTo: timerContainer.centerYAnchor),

            ctaButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: UX.paddingLeading),
            ctaButton.trailingAnchor.constraint(
                lessThanOrEqualTo: heroImageView.leadingAnchor,
                constant: -UX.paddingTrailing
            ),
            ctaButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -UX.paddingBottom),
        ])
    }

    private func observeCardBounds() {
        kvoToken = cardView.observe(\.bounds, options: .new) { [weak self] _, _ in
            ensureMainThread { [weak self] in
                self?.updateShadow()
            }
        }
    }

    private func updateShadow() {
        cardView.layer.shadowPath = UIBezierPath(
            roundedRect: cardView.bounds,
            cornerRadius: UX.cornerRadius
        ).cgPath
    }

    // MARK: - Actions

    @objc private func handleCTA() { }

    @objc private func dismissCard() { }
}

// MARK: - Blurrable

extension WorldcupCardCell: Blurrable {
    func adjustBlur(theme: Theme) {
        if shouldApplyWallpaperBlur {
            cardView.addBlurEffectWithClearBackgroundAndClipping(using: .systemThickMaterial)
            timerContainer.addBlurEffectWithClearBackgroundAndClipping(using: .systemUltraThinMaterial)
        } else {
            cardView.removeVisualEffectView()
            timerContainer.removeVisualEffectView()
            cardView.backgroundColor = theme.colors.layer5
            timerContainer.backgroundColor = theme.colors.layer4
            cardView.layer.shadowColor = theme.colors.shadowDefault.cgColor
            cardView.layer.shadowOffset = UX.shadowOffset
            cardView.layer.shadowOpacity = UX.shadowOpacity
            cardView.layer.shadowRadius = UX.shadowRadius
            updateShadow()
        }
    }
}

// MARK: - ThemeApplicable

extension WorldcupCardCell: ThemeApplicable {
    func applyTheme(theme: Theme) {
        titleLabel.textColor = theme.colors.textPrimary
        timerLabel.textColor = theme.colors.textPrimary
        dismissButton.imageView?.tintColor = theme.colors.textPrimary
        backgroundColor = .clear
        adjustBlur(theme: theme)
    }
}
