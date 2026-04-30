// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Shared
import UIKit

final class WorldCupTimerCell: UICollectionViewCell, ReusableCell, Blurrable, ThemeApplicable {
    private struct UX {
        static let cardCornerRadius: CGFloat = 24
        static let cardPaddingTop: CGFloat = 18
        static let cardPaddingBottom: CGFloat = 18
        static let cardPaddingLeading: CGFloat = 20
        static let cardPaddingTrailing: CGFloat = 20
        static let cardContentSpacing: CGFloat = 8.0
        static let timerVerticalPadding: CGFloat = 8
        static let timerHorizontalPadding: CGFloat = 64
        static let timerSegmentSpacing: CGFloat = 8.0
        static let dismissButtonSize = CGSize(width: 16, height: 16)
        static let heroImageWidth: CGFloat = 120
        static let heroImageTrailingPadding: CGFloat = 24.0
        static let heroGifName = "kitHeroGif"
        static let heroImageName = "kitHero"
        static let heroFrameDuration = 0.04
        static let heroInitialFramePosition = 0.7
        static let heroAnimationRepeatCount = 2
    }

    private var countdownModel: WorldCupCountdownModel?
    var onCTATapped: (() -> Void)?
    var onDismiss: (() -> Void)?

    private var heroVisibleConstraints: [NSLayoutConstraint] = []
    private var heroHiddenConstraints: [NSLayoutConstraint] = []

    // MARK: - UI

    private lazy var cardView: UIView = .build { view in
        view.layer.cornerRadius = UX.cardCornerRadius
        view.clipsToBounds = true
    }

    private lazy var heroImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = false

        guard let gifImage = UIImage.gifFromBundle(named: UX.heroGifName,
                                                   frameDuration: UX.heroFrameDuration),
              let frames = gifImage.images, !frames.isEmpty else {
            imageView.image = UIImage(named: UX.heroImageName)
            return
        }
        imageView.image = frames[Int(Double(frames.count) * UX.heroInitialFramePosition)]
        imageView.animationImages = frames
        imageView.animationDuration = gifImage.duration
        imageView.animationRepeatCount = UX.heroAnimationRepeatCount
        imageView.startAnimating()
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = FXFontStyles.Bold.body.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.text = String.WorldCup.HomepageWidget.CountDown.Title
        label.textAlignment = .natural
        label.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private lazy var timerContainer: UIView = .build { view in
        view.clipsToBounds = true
        view.isAccessibilityElement = true
        view.accessibilityTraits = .staticText
    }

    private lazy var dayValueLabel: UILabel = makeValueLabel()
    private lazy var hourValueLabel: UILabel = makeValueLabel()
    private lazy var minuteValueLabel: UILabel = makeValueLabel()

    private lazy var dayUnitLabel: UILabel = makeUnitLabel(
        text: String.WorldCup.HomepageWidget.CountDown.DayLabel
    )
    private lazy var hourUnitLabel: UILabel = makeUnitLabel(
        text: String.WorldCup.HomepageWidget.CountDown.HourLabel
    )
    private lazy var minuteUnitLabel: UILabel = makeUnitLabel(
        text: String.WorldCup.HomepageWidget.CountDown.MinuteLabel
    )

    private lazy var timerStack: UIStackView = .build { stack in
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.spacing = UX.timerSegmentSpacing
    }

    private lazy var ctaButton: PrimaryRoundedGlassButton = .build { [weak self] button in
        let buttonViewModel = PrimaryRoundedButtonViewModel(
            title: String.WorldCup.HomepageWidget.CountDown.ViewScheduleButtonLabel,
            a11yIdentifier: ""
        )
        button.configure(viewModel: buttonViewModel)
        button.configuration?.titleLineBreakMode = .byWordWrapping
        button.titleLabel?.numberOfLines = 0
        button.setContentCompressionResistancePriority(.required, for: .vertical)
        button.addAction(
            UIAction { [weak self] _ in
                self?.onCTATapped?()
            },
            for: .touchUpInside)
    }

    private lazy var dismissButton: UIButton = .build { [weak self] button in
        button.setImage(
            UIImage(named: StandardImageIdentifiers.Large.cross)?.withRenderingMode(.alwaysTemplate),
            for: .normal
        )
        button.accessibilityLabel = .WorldCup.HomepageWidget.FollowTeamCard.CloseButtonAccessibilityLabel
        button.addAction(
            UIAction { [weak self] _ in
                self?.onDismiss?()
            },
            for: .touchUpInside)
    }

    private lazy var leftContentStack: UIStackView = .build { stack in
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = UX.cardContentSpacing
        stack.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    private func setupLayout() {
        let daySegment = makeSegmentStack(valueLabel: dayValueLabel, unitLabel: dayUnitLabel)
        let colon1 = makeColonStack()
        let hourSegment = makeSegmentStack(valueLabel: hourValueLabel, unitLabel: hourUnitLabel)
        let colon2 = makeColonStack()
        let minuteSegment = makeSegmentStack(valueLabel: minuteValueLabel, unitLabel: minuteUnitLabel)

        [daySegment, colon1, hourSegment, colon2, minuteSegment].forEach {
            timerStack.addArrangedSubview($0)
        }

        timerContainer.addSubview(timerStack)
        leftContentStack.addArrangedSubview(titleLabel)
        leftContentStack.addArrangedSubview(timerContainer)
        leftContentStack.addArrangedSubview(ctaButton)

        cardView.addSubviews(leftContentStack, heroImageView, dismissButton)
        contentView.addSubview(cardView)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            heroImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            heroImageView.trailingAnchor.constraint(
                equalTo: dismissButton.leadingAnchor,
                constant: -UX.heroImageTrailingPadding
            ),
            heroImageView.widthAnchor.constraint(lessThanOrEqualToConstant: UX.heroImageWidth),
            heroImageView.heightAnchor.constraint(lessThanOrEqualToConstant: UX.heroImageWidth),
            heroImageView.topAnchor.constraint(equalTo: cardView.topAnchor).priority(.defaultLow),
            heroImageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor).priority(.defaultLow),

            dismissButton.topAnchor.constraint(equalTo: cardView.topAnchor, constant: UX.cardPaddingTop),
            dismissButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -UX.cardPaddingTrailing),
            dismissButton.widthAnchor.constraint(equalToConstant: UX.dismissButtonSize.width),
            dismissButton.heightAnchor.constraint(equalToConstant: UX.dismissButtonSize.height),

            leftContentStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: UX.cardPaddingTop),
            leftContentStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: UX.cardPaddingLeading),

            timerStack.topAnchor.constraint(
                equalTo: timerContainer.topAnchor,
                constant: UX.timerVerticalPadding
            ),
            timerStack.bottomAnchor.constraint(
                equalTo: timerContainer.bottomAnchor,
                constant: -UX.timerVerticalPadding
            ),
            timerStack.centerXAnchor.constraint(equalTo: timerContainer.centerXAnchor),
            timerStack.leadingAnchor.constraint(
                equalTo: timerContainer.leadingAnchor,
                constant: UX.timerHorizontalPadding
            ).priority(.defaultLow),
            timerStack.trailingAnchor.constraint(
                equalTo: timerContainer.trailingAnchor,
                constant: -UX.timerHorizontalPadding
            ).priority(.defaultLow),

            leftContentStack.bottomAnchor.constraint(
                equalTo: cardView.bottomAnchor,
                constant: -UX.cardPaddingBottom
            ),
        ])

        heroVisibleConstraints = [
            leftContentStack.trailingAnchor.constraint(equalTo: heroImageView.leadingAnchor),
        ]

        heroHiddenConstraints = [
            leftContentStack.trailingAnchor.constraint(
                equalTo: cardView.trailingAnchor,
                constant: -UX.cardPaddingTrailing
            ),
        ]

        updateA11yLayout()
    }

    private func makeValueLabel() -> UILabel {
        let label = UILabel()
        label.font = FXFontStyles.Bold.title3.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }

    private func makeUnitLabel(text: String) -> UILabel {
        let label = UILabel()
        label.font = FXFontStyles.Regular.caption1.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.text = text
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private func makeSegmentStack(valueLabel: UILabel, unitLabel: UILabel) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [valueLabel, unitLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    private func makeColonStack() -> UIStackView {
        let colonLabel = UILabel()
        colonLabel.font = FXFontStyles.Bold.title3.scaledFont()
        colonLabel.adjustsFontForContentSizeCategory = true
        colonLabel.textAlignment = .center
        colonLabel.text = ":"
        colonLabel.translatesAutoresizingMaskIntoConstraints = false

        let spacer = UILabel()
        spacer.font = FXFontStyles.Regular.caption1.scaledFont()
        spacer.adjustsFontForContentSizeCategory = true
        spacer.text = " "
        spacer.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [colonLabel, spacer])
        stack.axis = .vertical
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isAccessibilityElement = false
        return stack
    }

    // MARK: - Configure

    func configure(
        theme: Theme,
        profile: Profile = AppContainer.shared.resolve(),
        onCTATapped: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.onCTATapped = onCTATapped
        self.onDismiss = onDismiss
        let model = WorldCupCountdownModel(prefs: profile.prefs)
        model.onCountdownUpdated = { [weak self] countdown in
            self?.apply(countdown: countdown)
        }
        model.start()
        countdownModel = model
        applyTheme(theme: theme)
    }

    // MARK: - Countdown

    private func apply(countdown: WorldCupCountdown) {
        dayValueLabel.text = String(format: "%02d", countdown.days)
        hourValueLabel.text = String(format: "%02d", countdown.hours)
        minuteValueLabel.text = String(format: "%02d", countdown.minutes)

        timerContainer.accessibilityLabel = DateComponentsFormatter.localizedString(
            from: countdown.components,
            unitsStyle: .spellOut)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        timerContainer.layoutIfNeeded()
        timerContainer.layer.cornerRadius = timerContainer.bounds.height / 2
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory
        else { return }
        updateA11yLayout()
    }

    private func updateA11yLayout() {
        let isA11y = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        heroImageView.isHidden = isA11y
        leftContentStack.alignment = isA11y ? .fill : .leading

        NSLayoutConstraint.deactivate(isA11y ? heroVisibleConstraints : heroHiddenConstraints)
        NSLayoutConstraint.activate(isA11y ? heroHiddenConstraints : heroVisibleConstraints)
    }

    // MARK: - Blurrable

    func adjustBlur(theme: Theme) {
        if shouldApplyWallpaperBlur {
            cardView.addBlurEffectWithClearBackgroundAndClipping(using: .systemThickMaterial)
        } else {
            cardView.removeVisualEffectView()
        }
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        titleLabel.textColor = theme.colors.textPrimary
        [dayValueLabel, hourValueLabel, minuteValueLabel].forEach {
            $0.textColor = theme.colors.textPrimary
        }
        [dayUnitLabel, hourUnitLabel, minuteUnitLabel].forEach {
            $0.textColor = theme.colors.textPrimary
        }
        dismissButton.imageView?.tintColor = theme.colors.textPrimary
        backgroundColor = .clear
        adjustBlur(theme: theme)
        ctaButton.applyTheme(theme: theme)
        cardView.backgroundColor = theme.colors.layer5
        timerContainer.backgroundColor = theme.colors.layer3
        cardView.applyShadow(FxShadow.shadow200, theme: theme)
    }
}
