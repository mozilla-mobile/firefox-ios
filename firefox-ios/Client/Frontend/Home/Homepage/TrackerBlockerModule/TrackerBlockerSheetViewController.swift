// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit

/// The tracker blocker sheet, presented as a native `UISheetPresentationController` bottom sheet.
///
/// The content is wrapped in a scroll view so it becomes scrollable when it is taller than the sheet
/// (large Dynamic Type or landscape). Detents adapt to Dynamic Type: `.medium()` normally, `.large()` for
/// accessibility text sizes.
///
/// Detents only apply on iPhone. On iPad the sheet is presented as a form sheet sized to
/// `preferredContentSize`, because the default page sheet there is a fixed-height card that would leave a gap
/// below the content.
final class TrackerBlockerSheetViewController: UIViewController, Themeable, Notifiable {
    private struct UX {
        static let contentHorizontalPadding: CGFloat = 22
        static let contentTopPadding: CGFloat = 44
        static let contentBottomPadding: CGFloat = 16
        static let closeButtonTrailingPadding: CGFloat = 16
        static let closeButtonTopPadding: CGFloat = 16
        static let shieldIconSize: CGFloat = 48
        static let cardCornerRadius: CGFloat = 34
        static let cardHorizontalPadding: CGFloat = 12
        static let cardTopPadding: CGFloat = 16
        static let cardBottomPadding: CGFloat = 12
        static let separatorHeight: CGFloat = 1
        /// Insets the line inside the row it divides. Eyeballed: the leading edge lands just past where the row
        /// titles begin, which `TrackerCategoryRowView` puts at 48 (its leading inset, icon and icon-to-title
        /// spacing).
        static let separatorLeadingInset: CGFloat = 49
        static let separatorTrailingInset: CGFloat = 10
        static let pillHorizontalPadding: CGFloat = 12
        static let pillVerticalPadding: CGFloat = 6
        static let spacingShieldToCount: CGFloat = 12
        static let spacingCountToHeader: CGFloat = 4
        static let spacingHeaderToCard: CGFloat = 20
        static let spacingCardToFooter: CGFloat = 16
        /// The width the iPad form sheet asks for. Wider than the design's 377pt phone sheet, which reads as
        /// too narrow on an iPad.
        static let formSheetWidth: CGFloat = 525
    }

    // MARK: - Themeable
    var currentWindowUUID: WindowUUID? { return windowUUID }
    var themeManager: any ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: any NotificationProtocol

    private let windowUUID: WindowUUID
    private var state: TrackerBlockerSheetState
    private var categoryRowViews: [TrackerCategoryRowView] = []
    private var separatorViews: [UIView] = []

    // MARK: - UI
    private let backgroundGradientView: GradientView = .build()

    private lazy var closeButton: CloseButton = .build { [unowned self] button in
        button.addTarget(self, action: #selector(self.closeButtonTapped), for: .touchUpInside)
    }

    private let contentScrollView: UIScrollView = .build { scrollView in
        scrollView.backgroundColor = .clear
        scrollView.showsHorizontalScrollIndicator = false
    }

    private let contentView: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private lazy var contentStack: UIStackView = .build { stack in
        stack.axis = .vertical
        stack.alignment = .fill
    }

    private let shieldContainer: UIView = .build()

    // The asset is already coloured, so it is drawn as-is rather than tinted from the theme.
    private let shieldImageView: UIImageView = .build { imageView in
        imageView.image = UIImage(named: ImageIdentifiers.shieldCheckmarkColored)
        imageView.contentMode = .scaleAspectFit
        imageView.isAccessibilityElement = false
        imageView.accessibilityIdentifier =
            AccessibilityIdentifiers.FirefoxHomepage.TrackerBlockerModule.Sheet.shieldIcon
    }

    private let weeklyCountLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.largeTitle.scaledFont()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.TrackerBlockerModule.Sheet.weeklyCountLabel
    }

    private let headerLabel: UILabel = .build { label in
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.TrackerBlockerModule.Sheet.headerLabel
    }

    private let categoriesCardView: UIView = .build { view in
        view.layer.cornerRadius = UX.cardCornerRadius
        view.clipsToBounds = true
        view.accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.TrackerBlockerModule.Sheet.categoriesCard
    }

    private lazy var categoriesStack: UIStackView = .build { stack in
        stack.axis = .vertical
        stack.alignment = .fill
    }

    private let footerContainer: UIView = .build()

