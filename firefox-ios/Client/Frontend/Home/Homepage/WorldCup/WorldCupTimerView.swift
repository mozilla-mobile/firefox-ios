// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Shared
import UIKit

final class WorldCupTimerView: UIView, ThemeApplicable {
    private struct UX {
        static let horizontalPadding: CGFloat = 16.0
        static let leftContentStackSpacing: CGFloat = 16.0
        static let timerVerticalPadding: CGFloat = 8
        static let timerHorizontalPadding: CGFloat = 64
        static let timerSegmentSpacing: CGFloat = 8.0
        static let dismissButtonSize = CGSize(width: 16, height: 16)
        static let heroImageWidth: CGFloat = 160
        static let heroImageHeight: CGFloat = 140.0
        static let heroImageTrailingPadding: CGFloat = 12.0
        static let heroGifName = "kitHeroGif"
        static let heroImageName = "kitHero"
        static let heroFrameDuration = 0.04
        static let heroInitialFramePosition = 0.7
        static let heroAnimationRepeatCount = 2
        static let scheduleURL = "https://www.fifa.com/tournaments/mens/worldcup/canadamexicousa2026/scores-fixtures"
    }

    private let windowUUID: WindowUUID
    private let profile: Profile
    private var countdownModel: WorldCupCountdownModel?
    private let telemetry = WorldCupTelemetry()

    private var heroVisibleConstraints: [NSLayoutConstraint] = []
    private var heroHiddenConstraints: [NSLayoutConstraint] = []

