// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import UIKit

/// Sub-view of the World Cup homepage card shown after the user has selected a team to follow.
/// It surfaces the upcoming games for the followed team: one or two featured matches plus a short
/// list of the games that come after them.
final class WorldCupInfoCardView: UIView, ThemeApplicable {
    private struct UX {
        static let sectionSpacing: CGFloat = 16
        static let headerSpacing: CGFloat = 6
        static let headerInnerSpacing: CGFloat = 8
        static let moreOptionButtonIconSize: CGFloat = 24
        
        static let featuredMatchesStackHorizontalPadding: CGFloat = 41.0
        static let featuredColumnWidth: CGFloat = 104
        static let featuredColumnHeight: CGFloat = 60
        static let featuredFlagSize = CGSize(width: 60, height: 40)
        static let featuredFlagCornerRadius: CGFloat = 7
        static let featuredFlagToCodeSpacing: CGFloat = 4
        static let featuredMatchesSpacing: CGFloat = 16

        static let dividerHeight: CGFloat = 1
        static let upcomingRowSpacing: CGFloat = 8

        static let separatorBullet = "  •  "

        static let liveLabelCornerRadius: CGFloat = 5
        static let liveLabelHorizontalPadding: CGFloat = 6
        static let liveLabelVerticalPadding: CGFloat = 4
        static let liveLabelDotText = "•"
    }

    /// A single match displayed in the card (either as a featured match or in the
    /// upcoming-matches list below).
    struct Match: Equatable {
        struct Score: Equatable {
            let score: String
            let clock: String
        }
        let homeFlagAssetName: String
        let homeCode: String
        let awayFlagAssetName: String
        let awayCode: String
        let date: String
        let score: Score?
    }

    struct Model: Equatable {
        let phaseTitle: String
        let phaseDate: String
        let isLive: Bool
        /// One or two featured matches. When two are provided, a divider is rendered between them.
        let featuredMatch: [Match]
        /// The next two games after `featuredMatch`. Anything beyond two entries is ignored.
        let upcomingMatches: [Match]
    }

    // MARK: - UI

