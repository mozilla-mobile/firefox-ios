// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// Simple address toolbar implementation.
/// +-------------+--------------------------------------------------------+----------+
/// | navigation  | [ leading ]     indicators      url       [ trailing ] | browser  |
/// | actions     | [ page    ]                               [ page     ] | actions  |
/// |             | [ actions ]                               [ actions  ] |          |
/// +-------------+--------------------------------------------------------+----------+
public class BrowserAddressToolbar: UIView,
                                    Notifiable,
                                    AddressToolbar,
                                    ThemeApplicable,
                                    ToolbarButtonCaching,
                                    LocationViewDelegate,
                                    UIDragInteractionDelegate {
    private enum UX {
        static let horizontalSpace: CGFloat = 8
        static let borderHeight: CGFloat = 1
        static let actionSpacing: CGFloat = 0
        static let buttonSize = CGSize(width: 44, height: 44)
        static let locationHeight: CGFloat = 44
        // This could be changed at some point, depending on the a11y UX design.
        static let locationMaxHeight: CGFloat = 54
        static let toolbarAnimationTime: CGFloat = 0.15
        static let iconsAnimationTime: CGFloat = 0.1
        static let iconsAnimationDelay: CGFloat = 0.075
    }

    public var notificationCenter: any NotificationProtocol = NotificationCenter.default
    private weak var toolbarDelegate: AddressToolbarDelegate?
    private var theme: Theme?
    private var droppableUrl: URL?
    private var addressBarPosition: AddressToolbarPosition = .bottom

    var cachedButtonReferences = [String: ToolbarButton]()

    private lazy var toolbarContainerView: UIView = .build()
    private lazy var navigationActionStack: UIStackView = .build()

    private lazy var locationContainer: LocationContainer = .build()
    private lazy var locationView: LocationView = .build()
    private lazy var locationDividerView: UIView = .build()

    private lazy var leadingPageActionStack: UIStackView = .build()

    private lazy var trailingPageActionStack: UIStackView = .build { view in
        view.spacing = UX.actionSpacing
    }

    private lazy var browserActionStack: UIStackView = .build()
    private lazy var toolbarTopBorderView: UIView = .build()
    private lazy var toolbarBottomBorderView: UIView = .build()

    private var leadingBrowserActionConstraint: NSLayoutConstraint?
    private var leadingLocationContainerConstraint: NSLayoutConstraint?
    private var dividerWidthConstraint: NSLayoutConstraint?
    private var toolbarBottomConstraint: NSLayoutConstraint?
    private var toolbarTopConstraint: NSLayoutConstraint?
    private var toolbarTopBorderHeightConstraint: NSLayoutConstraint?
    private var toolbarBottomBorderHeightConstraint: NSLayoutConstraint?
    private var leadingNavigationActionStackConstraint: NSLayoutConstraint?
    private var trailingBrowserActionStackConstraint: NSLayoutConstraint?
    private var locationContainerHeightConstraint: NSLayoutConstraint?

    // FXIOS-10210 Temporary to support updating the Unified Search feature flag during runtime
    private var previousConfiguration: AddressToolbarConfiguration? {
        didSet {
            // Ensure the theme is reapplied to update colors and other UI elements
            // in sync with the new address toolbar configuration.
            guard let theme else { return }
            applyTheme(theme: theme)
        }
    }

    public var isUnifiedSearchEnabled = false {
        didSet {
            guard let previousConfiguration, oldValue != isUnifiedSearchEnabled else { return }

            locationView.configure(
                previousConfiguration.locationViewConfiguration,
                delegate: self,
                isUnifiedSearchEnabled: isUnifiedSearchEnabled,
                uxConfig: previousConfiguration.uxConfiguration,
                addressBarPosition: addressBarPosition
            )
        }
    }

    override public var transform: CGAffineTransform {
        get {
            return locationContainer.transform
        }
        set {
            locationContainer.transform = newValue
        }
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
        startObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: self,
            observing: [UIContentSizeCategory.didChangeNotification]
        )
        adjustHeightConstraintForA11ySizeCategory()
        setupDragInteraction()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configureNonInteractive(
        config: AddressToolbarConfiguration,
        leadingSpace: CGFloat,
        trailingSpace: CGFloat
    ) {
        previousConfiguration = config
        configureUX(config: config.uxConfiguration, toolbarPosition: .bottom)
        updateSpacing(uxConfig: config.uxConfiguration, leading: leadingSpace, trailing: trailingSpace)
        locationView.configureNonInteractive(config.locationViewConfiguration, uxConfig: config.uxConfiguration)
        updateActions(config: config, animated: false)
    }

    public func configure(config: AddressToolbarConfiguration,
                          toolbarPosition: AddressToolbarPosition,
                          toolbarDelegate: any AddressToolbarDelegate,
                          leadingSpace: CGFloat,
                          trailingSpace: CGFloat,
                          isUnifiedSearchEnabled: Bool,
                          animated: Bool) {
        [navigationActionStack, leadingPageActionStack, trailingPageActionStack, browserActionStack].forEach {
            $0.isHidden = config.uxConfiguration.scrollAlpha.isZero
        }
        if #available(iOS 26.0, *) {
            toolbarTopBorderView.isHidden = config.uxConfiguration.scrollAlpha.isZero
        }
        self.toolbarDelegate = toolbarDelegate
        self.isUnifiedSearchEnabled = isUnifiedSearchEnabled
        addressBarPosition = toolbarPosition
        previousConfiguration = config
        toolbarTopBorderView.accessibilityIdentifier = config.borderConfiguration.a11yIdentifier
        configureUX(config: config.uxConfiguration, toolbarPosition: toolbarPosition)
        updateSpacing(uxConfig: config.uxConfiguration, leading: leadingSpace, trailing: trailingSpace)
        configure(config: config,
                  isUnifiedSearchEnabled: isUnifiedSearchEnabled,
                  addressBarPosition: toolbarPosition,
                  animated: animated)
    }

    private func configure(
        config: AddressToolbarConfiguration,
        isUnifiedSearchEnabled: Bool,
        addressBarPosition: AddressToolbarPosition,
        animated: Bool
    ) {
        updateBorder(borderPosition: config.borderConfiguration.borderPosition)

        locationView.configure(
            config.locationViewConfiguration,
            delegate: self,
            isUnifiedSearchEnabled: isUnifiedSearchEnabled,
            uxConfig: config.uxConfiguration,
            addressBarPosition: addressBarPosition
        )
        updateActions(config: config, animated: animated)
        droppableUrl = config.locationViewConfiguration.droppableUrl
    }

    private func configureUX(config: AddressToolbarUXConfiguration,
                             toolbarPosition: AddressToolbarPosition) {
        locationContainer.layer.cornerRadius = config.toolbarCornerRadius
        locationContainer.updateShadowOpacityBasedOn(scrollAlpha: config.scrollAlpha)
        dividerWidthConstraint?.constant = config.browserActionsAddressBarDividerWidth
        let locationViewPaddings = config.locationViewVerticalPaddings(addressBarPosition: toolbarPosition)
        toolbarBottomConstraint?.constant = -locationViewPaddings.bottom
        toolbarTopConstraint?.constant = locationViewPaddings.top
    }

    public func setAutocompleteSuggestion(_ suggestion: String?) {
        locationView.setAutocompleteSuggestion(suggestion)
    }

    override public func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        return locationView.becomeFirstResponder()
    }

    override public func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        return locationView.resignFirstResponder()
    }

    // MARK: - Private
    private func setupLayout() {
        addSubview(toolbarContainerView)
        addSubview(toolbarTopBorderView)
        addSubview(toolbarBottomBorderView)

        locationContainer.addSubview(leadingPageActionStack)
        locationContainer.addSubview(locationView)
        locationContainer.addSubview(locationDividerView)
        locationContainer.addSubview(trailingPageActionStack)

        toolbarContainerView.addSubview(navigationActionStack)
        toolbarContainerView.addSubview(locationContainer)
        toolbarContainerView.addSubview(browserActionStack)

        leadingLocationContainerConstraint = navigationActionStack.trailingAnchor.constraint(
            equalTo: locationContainer.leadingAnchor,
            constant: -UX.horizontalSpace)
        leadingLocationContainerConstraint?.isActive = true

        leadingBrowserActionConstraint = browserActionStack.leadingAnchor.constraint(
            equalTo: locationContainer.trailingAnchor,
            constant: UX.horizontalSpace)
        leadingBrowserActionConstraint?.isActive = true

        dividerWidthConstraint = locationDividerView.widthAnchor.constraint(equalToConstant: 0)
        dividerWidthConstraint?.isActive = true

        [navigationActionStack,
         leadingPageActionStack,
         trailingPageActionStack,
         browserActionStack].forEach(setZeroWidthConstraint)

        toolbarTopBorderHeightConstraint = toolbarTopBorderView.heightAnchor.constraint(equalToConstant: 0)
        toolbarBottomBorderHeightConstraint = toolbarBottomBorderView.heightAnchor.constraint(equalToConstant: 0)
        toolbarTopBorderHeightConstraint?.isActive = true
        toolbarBottomBorderHeightConstraint?.isActive = true

        leadingNavigationActionStackConstraint = navigationActionStack.leadingAnchor.constraint(
            equalTo: toolbarContainerView.leadingAnchor)
        leadingNavigationActionStackConstraint?.isActive = true

        trailingBrowserActionStackConstraint = browserActionStack.trailingAnchor.constraint(
            equalTo: toolbarContainerView.trailingAnchor)
        trailingBrowserActionStackConstraint?.isActive = true

        locationContainerHeightConstraint = locationContainer.heightAnchor.constraint(equalToConstant: UX.locationHeight)
        locationContainerHeightConstraint?.isActive = true

        toolbarBottomConstraint = toolbarContainerView.bottomAnchor.constraint(
            equalTo: toolbarBottomBorderView.bottomAnchor
        )
        toolbarBottomConstraint?.isActive = true

        toolbarTopConstraint = toolbarContainerView.topAnchor.constraint(equalTo: toolbarTopBorderView.topAnchor)
        toolbarTopConstraint?.isActive = true

        NSLayoutConstraint.activate([
            toolbarContainerView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            toolbarContainerView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),

            toolbarTopBorderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbarTopBorderView.topAnchor.constraint(equalTo: topAnchor),
            toolbarTopBorderView.trailingAnchor.constraint(equalTo: trailingAnchor),

            toolbarBottomBorderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbarBottomBorderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            toolbarBottomBorderView.bottomAnchor.constraint(equalTo: bottomAnchor),

            navigationActionStack.topAnchor.constraint(equalTo: toolbarContainerView.topAnchor),
            navigationActionStack.bottomAnchor.constraint(equalTo: toolbarContainerView.bottomAnchor),

            locationContainer.topAnchor.constraint(equalTo: toolbarContainerView.topAnchor),
            locationContainer.bottomAnchor.constraint(equalTo: toolbarContainerView.bottomAnchor),

            leadingPageActionStack.leadingAnchor.constraint(equalTo: locationContainer.leadingAnchor),
            leadingPageActionStack.topAnchor.constraint(equalTo: locationContainer.topAnchor),
            leadingPageActionStack.trailingAnchor.constraint(equalTo: locationView.leadingAnchor),
            leadingPageActionStack.bottomAnchor.constraint(equalTo: locationContainer.bottomAnchor),

            locationView.topAnchor.constraint(equalTo: locationContainer.topAnchor),
            locationView.trailingAnchor.constraint(equalTo: locationDividerView.leadingAnchor),
            locationView.bottomAnchor.constraint(equalTo: locationContainer.bottomAnchor),

            locationDividerView.topAnchor.constraint(equalTo: locationContainer.topAnchor),
            locationDividerView.trailingAnchor.constraint(equalTo: trailingPageActionStack.leadingAnchor),
            locationDividerView.bottomAnchor.constraint(equalTo: locationContainer.bottomAnchor),

            trailingPageActionStack.topAnchor.constraint(equalTo: locationContainer.topAnchor),
            trailingPageActionStack.trailingAnchor.constraint(equalTo: locationContainer.trailingAnchor),
            trailingPageActionStack.bottomAnchor.constraint(equalTo: locationContainer.bottomAnchor),

            browserActionStack.topAnchor.constraint(equalTo: toolbarContainerView.topAnchor),
            browserActionStack.bottomAnchor.constraint(equalTo: toolbarContainerView.bottomAnchor),
        ])

        updateActionSpacing(uxConfig: .default())

        setupAccessibility()
    }

    private func setupDragInteraction() {
        // Setup UIDragInteraction to handle dragging the location
        // bar for dropping its URL into other apps.
        let dragInteraction = UIDragInteraction(delegate: self)
        dragInteraction.allowsSimultaneousRecognitionDuringLift = true
        locationContainer.addInteraction(dragInteraction)
    }

    // MARK: - Accessibility
    private func setupAccessibility() {
        addInteraction(UILargeContentViewerInteraction())
    }

    private func adjustHeightConstraintForA11ySizeCategory() {
        let height = min(UIFontMetrics.default.scaledValue(for: UX.locationHeight), UX.locationMaxHeight)
        let contentSizeCategory = UIApplication.shared.preferredContentSizeCategory

        if contentSizeCategory.isAccessibilityCategory {
            locationContainerHeightConstraint?.constant = height
        } else {
            locationContainerHeightConstraint?.constant = UX.locationHeight
        }
    }

    // MARK: - Toolbar Actions and Layout Updates
    internal func updateActions(config: AddressToolbarConfiguration, animated: Bool) {
        // Browser actions
        updateActionStack(stackView: browserActionStack, toolbarElements: config.browserActions)

        // Navigation actions
        updateActionStack(stackView: navigationActionStack, toolbarElements: config.navigationActions)

        // Page actions
        updateActionStack(stackView: leadingPageActionStack, toolbarElements: config.leadingPageActions)
        updateActionStack(stackView: trailingPageActionStack, toolbarElements: config.trailingPageActions)

        updateActionSpacing(uxConfig: config.uxConfiguration)
        updateToolbarLayout(animated: animated)
    }

    private func updateToolbarLayout(animated: Bool) {
        let stacks = browserActionStack.arrangedSubviews +
                     navigationActionStack.arrangedSubviews +
                     leadingPageActionStack.arrangedSubviews +
                     trailingPageActionStack.arrangedSubviews
        let areAllStacksAlreadyVisible = stacks.allSatisfy { $0.alpha == 1.0 }
        guard !areAllStacksAlreadyVisible else { return }

        let isAnimationEnabled = !UIAccessibility.isReduceMotionEnabled && animated

        if isAnimationEnabled {
            UIView.animate(withDuration: UX.toolbarAnimationTime, delay: 0.0, options: .curveEaseOut) {
                self.layoutIfNeeded()
            }
            UIView.animate(withDuration: UX.iconsAnimationTime, delay: UX.iconsAnimationDelay, options: .curveEaseOut) {
                stacks.forEach {
                    $0.alpha = 1.0
                }
            }
        } else {
            stacks.forEach {
                $0.alpha = 1.0
            }
        }
    }

    private func updateSpacing(uxConfig: AddressToolbarUXConfiguration,
                               leading: CGFloat,
                               trailing: CGFloat) {
        leadingNavigationActionStackConstraint?.constant = leading
        trailingBrowserActionStackConstraint?.constant = -trailing
    }

    private func setZeroWidthConstraint(_ stackView: UIStackView) {
        let widthAnchor = stackView.widthAnchor.constraint(equalToConstant: 0)
        widthAnchor.isActive = true
        widthAnchor.priority = .defaultHigh
    }

    private func updateActionStack(stackView: UIStackView, toolbarElements: [ToolbarElement]) {
        let buttons = toolbarElements.map { toolbarElement in
            let hasCachedButton = hasCachedButton(for: toolbarElement)
            let button = getToolbarButton(for: toolbarElement)
            button.configure(element: toolbarElement)
            if !stackView.arrangedSubviews.contains(button) {
                button.alpha = 0
            }

            if let theme {
                // As we recreate the buttons we need to apply the theme for them to be displayed correctly
                button.applyTheme(theme: theme)
            }

            if let contextualHintType = toolbarElement.contextualHintType {
                toolbarDelegate?.configureContextualHint(self, for: button, with: contextualHintType)
            }

            // Only add the constraints to new buttons
            if !hasCachedButton {
                if button.configuration?.title == nil {
                    NSLayoutConstraint.activate([
                        button.widthAnchor.constraint(equalToConstant: UX.buttonSize.width),
                        button.heightAnchor.constraint(equalToConstant: UX.buttonSize.height),
                    ])
                } else {
                    NSLayoutConstraint.activate([
                        button.widthAnchor.constraint(greaterThanOrEqualToConstant: UX.buttonSize.width),
                        button.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.buttonSize.height),
                    ])
                    button.setContentCompressionResistancePriority(.required, for: .horizontal)
                }
            }
            return button
        }

        stackView.removeAllArrangedViews()

        buttons.forEach { button in
            stackView.addArrangedSubview(button)
        }
    }

    private func updateActionSpacing(uxConfig: AddressToolbarUXConfiguration) {
        // Browser action spacing
        let hasBrowserActions = !browserActionStack.arrangedSubviews.isEmpty
        leadingBrowserActionConstraint?.constant = hasBrowserActions ? UX.horizontalSpace : 0

        // Navigation action spacing
        let hasNavigationActions = !navigationActionStack.arrangedSubviews.isEmpty
        let isRegular = traitCollection.horizontalSizeClass == .regular
        leadingLocationContainerConstraint?.constant = hasNavigationActions && isRegular ? -UX.horizontalSpace : 0

        // Page action spacing
        let hasPageActions = !trailingPageActionStack.arrangedSubviews.isEmpty
        dividerWidthConstraint?.constant = hasPageActions ? uxConfig.browserActionsAddressBarDividerWidth : 0
    }

    private func updateBorder(borderPosition: AddressToolbarBorderPosition?) {
        switch borderPosition {
        case .top:
            toolbarTopBorderHeightConstraint?.constant = UX.borderHeight
            toolbarBottomBorderHeightConstraint?.constant = 0
        case .bottom:
            toolbarTopBorderHeightConstraint?.constant = 0
            toolbarBottomBorderHeightConstraint?.constant = UX.borderHeight
        default:
            toolbarTopBorderHeightConstraint?.constant = 0
            toolbarBottomBorderHeightConstraint?.constant = 0
        }
    }

    // MARK: - Notifiable
    nonisolated public func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIContentSizeCategory.didChangeNotification:
            ensureMainThread {
                self.adjustHeightConstraintForA11ySizeCategory()
            }
        default: break
        }
    }

    // MARK: - LocationViewDelegate
    func locationViewDidEnterText(_ text: String) {
        toolbarDelegate?.searchSuggestions(searchTerm: text)
    }

    func locationViewDidClearText() {
        toolbarDelegate?.didClearSearch()
    }

    func locationViewDidBeginEditing(_ text: String, shouldShowSuggestions: Bool) {
        toolbarDelegate?.addressToolbarDidBeginEditing(searchTerm: text, shouldShowSuggestions: shouldShowSuggestions)
    }

    func locationViewDidSubmitText(_ text: String) {
        guard !text.isEmpty else { return }

        toolbarDelegate?.openBrowser(searchTerm: text)
    }

    func locationViewDidTapSearchEngine<T: SearchEngineView>(_ searchEngine: T) {
        toolbarDelegate?.addressToolbarDidTapSearchEngine(searchEngine)
    }

    func locationViewAccessibilityActions() -> [UIAccessibilityCustomAction]? {
        toolbarDelegate?.addressToolbarAccessibilityActions()
    }

    func locationViewDidBeginDragInteraction() {
        toolbarDelegate?.addressToolbarDidBeginDragInteraction()
    }

    func locationTextFieldNeedsSearchReset() {
        toolbarDelegate?.addressToolbarNeedsSearchReset()
    }

    // MARK: - ThemeApplicable
    public func applyTheme(theme: Theme) {
        let colors = theme.colors
        // Set background color to clear when address bar is positioned at top to avoid
        // double opacity effects. The status bar overlay already provides the necessary
        // alpha gradient that matches the bottom navigation bar's appearance.
        backgroundColor = addressBarPosition == .top ? .clear :
        previousConfiguration?.uxConfiguration.addressToolbarBackgroundColor(theme: theme)
        locationContainer.backgroundColor = previousConfiguration?.uxConfiguration
            .locationContainerBackgroundColor(theme: theme)
        locationDividerView.backgroundColor = colors.layer1
        toolbarTopBorderView.backgroundColor = colors.borderPrimary
        toolbarBottomBorderView.backgroundColor = colors.borderPrimary
        locationContainer.applyTheme(theme: theme)
        locationView.applyTheme(theme: theme)
        self.theme = theme
    }

    // MARK: - UIDragInteractionDelegate
    public func dragInteraction(_ interaction: UIDragInteraction,
                                itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        let dragPoint = session.location(in: self)
        guard let url = droppableUrl,
              let itemProvider = NSItemProvider(contentsOf: url),
              // allow drag only on the location view frame in order to don't mess with long press gesture
              // on the address bar buttons.
              locationView.frame.contains(dragPoint) else { return [] }

        toolbarDelegate?.addressToolbarDidProvideItemsForDragInteraction()

        let dragItem = UIDragItem(itemProvider: itemProvider)
        return [dragItem]
    }

    public func dragInteraction(_ interaction: UIDragInteraction, sessionWillBegin session: UIDragSession) {
        toolbarDelegate?.addressToolbarDidBeginDragInteraction()
    }
}