    // MARK: - UI

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
        label.setContentHuggingPriority(.required, for: .vertical)
    }

    private lazy var timerContainer: UIView = .build { view in
        view.clipsToBounds = true
        view.isAccessibilityElement = true
        view.accessibilityTraits = .staticText
        view.setContentCompressionResistancePriority(.required, for: .vertical)
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
        stack.distribution = .equalSpacing
        stack.spacing = UX.timerSegmentSpacing
        stack.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private lazy var ctaButton: PrimaryRoundedButton = .build { [weak self] button in
        button.configuration?.titleLineBreakMode = .byWordWrapping
        button.titleLabel?.numberOfLines = 0
    }

    /// The action button can represent either a close button with `X` icon for milestone 1 or a an option button with `...` icon for milestone2 and more.
    private lazy var actionButton: UIButton = .build { button in
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private lazy var leftContentStack: UIStackView = .build { stack in
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = UX.leftContentStackSpacing
        stack.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    // MARK: - Init

    init(
        windowUUID: WindowUUID,
        profile: Profile = AppContainer.shared.resolve()
    ) {
        self.windowUUID = windowUUID
        self.profile = profile
        super.init(frame: .zero)
        setupLayout()
        startCountdown()
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

        addSubviews(leftContentStack, heroImageView, actionButton)

        NSLayoutConstraint.activate([
            heroImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            heroImageView.trailingAnchor.constraint(
                equalTo: actionButton.leadingAnchor,
                constant: -UX.heroImageTrailingPadding
            ),
            heroImageView.widthAnchor.constraint(lessThanOrEqualToConstant: UX.heroImageWidth),
            heroImageView.heightAnchor.constraint(lessThanOrEqualToConstant: UX.heroImageHeight),
            heroImageView.topAnchor.constraint(equalTo: topAnchor).priority(.defaultLow),
            heroImageView.bottomAnchor.constraint(equalTo: bottomAnchor).priority(.defaultLow),

            actionButton.topAnchor.constraint(equalTo: topAnchor),
            actionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.horizontalPadding),
            actionButton.widthAnchor.constraint(equalToConstant: UX.dismissButtonSize.width),
            actionButton.heightAnchor.constraint(equalToConstant: UX.dismissButtonSize.height),

            leftContentStack.topAnchor.constraint(equalTo: topAnchor),
            leftContentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.horizontalPadding),

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

            leftContentStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        heroVisibleConstraints = [
            leftContentStack.trailingAnchor.constraint(equalTo: heroImageView.leadingAnchor),
        ]

        heroHiddenConstraints = [
            leftContentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.horizontalPadding),
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

    func configure(state: WorldCupSectionState) {
        if state.isMilestone2 {
            configureMilestone2Actions()
        } else {
            configureMilestone1Actions()
        }
    }

    private func configureMilestone2Actions() {
        ctaButton.configure(viewModel: .init(title: .WorldCup.HomepageWidget.FollowTeamCard.CTA, a11yIdentifier: ""))
        ctaButton.addAction(
            UIAction(
                handler: { [weak self] _ in
                    self?.navigateToTeamSelection()
                }),
            for: .touchUpInside
        )
        let changeTeamAction = UIAction(
            title: .WorldCup.HomepageWidget.ChangeTeamLabel,
            image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.soccerBall),
            handler: { [weak self] _ in
                self?.navigateToTeamSelection()
            }
        )
        let removeAction = UIAction(
            title: .WorldCup.HomepageWidget.RemoveLabel,
            image: UIImage.templateImageNamed(
                StandardImageIdentifiers.Large.cross
            ),
            attributes: .destructive,
            handler: { [weak self] _ in
                self?.dismiss()
            }
        )
        let menu = UIMenu(children: [changeTeamAction, removeAction])
        actionButton.menu = menu
        actionButton.showsMenuAsPrimaryAction = true
        actionButton.setImage(
            UIImage(named: StandardImageIdentifiers.Large.moreHorizontalRound)?
                .withRenderingMode(.alwaysTemplate),
            for: .normal
        )
        actionButton.accessibilityLabel = .WorldCup.HomepageWidget.SettingsButtonAccessibilityLabel
        actionButton.largeContentTitle = .WorldCup.HomepageWidget.SettingsButtonAccessibilityLabel
    }

    private func configureMilestone1Actions() {
        ctaButton.configure(
            viewModel: .init(
                title: .WorldCup.HomepageWidget.CountDown.ViewScheduleButtonLabel,
                a11yIdentifier: ""
            )
        )
        ctaButton.addAction(
            UIAction { [weak self] _ in
                self?.navigateToScheduleURL()
            },
            for: .touchUpInside)
        actionButton.showsMenuAsPrimaryAction = false
        actionButton.setImage(
            UIImage(named: StandardImageIdentifiers.Large.cross)?.withRenderingMode(.alwaysTemplate),
            for: .normal
        )
        actionButton.accessibilityLabel = .WorldCup.HomepageWidget.FollowTeamCard.CloseButtonAccessibilityLabel
        actionButton.largeContentTitle = .WorldCup.HomepageWidget.FollowTeamCard.CloseButtonAccessibilityLabel
        actionButton.addAction(
            UIAction { [weak self] _ in
                self?.dismiss()
            },
            for: .touchUpInside)
    }

    // MARK: - Countdown

    private func startCountdown() {
        let model = WorldCupCountdownModel(prefs: profile.prefs)
        model.onCountdownUpdated = { [weak self] countdown in
            self?.apply(countdown: countdown)
        }
        model.start()
        countdownModel = model
    }

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
        updateA11yLayout()
    }

    private func updateA11yLayout() {
        let isA11y = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        heroImageView.isHidden = isA11y
        leftContentStack.alignment = isA11y ? .fill : .leading

        NSLayoutConstraint.deactivate(isA11y ? heroVisibleConstraints : heroHiddenConstraints)
        NSLayoutConstraint.activate(isA11y ? heroHiddenConstraints : heroVisibleConstraints)
    }

    // MARK: - Actions

    private func navigateToTeamSelection() {
        store.dispatch(
            NavigationBrowserAction(
                navigationDestination: NavigationDestination(.worldCupCountryPicker),
                windowUUID: windowUUID,
                actionType: NavigationBrowserActionType.tapOnCell
            )
        )
    }

    private func navigateToScheduleURL() {
        guard let url = URL(string: UX.scheduleURL) else { return }
        telemetry.viewScheduleTapped()
        store.dispatch(
            NavigationBrowserAction(
                navigationDestination: NavigationDestination(
                    .newTab,
                    url: url,
                    isPrivate: false,
                    selectNewTab: true
                ),
                windowUUID: windowUUID,
                actionType: NavigationBrowserActionType.tapOnCell
            )
        )
    }

    private func dismiss() {
        telemetry.closeButtonTapped()
        store.dispatch(
            WorldCupAction(
                windowUUID: windowUUID,
                actionType: WorldCupActionType.removeHomepageCard,
            )
        )
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
        actionButton.imageView?.tintColor = theme.colors.textPrimary
        ctaButton.applyTheme(theme: theme)
        timerContainer.backgroundColor = theme.colors.layer3
    }
}