    private lazy var titleLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = FXFontStyles.Bold.subheadline.scaledFont()
        label.adjustsFontForContentSizeCategory = true
    }
    
    private lazy var dateLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontForContentSizeCategory = true
    }

    private lazy var moreOptionsButton: UIButton = .build { [weak self] button in
        let changeTeamAction = UIAction(
            title: .WorldCup.HomepageWidget.ChangeTeamLabel,
            image: UIImage.templateImageNamed(StandardImageIdentifiers.Medium.starFill),
            handler: { _ in }
        )
        let removeAction = UIAction(
            title: .WorldCup.HomepageWidget.RemoveLabel,
            image: UIImage.templateImageNamed(
                StandardImageIdentifiers.Medium.cross
            ),
            attributes: .destructive,
            handler: { _ in}
        )
        let menu = UIMenu(children: [changeTeamAction, removeAction])
        button.menu = menu
        button.showsMenuAsPrimaryAction = true
        button.setImage(
            UIImage(named: StandardImageIdentifiers.Large.moreHorizontalRound)?
                .withRenderingMode(.alwaysTemplate),
            for: .normal
        )
        button.accessibilityLabel = .WorldCup.HomepageWidget.SettingsButtonAccessibilityLabel
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private lazy var liveLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.caption1.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.text = "\(UX.liveLabelDotText) \(String.WorldCup.HomepageWidget.LiveLabel)"
        label.textAlignment = .center
        label.textColor = .white
    }

    private lazy var liveLabelContainer: UIView = .build { view in
        view.layer.cornerRadius = UX.liveLabelCornerRadius
    }

    private lazy var headerStack: UIStackView = .build { stack in
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = UX.headerSpacing
    }

    private lazy var featuredMatchesStack: UIStackView = .build { stack in
        stack.axis = .vertical
        stack.spacing = UX.featuredMatchesSpacing
    }

    private lazy var divider: UIView = .build()

    private lazy var upcomingStack: UIStackView = .build { stack in
        stack.axis = .vertical
        stack.spacing = UX.upcomingRowSpacing
    }

    private lazy var contentStack: UIStackView = .build { stack in
        stack.axis = .vertical
        stack.spacing = UX.sectionSpacing
    }

    // MARK: - State

    private let windowUUID: WindowUUID
    private var model: Model?
    private var featuredDividers: [UIView] = []

    // MARK: - Init

    init(windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    private func setupLayout() {
        liveLabelContainer.addSubview(liveLabel)
        
        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(dateLabel)
        headerStack.addArrangedSubview(liveLabelContainer)
        // spacer view
        headerStack.addArrangedSubview(UIView())
        headerStack.addArrangedSubview(moreOptionsButton)
        
        contentStack.addArrangedSubview(headerStack)
        contentStack.addArrangedSubview(featuredMatchesStack)
        contentStack.addArrangedSubview(divider)
        contentStack.addArrangedSubview(upcomingStack)

        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            featuredMatchesStack.leadingAnchor.constraint(equalTo: leadingAnchor,
                                                          constant: UX.featuredMatchesStackHorizontalPadding),
            featuredMatchesStack.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                           constant: -UX.featuredMatchesStackHorizontalPadding),
            
            liveLabel.leadingAnchor.constraint(equalTo: liveLabelContainer.leadingAnchor,
                                               constant: UX.liveLabelHorizontalPadding),
            liveLabel.trailingAnchor.constraint(equalTo: liveLabelContainer.trailingAnchor,
                                                constant: -UX.liveLabelHorizontalPadding),
            liveLabel.topAnchor.constraint(equalTo: liveLabelContainer.topAnchor,
                                           constant: UX.liveLabelVerticalPadding),
            liveLabel.bottomAnchor.constraint(equalTo: liveLabelContainer.bottomAnchor,
                                              constant: -UX.liveLabelVerticalPadding),

            moreOptionsButton.widthAnchor.constraint(equalToConstant: UX.moreOptionButtonIconSize),
            moreOptionsButton.heightAnchor.constraint(equalToConstant: UX.moreOptionButtonIconSize),

            divider.heightAnchor.constraint(equalToConstant: UX.dividerHeight),
        ])
    }

    // MARK: - Configuration

    func configure(with model: Model, theme: Theme) {
        guard model != self.model else { return }
        self.model = model

        rebuildFeaturedMatches(matches: model.featuredMatch)
        rebuildUpcomingRows(matches: Array(model.upcomingMatches.prefix(2)))
        refreshHeader(model: model)
        applyTheme(theme: theme)
    }

    private func refreshHeader(model: Model) {
        titleLabel.text = model.phaseTitle
        dateLabel.text = model.phaseDate
        liveLabelContainer.isHidden = !model.isLive
        dateLabel.isHidden = model.isLive
    }

    private func rebuildFeaturedMatches(matches: [Match]) {
        featuredMatchesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        featuredDividers.forEach { $0.removeFromSuperview() }
        featuredDividers.removeAll()

        for (index, match) in matches.enumerated() {
            if index > 0 {
                let separator: UIView = .build()
                separator.heightAnchor.constraint(equalToConstant: UX.dividerHeight).isActive = true
                featuredMatchesStack.addArrangedSubview(separator)
                featuredDividers.append(separator)
            }
            let view: FeaturedMatchView = .build()
            view.configure(with: match)
            featuredMatchesStack.addArrangedSubview(view)
        }
    }

    private func rebuildUpcomingRows(matches: [Match]) {
        upcomingStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for match in matches {
            let row: UpcomingMatchRow = .build()
            row.configure(with: match)
            upcomingStack.addArrangedSubview(row)
        }
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        moreOptionsButton.tintColor = theme.colors.iconSecondary
        divider.backgroundColor = theme.colors.borderSecondary
        liveLabelContainer.backgroundColor = theme.colors.gradientAIStrongStop1

        featuredMatchesStack.arrangedSubviews.forEach { ($0 as? ThemeApplicable)?.applyTheme(theme: theme) }
        featuredDividers.forEach { $0.backgroundColor = theme.colors.borderPrimary }
        upcomingStack.arrangedSubviews.forEach { ($0 as? ThemeApplicable)?.applyTheme(theme: theme) }
    }
}

