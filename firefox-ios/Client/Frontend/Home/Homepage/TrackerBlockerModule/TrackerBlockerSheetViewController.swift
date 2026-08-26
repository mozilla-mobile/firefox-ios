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
final class TrackerBlockerSheetViewController: UIViewController, Themeable, Notifiable {
    private struct UX {
        static let contentHorizontalPadding: CGFloat = 16
        static let contentTopPadding: CGFloat = 44
        static let contentBottomPadding: CGFloat = 16
        static let closeButtonTrailingPadding: CGFloat = 16
        static let closeButtonTopPadding: CGFloat = 16
        static let shieldPlaceholderSize: CGFloat = 48
        static let shieldCornerRadius: CGFloat = 12
        static let cardCornerRadius: CGFloat = 12
        static let cardHorizontalPadding: CGFloat = 12
        static let separatorHeight: CGFloat = 1
        static let pillHorizontalPadding: CGFloat = 12
        static let pillVerticalPadding: CGFloat = 6
        static let spacingShieldToCount: CGFloat = 12
        static let spacingCountToHeader: CGFloat = 4
        static let spacingHeaderToCard: CGFloat = 20
        static let spacingCardToFooter: CGFloat = 16
    }

    // MARK: - Themeable
    var currentWindowUUID: WindowUUID? { return windowUUID }
    var themeManager: any ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: any NotificationProtocol

    private let windowUUID: WindowUUID
    private var state: TrackerBlockerSheetState
    private var categoryRowViews: [TrackerCategoryRowView] = []

    // MARK: - UI
    private let backgroundGradientView: GradientView = .build()

    private lazy var closeButton: CloseButton = .build { [weak self] button in
        button.addTarget(self, action: #selector(self?.closeButtonTapped), for: .touchUpInside)
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

    // Placeholder for the shield icon (the real icon is added separately).
    private let shieldPlaceholder: UIView = .build { view in
        view.layer.cornerRadius = UX.shieldCornerRadius
        view.isAccessibilityElement = false
        view.accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.TrackerBlockerModule.Sheet.shieldIcon
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

    private let footerLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.footnote.scaledFont()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
    }

    // MARK: - Init
    init(
        windowUUID: WindowUUID,
        state: TrackerBlockerSheetState = .dummyEmpty
//        state: TrackerBlockerSheetState = .dummyFilled,
//        state: TrackerBlockerSheetState = .dummyWeeklyReset,
        themeManager: any ThemeManager = AppContainer.shared.resolve(),
        notificationCenter: any NotificationProtocol = NotificationCenter.default
    ) {
        self.windowUUID = windowUUID
        self.state = state
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)

        startObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: self,
            observing: [UIContentSizeCategory.didChangeNotification]
        )
        setDetentSize()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        setupCloseButton()
        listenForThemeChanges(withNotificationCenter: notificationCenter)
        configure(with: state)
    }

    // MARK: - Layout
    private func setupLayout() {
        shieldContainer.addSubview(shieldPlaceholder)
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

            contentScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            contentScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

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

            shieldPlaceholder.topAnchor.constraint(equalTo: shieldContainer.topAnchor),
            shieldPlaceholder.bottomAnchor.constraint(equalTo: shieldContainer.bottomAnchor),
            shieldPlaceholder.centerXAnchor.constraint(equalTo: shieldContainer.centerXAnchor),
            shieldPlaceholder.widthAnchor.constraint(equalToConstant: UX.shieldPlaceholderSize),
            shieldPlaceholder.heightAnchor.constraint(equalToConstant: UX.shieldPlaceholderSize),

            categoriesStack.topAnchor.constraint(equalTo: categoriesCardView.topAnchor),
            categoriesStack.bottomAnchor.constraint(equalTo: categoriesCardView.bottomAnchor),
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
        // TODO: FXIOS-XXXXX - Use a localized close-button a11y label once strings land.
        let closeButtonViewModel = CloseButtonViewModel(
            a11yLabel: "Close",
            a11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.TrackerBlockerModule.Sheet.closeButton
        )
        closeButton.configure(viewModel: closeButtonViewModel, notificationCenter: notificationCenter)
    }

    private func setDetentSize() {
        guard UIDevice.current.userInterfaceIdiom == .phone, let sheet = sheetPresentationController else { return }
        if UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory {
            sheet.detents = [.large()]
        } else {
            sheet.detents = [.medium()]
        }
    }

    // MARK: - Configuration
    func configure(with state: TrackerBlockerSheetState) {
        self.state = state
        let theme = themeManager.getCurrentTheme(for: windowUUID)

        rebuildCategoryRows(with: state, theme: theme)

        if let weeklyCount = state.weeklyCount {
            weeklyCountLabel.isHidden = false
            weeklyCountLabel.text = weeklyCount.formatted(.number)
            weeklyCountLabel.accessibilityLabel = "\(weeklyCount) trackers blocked this week"

            headerLabel.text = "Trackers blocked this week"
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
        footerLabel.text = state.totalText
        footerPill.isAccessibilityElement = state.totalText != nil
        footerPill.accessibilityLabel = state.totalText

        applyTheme()
    }

    private func rebuildCategoryRows(with state: TrackerBlockerSheetState, theme: Theme) {
        categoriesStack.arrangedSubviews.forEach {
            categoriesStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        categoryRowViews.removeAll()

        for (index, category) in state.categories.enumerated() {
            if index > 0 {
                categoriesStack.addArrangedSubview(makeSeparator(theme: theme))
            }
            let rowView = TrackerCategoryRowView()
            rowView.accessibilityIdentifier =
                AccessibilityIdentifiers.FirefoxHomepage.TrackerBlockerModule.Sheet.categoryRow(index)
            rowView.configure(with: category, fillRatio: state.fillRatio(for: category), theme: theme)
            categoriesStack.addArrangedSubview(rowView)
            categoryRowViews.append(rowView)
        }
    }

    private func makeSeparator(theme: Theme) -> UIView {
        let separator: UIView = .build { view in
            view.isAccessibilityElement = false
        }
        separator.backgroundColor = theme.colors.borderPrimary
        separator.heightAnchor.constraint(equalToConstant: UX.separatorHeight).isActive = true
        return separator
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
                self.setDetentSize()
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
        backgroundGradientView.backgroundColor = theme.colors.layer2
        backgroundGradientView.configure(gradient: theme.isNova ? theme.colors.gradientAccentSubtle : nil)

        shieldPlaceholder.backgroundColor = theme.colors.layer3
        weeklyCountLabel.textColor = theme.colors.textPrimary
        headerLabel.textColor = state.isEmpty ? theme.colors.textPrimary : theme.colors.textSecondary
        categoriesCardView.backgroundColor = theme.colors.layer2
        // The pill has no background in the empty state, where it acts as an empty spacer.
        footerPill.backgroundColor = state.totalText != nil ? theme.colors.layerAccentPrivateNonOpaque : .clear
        footerLabel.textColor = theme.colors.textSecondary

        categoryRowViews.forEach { $0.applyTheme(theme: theme) }
    }
}

/// A view that always renders as a capsule (fully rounded ends), re-rounding itself whenever its bounds change.
/// Rounding in the view's own `layoutSubviews` is reliable across presentation styles (e.g. iPhone sheet vs iPad),
/// unlike computing the corner radius from a view controller's `viewDidLayoutSubviews`.
private final class CapsuleView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }
}