    private let footerPill: CapsuleView = .build { view in
        view.clipsToBounds = true
        view.isAccessibilityElement = true
        view.accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.TrackerBlockerModule.Sheet.totalPill
    }

    /// Resolved on each use so it keeps up with Dynamic Type.
    private static var footerFont: UIFont { FXFontStyles.Regular.footnote.scaledFont() }

    private let footerLabel: UILabel = .build { label in
        label.font = TrackerBlockerSheetViewController.footerFont
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
    }

    // MARK: - Init
    init(
        windowUUID: WindowUUID,
        state: TrackerBlockerSheetState,
        themeManager: any ThemeManager = AppContainer.shared.resolve(),
        notificationCenter: any NotificationProtocol = NotificationCenter.default
    ) {
        self.windowUUID = windowUUID
        self.state = state
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)

        // Has to be set before the presenting code reaches `present`, so it can't wait for `viewDidLoad`.
        if isFormSheetPresentation {
            modalPresentationStyle = .formSheet
        }

        startObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: self,
            observing: [UIContentSizeCategory.didChangeNotification]
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Reading `sheetPresentationController` forces the presentation controller into existence, so this waits
        // until `modalPresentationStyle` is settled — `init` sets it, and the presenting code may override it.
        setDetentSize()
        setupLayout()
        setupCloseButton()
        listenForThemeChanges(withNotificationCenter: notificationCenter)
        configure(with: state)
    }

    // MARK: - Layout
    private func setupLayout() {
        shieldContainer.addSubview(shieldImageView)
        footerContainer.addSubview(footerPill)
        footerPill.addSubview(footerLabel)
        categoriesCardView.addSubview(categoriesStack)

        contentStack.addArrangedSubview(shieldContainer)
        contentStack.addArrangedSubview(weeklyCountLabel)
        contentStack.addArrangedSubview(headerLabel)
        contentStack.addArrangedSubview(categoriesCardView)
        contentStack.addArrangedSubview(footerContainer)

        contentStack.setCustomSpacing(UX.spacingShieldToCount, after: shieldContainer)
        contentStack.setCustomSpacing(UX.spacingCountToHeader, after: weeklyCountLabel)
        contentStack.setCustomSpacing(UX.spacingHeaderToCard, after: headerLabel)
        contentStack.setCustomSpacing(UX.spacingCardToFooter, after: categoriesCardView)

        contentView.addSubview(contentStack)
        contentScrollView.addSubview(contentView)
        view.addSubview(backgroundGradientView)
        view.addSubview(contentScrollView)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            backgroundGradientView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundGradientView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundGradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundGradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                             constant: UX.closeButtonTopPadding),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                  constant: -UX.closeButtonTrailingPadding),

            // The gradient stays full-bleed, but the content keeps clear of the safe area on the sides: in
            // landscape the sheet is full screen, so the notch/Dynamic Island would otherwise sit on top of the
            // categories card.
            contentScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            contentScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentScrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            contentScrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),

            contentView.topAnchor.constraint(equalTo: contentScrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: contentScrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: contentScrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: contentScrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: contentScrollView.frameLayoutGuide.widthAnchor),
            contentView.heightAnchor.constraint(equalTo: contentScrollView.heightAnchor).priority(.defaultLow),

            contentStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UX.contentTopPadding),
            // Use a `lessThanOrEqual` bottom so the content hugs the top and scrolls when tall, instead of the
            // stack stretching (and vertically stretching the category rows) to fill a short sheet.
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor,
                                                 constant: -UX.contentBottomPadding),
            contentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                  constant: UX.contentHorizontalPadding),
            contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                   constant: -UX.contentHorizontalPadding),

            shieldImageView.topAnchor.constraint(equalTo: shieldContainer.topAnchor),
            shieldImageView.bottomAnchor.constraint(equalTo: shieldContainer.bottomAnchor),
            shieldImageView.centerXAnchor.constraint(equalTo: shieldContainer.centerXAnchor),
            shieldImageView.widthAnchor.constraint(equalToConstant: UX.shieldIconSize),
            shieldImageView.heightAnchor.constraint(equalToConstant: UX.shieldIconSize),

            categoriesStack.topAnchor.constraint(equalTo: categoriesCardView.topAnchor,
                                                 constant: UX.cardTopPadding),
            categoriesStack.bottomAnchor.constraint(equalTo: categoriesCardView.bottomAnchor,
                                                    constant: -UX.cardBottomPadding),
            categoriesStack.leadingAnchor.constraint(equalTo: categoriesCardView.leadingAnchor,
                                                     constant: UX.cardHorizontalPadding),
            categoriesStack.trailingAnchor.constraint(equalTo: categoriesCardView.trailingAnchor,
                                                      constant: -UX.cardHorizontalPadding),

            footerPill.topAnchor.constraint(equalTo: footerContainer.topAnchor),
            footerPill.bottomAnchor.constraint(equalTo: footerContainer.bottomAnchor),
            footerPill.centerXAnchor.constraint(equalTo: footerContainer.centerXAnchor),
            footerPill.leadingAnchor.constraint(greaterThanOrEqualTo: footerContainer.leadingAnchor),
            footerPill.trailingAnchor.constraint(lessThanOrEqualTo: footerContainer.trailingAnchor),

            footerLabel.topAnchor.constraint(equalTo: footerPill.topAnchor, constant: UX.pillVerticalPadding),
            footerLabel.bottomAnchor.constraint(equalTo: footerPill.bottomAnchor, constant: -UX.pillVerticalPadding),
            footerLabel.leadingAnchor.constraint(equalTo: footerPill.leadingAnchor, constant: UX.pillHorizontalPadding),
            footerLabel.trailingAnchor.constraint(equalTo: footerPill.trailingAnchor, constant: -UX.pillHorizontalPadding)
        ])
    }

    private func setupCloseButton() {
        let closeButtonViewModel = CloseButtonViewModel(
            a11yLabel: .CloseButtonTitle,
            a11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.TrackerBlockerModule.Sheet.closeButton
        )
        closeButton.configure(viewModel: closeButtonViewModel, notificationCenter: notificationCenter)
    }

    /// iPad gets a content-sized form sheet rather than detents; see the type's documentation.
    private var isFormSheetPresentation: Bool {
        return UIDevice.current.userInterfaceIdiom != .phone
    }

    /// The size the iPad form sheet asks for: the content's natural height at the design's sheet width, so the
    /// card wraps the content instead of leaving a gap below the footer pill.
    func contentPreferredSize() -> CGSize {
        let stackHeight = contentStack.systemLayoutSizeFitting(
            CGSize(width: UX.formSheetWidth - UX.contentHorizontalPadding * 2,
                   height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        return CGSize(width: UX.formSheetWidth,
                      height: UX.contentTopPadding + stackHeight + UX.contentBottomPadding)
    }

    private func updatePreferredContentSize() {
        guard isFormSheetPresentation else { return }
        preferredContentSize = contentPreferredSize()
    }

    /// - Parameter animated: pass `true` when the sheet is already on screen, so UIKit resizes it smoothly
    ///   instead of snapping to the new detent.
    private func setDetentSize(animated: Bool = false) {
        guard !isFormSheetPresentation, let sheet = sheetPresentationController else { return }
        let isAccessibilitySize = UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory
        let detents: [UISheetPresentationController.Detent] = isAccessibilitySize ? [.large()] : [.medium()]

        guard animated else {
            sheet.detents = detents
            return
        }
        sheet.animateChanges { sheet.detents = detents }
    }

    // MARK: - Configuration
    func configure(with state: TrackerBlockerSheetState) {
        self.state = state
        let theme = themeManager.getCurrentTheme(for: windowUUID)

        rebuildCategoryRows(with: state, theme: theme)

        if let weeklyCount = state.weeklyCount {
            let countText = weeklyCount.formatted(.number)
            weeklyCountLabel.isHidden = false
            weeklyCountLabel.text = countText
            // The count and the header read as one sentence, so the count carries both for VoiceOver.
            weeklyCountLabel.accessibilityLabel = String(format: .PrivacyDashboard.HeaderLabelAccessibilityLabel,
                                                         countText)
            headerLabel.text = .PrivacyDashboard.HeaderLabel
            headerLabel.font = FXFontStyles.Regular.body.scaledFont()
            headerLabel.isAccessibilityElement = false
        } else {
            weeklyCountLabel.isHidden = true
            headerLabel.text = state.emptyMessage
            headerLabel.font = FXFontStyles.Bold.headline.scaledFont()
            headerLabel.isAccessibilityElement = true
        }

        // Keep the footer in the layout at all times so it doesn't affect the sizing of the rows above it;
        // in the empty state it simply has no text.
        if let total = state.total {
            // The lifetime count is bold; the surrounding copy is not. The base font is resolved rather than read
            // back from `footerLabel.font`, which reports the attributed string's first font — the bold count —
            // once it has been set, and would otherwise bold the whole string on the next `configure`.
            footerLabel.attributedText = total.text.attributedText(boldString: total.countText,
                                                                   font: Self.footerFont)
        } else {
            footerLabel.attributedText = nil
            footerLabel.text = nil
        }
        footerPill.isAccessibilityElement = state.total != nil
        footerPill.accessibilityLabel = state.total?.text

        applyTheme()
        updatePreferredContentSize()
    }

    private func rebuildCategoryRows(with state: TrackerBlockerSheetState, theme: Theme) {
        categoriesStack.arrangedSubviews.forEach {
            categoriesStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        categoryRowViews.removeAll()
        separatorViews.removeAll()

        for (index, category) in state.categories.enumerated() {
            if index > 0 {
                let separator = makeSeparator()
                categoriesStack.addArrangedSubview(separator.container)
                separatorViews.append(separator.line)
            }
            let rowView = TrackerCategoryRowView()
            rowView.accessibilityIdentifier =
                AccessibilityIdentifiers.FirefoxHomepage.TrackerBlockerModule.Sheet.categoryRow(index)
            rowView.configure(with: category, fillRatio: state.fillRatio(for: category), theme: theme)
            categoriesStack.addArrangedSubview(rowView)
            categoryRowViews.append(rowView)
        }

        // Pin every count to the same width so the bars are all the same length; Auto Layout settles on the
        // widest count in the card, so a four-digit row doesn't shorten its own bar. These constraints live on
        // `categoriesStack`, the rows' common ancestor, and are discarded with the rows on the next rebuild.
        if let firstRow = categoryRowViews.first {
            NSLayoutConstraint.activate(categoryRowViews.dropFirst().map {
                $0.countWidthAnchor.constraint(equalTo: firstRow.countWidthAnchor)
            })
        }
    }

    /// The stack fills its arranged subviews, so the line is inset inside a transparent container rather than
    /// constrained directly; that is what lets it start under the row titles instead of at the card's edge.
    /// Only the line is themed, by `applyTheme()`, so it keeps up with theme changes while the sheet is open.
    private func makeSeparator() -> (container: UIView, line: UIView) {
        let container: UIView = .build { view in
            view.isAccessibilityElement = false
        }
        let line: UIView = .build { view in
            view.isAccessibilityElement = false
        }
        container.addSubview(line)

        NSLayoutConstraint.activate([
            line.topAnchor.constraint(equalTo: container.topAnchor),
            line.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            line.leadingAnchor.constraint(equalTo: container.leadingAnchor,
                                          constant: UX.separatorLeadingInset),
            line.trailingAnchor.constraint(equalTo: container.trailingAnchor,
                                           constant: -UX.separatorTrailingInset),
            line.heightAnchor.constraint(equalToConstant: UX.separatorHeight)
        ])
        return (container, line)
    }

    @objc
    private func closeButtonTapped() {
        dismiss(animated: true)
    }

    // MARK: - Notifiable
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIContentSizeCategory.didChangeNotification:
            ensureMainThread {
                self.setDetentSize(animated: true)
                // The labels rescale themselves, so the form sheet has to re-measure around them.
                self.view.layoutIfNeeded()
                self.updatePreferredContentSize()
            }
        default:
            break
        }
    }

    // MARK: - Themeable
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)

        // `gradientAccentSubtle` carries its own 50% alpha, so it composites over the solid fill behind it.
        // It is Nova-only, so classic themes get the flat fill on its own.
        backgroundGradientView.backgroundColor = theme.colors.layer1
        backgroundGradientView.configure(gradient: theme.isNova ? theme.colors.gradientAccentSubtle : nil)

        weeklyCountLabel.textColor = theme.colors.textPrimary
        headerLabel.textColor = state.isEmpty ? theme.colors.textPrimary : theme.colors.textSecondary
        // The card is translucent by design, so it picks up the gradient behind it rather than covering it.
        categoriesCardView.backgroundColor = theme.colors.layerSurfaceMediumAlpha
        // The pill has no background in the empty state, where it acts as an empty spacer.
        footerPill.backgroundColor = state.total != nil ? theme.colors.layerAccentPrivateNonOpaque : .clear
        footerLabel.textColor = theme.colors.textSecondary

        categoryRowViews.forEach { $0.applyTheme(theme: theme) }
        separatorViews.forEach { $0.backgroundColor = theme.colors.borderPrimary }
    }
}