// MARK: - Featured match

private final class FeaturedMatchView: UIView, ThemeApplicable {
    private struct UX {
        static let flagSize = CGSize(width: 60, height: 40)
        static let flagCornerRadius: CGFloat = 7
        static let flagToCodeSpacing: CGFloat = 4

        static let scoreLabelHorizontalPadding: CGFloat = 16
        static let scoreLabelVerticalPadding: CGFloat = 8
        static let scorePillSpacing: CGFloat = 12
        static let scoreSectionSpacing: CGFloat = 8
    }

    private struct FeaturedColumn {
        let container: UIView
        let flagView: UIImageView
        let codeLabel: UILabel
    }

    private lazy var homeColumn = makeFeaturedColumn()
    private lazy var awayColumn = makeFeaturedColumn()

    private lazy var dateLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.footnote.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 0
    }

    private lazy var scoreLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.title2.scaledFont()
        label.adjustsFontForContentSizeCategory = true
    }
    
    private lazy var scoreContainer: UIView = .build()
    
    private lazy var clockLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.footnote.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
    }

    private lazy var scoreSection: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [scoreContainer, clockLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = UX.scoreSectionSpacing
        return stack
    }()

    private lazy var centerStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [dateLabel, scoreSection])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        return stack
    }()

    private lazy var horizontalStack: UIStackView = {
        let spacer1 = UIView()
        let spacer2 = UIView()
        let stack = UIStackView(arrangedSubviews: [
            homeColumn.container, spacer1, centerStack, spacer2, awayColumn.container
        ])
        spacer1.widthAnchor.constraint(equalTo: spacer2.widthAnchor).isActive = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        return stack
    }()

    init() {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        scoreContainer.addSubview(scoreLabel)
        addSubview(horizontalStack)
        
        NSLayoutConstraint.activate([
            horizontalStack.topAnchor.constraint(equalTo: topAnchor),
            horizontalStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            horizontalStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            horizontalStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            scoreLabel.leadingAnchor.constraint(equalTo: scoreContainer.leadingAnchor,
                                                constant: UX.scoreLabelHorizontalPadding),
            scoreLabel.trailingAnchor.constraint(equalTo: scoreContainer.trailingAnchor,
                                                 constant: -UX.scoreLabelHorizontalPadding),
            scoreLabel.topAnchor.constraint(equalTo: scoreContainer.topAnchor,
                                            constant: UX.scoreLabelVerticalPadding),
            scoreLabel.bottomAnchor.constraint(equalTo: scoreContainer.bottomAnchor,
                                               constant: -UX.scoreLabelVerticalPadding)
        ])
    }
    
    private func makeFeaturedColumn() -> FeaturedColumn {
        let flagView: UIImageView = .build { imageView in
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = UX.flagCornerRadius
            imageView.layer.borderWidth = 1
            imageView.isAccessibilityElement = false
        }

        let codeLabel: UILabel = .build { label in
            label.font = FXFontStyles.Bold.footnote.scaledFont()
            label.adjustsFontForContentSizeCategory = true
            label.textAlignment = .center
            label.numberOfLines = 1
            label.lineBreakMode = .byTruncatingTail
        }

        let stack: UIStackView = .build { stack in
            stack.axis = .vertical
            stack.alignment = .center
            stack.spacing = UX.flagToCodeSpacing
        }
        stack.addArrangedSubview(flagView)
        stack.addArrangedSubview(codeLabel)

        NSLayoutConstraint.activate([
            flagView.widthAnchor.constraint(equalToConstant: UX.flagSize.width),
            flagView.heightAnchor.constraint(equalToConstant: UX.flagSize.height),
        ])

        return FeaturedColumn(container: stack, flagView: flagView, codeLabel: codeLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        scoreContainer.layoutIfNeeded()
        scoreContainer.layer.cornerRadius = scoreContainer.frame.height / 2
    }

    func configure(with match: WorldCupInfoCardView.Match) {
        homeColumn.flagView.image = UIImage(named: match.homeFlagAssetName)
        homeColumn.codeLabel.text = match.homeCode
        awayColumn.flagView.image = UIImage(named: match.awayFlagAssetName)
        awayColumn.codeLabel.text = match.awayCode

        if let score = match.score {
            dateLabel.isHidden = true
            scoreSection.isHidden = false
            scoreLabel.text = score.score
            clockLabel.text = score.clock
        } else {
            dateLabel.isHidden = false
            scoreSection.isHidden = true
            dateLabel.text = match.date
        }
    }
    
    // MARK: - ThemeApplicable
    
    func applyTheme(theme: Theme) {
        dateLabel.textColor = theme.colors.textSecondary
        clockLabel.textColor = theme.colors.textSecondary
        scoreLabel.textColor = theme.colors.textPrimary
        scoreContainer.backgroundColor = theme.colors.layer3
        
        homeColumn.codeLabel.textColor = theme.colors.textPrimary
        homeColumn.flagView.layer.borderColor = theme.colors.borderPrimary.cgColor
        awayColumn.codeLabel.textColor = theme.colors.textPrimary
        awayColumn.flagView.layer.borderColor = theme.colors.borderPrimary.cgColor
    }
}

// MARK: - Upcoming row

private final class UpcomingMatchRow: UIView, ThemeApplicable {
    private struct UX {
        static let flagSize = CGSize(width: 36, height: 24)
        static let flagCornerRadius: CGFloat = 5
        static let flagToCodeSpacing: CGFloat = 8
        static let dateLabelInset: CGFloat = 8
    }

    private lazy var homeFlagView = makeFlagView()
    private lazy var awayFlagView = makeFlagView()

    private lazy var homeCodeLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.footnote.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .natural
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
    }

    private lazy var awayCodeLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.footnote.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .right
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
    }

    /// Label for showing info about the match, it could the date or the score.
    private lazy var infoLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.footnote.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 1
    }

    private lazy var leftStack: UIStackView = .build { stack in
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = UX.flagToCodeSpacing
    }

    private lazy var rightStack: UIStackView = .build { stack in
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = UX.flagToCodeSpacing
    }

    init() {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        leftStack.addArrangedSubview(homeFlagView)
        leftStack.addArrangedSubview(homeCodeLabel)

        rightStack.addArrangedSubview(awayCodeLabel)
        rightStack.addArrangedSubview(awayFlagView)

        addSubviews(leftStack, infoLabel, rightStack)

        homeCodeLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        homeCodeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        awayCodeLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        awayCodeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            leftStack.topAnchor.constraint(equalTo: topAnchor),
            leftStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            leftStack.leadingAnchor.constraint(equalTo: leadingAnchor),

            rightStack.topAnchor.constraint(equalTo: topAnchor),
            rightStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            rightStack.trailingAnchor.constraint(equalTo: trailingAnchor),

            infoLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            infoLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            infoLabel.leadingAnchor.constraint(
                greaterThanOrEqualTo: leftStack.trailingAnchor,
                constant: UX.dateLabelInset
            ),
            infoLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: rightStack.leadingAnchor,
                constant: -UX.dateLabelInset
            ),

            homeFlagView.widthAnchor.constraint(equalToConstant: UX.flagSize.width),
            homeFlagView.heightAnchor.constraint(equalToConstant: UX.flagSize.height),
            awayFlagView.widthAnchor.constraint(equalToConstant: UX.flagSize.width),
            awayFlagView.heightAnchor.constraint(equalToConstant: UX.flagSize.height),
        ])
    }

    private func makeFlagView() -> UIImageView {
        return .build { imageView in
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = UX.flagCornerRadius
            imageView.layer.borderWidth = 1
            imageView.isAccessibilityElement = false
        }
    }

    func configure(with match: WorldCupInfoCardView.Match) {
        homeFlagView.image = UIImage(named: match.homeFlagAssetName)
        homeCodeLabel.text = match.homeCode
        awayFlagView.image = UIImage(named: match.awayFlagAssetName)
        awayCodeLabel.text = match.awayCode
        if let score = match.score {
            infoLabel.text = score.score
        } else {
            infoLabel.text = match.date
        }
    }

    // MARK: - ThemeApplicable
    
    func applyTheme(theme: Theme) {
        homeCodeLabel.textColor = theme.colors.textPrimary
        awayCodeLabel.textColor = theme.colors.textPrimary
        infoLabel.textColor = theme.colors.textSecondary
        homeFlagView.layer.borderColor = theme.colors.borderPrimary.cgColor
        awayFlagView.layer.borderColor = theme.colors.borderPrimary.cgColor
    }
}

// MARK: - Placeholder data

extension WorldCupInfoCardView.Model {
    /// Default placeholder content matching the original Figma reference: a single upcoming
    /// featured match with two follow-up games.
    static let placeholder = WorldCupInfoCardView.Model(
        phaseTitle: "Group Stage",
        phaseDate: "Jun 11",
        isLive: false,
        featuredMatch: [
            WorldCupInfoCardView.Match(
                homeFlagAssetName: "us",
                homeCode: "USA",
                awayFlagAssetName: "py",
                awayCode: "PAR",
                date: "Jun 13",
                score: nil
            ),
        ],
        upcomingMatches: [
            WorldCupInfoCardView.Match(
                homeFlagAssetName: "us",
                homeCode: "USA",
                awayFlagAssetName: "au",
                awayCode: "AUS",
                date: "Jun 19",
                score: nil
            ),
            WorldCupInfoCardView.Match(
                homeFlagAssetName: "tr",
                homeCode: "TUR",
                awayFlagAssetName: "us",
                awayCode: "USA",
                date: "Jun 25",
                score: nil
            ),
        ]
    )

    /// Placeholder showing the live state: a match in progress (with score), a follow-up featured
    /// match below a divider, and the rest of the schedule in the upcoming list.
    static let placeholderLive = WorldCupInfoCardView.Model(
        phaseTitle: "Group stage",
        phaseDate: "Jun 11",
        isLive: true,
        featuredMatch: [
            WorldCupInfoCardView.Match(
                homeFlagAssetName: "us",
                homeCode: "USA",
                awayFlagAssetName: "py",
                awayCode: "PAR",
                date: "Jun 13",
                score: WorldCupInfoCardView.Match.Score(score: "2 - 2", clock: "103’")
            ),
            WorldCupInfoCardView.Match(
                homeFlagAssetName: "us",
                homeCode: "USA",
                awayFlagAssetName: "au",
                awayCode: "AUS",
                date: "Jun 19",
                score: nil
            ),
        ],
        upcomingMatches: [
            WorldCupInfoCardView.Match(
                homeFlagAssetName: "tr",
                homeCode: "TUR",
                awayFlagAssetName: "us",
                awayCode: "USA",
                date: "Jun 25",
                score: nil
            ),
        ]
    )
    
    static let placeholderNoUpcoming = WorldCupInfoCardView.Model(
        phaseTitle: "Group stage",
        phaseDate: "Jun 11",
        isLive: true,
        featuredMatch: [
            WorldCupInfoCardView.Match(
                homeFlagAssetName: "us",
                homeCode: "USA",
                awayFlagAssetName: "py",
                awayCode: "PAR",
                date: "Jun 13",
                score: WorldCupInfoCardView.Match.Score(score: "2 - 2", clock: "103’")
            ),
            WorldCupInfoCardView.Match(
                homeFlagAssetName: "us",
                homeCode: "USA",
                awayFlagAssetName: "au",
                awayCode: "AUS",
                date: "Jun 19",
                score: nil
            ),
        ],
        upcomingMatches: []
    )
}
