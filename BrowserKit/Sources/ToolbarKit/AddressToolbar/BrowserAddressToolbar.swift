// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// Simple address toolbar implementation.
/// +-------------+------------+-----------------------+----------+
/// | navigation  | indicators | url       [ page    ] | browser  |
/// |   actions   |            |           [ actions ] | actions  |
/// +-------------+------------+-----------------------+----------+
public class BrowserAddressToolbar: UIView,
                                    Notifiable,
                                    AddressToolbar,
                                    ThemeApplicable,
                                    LocationViewDelegate,
                                    UIDragInteractionDelegate {
    private enum UX {
        static let verticalEdgeSpace: CGFloat = 8
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

    /// A cache of `ToolbarButton` instances keyed by their accessibility identifier (`a11yId`).
    /// This improves performance by reusing buttons instead of creating new instances.
    private(set) var cachedButtonReferences = [String: ToolbarButton]()

    private lazy var toolbarContainerView: UIView = .build()
    private lazy var navigationActionStack: UIStackView = .build()

    private lazy var locationContainer: UIView = .build()

    private lazy var locationView: LocationView = .build()
    private lazy var locationDividerView: UIView = .build()

    private lazy var pageActionStack: UIStackView = .build { view in
        view.spacing = UX.actionSpacing
    }
    private lazy var browserActionStack: UIStackView = .build()
    private lazy var toolbarTopBorderView: UIView = .build()
    private lazy var toolbarBottomBorderView: UIView = .build()

    private var leadingBrowserActionConstraint: NSLayoutConstraint?
    private var leadingLocationContainerConstraint: NSLayoutConstraint?
    private var dividerWidthConstraint: NSLayoutConstraint?
    private var toolbarTopBorderHeightConstraint: NSLayoutConstraint?
    private var toolbarBottomBorderHeightConstraint: NSLayoutConstraint?
    private var leadingNavigationActionStackConstraint: NSLayoutConstraint?
    private var trailingBrowserActionStackConstraint: NSLayoutConstraint?
    private var locationContainerHeightConstraint: NSLayoutConstraint?
    private var navigationStackConstrains: [NSLayoutConstraint] = []

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
                toolbarCornerRadius: previousConfiguration.uxConfiguration.toolbarCornerRadius,
                isLocationTextCentered: previousConfiguration.uxConfiguration.isLocationTextCentered
            )
        }
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
        setupNotifications(forObserver: self, observing: [UIContentSizeCategory.didChangeNotification])
        adjustHeightConstraintForA11ySizeCategory()
        setupDragInteraction()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(config: AddressToolbarConfiguration,
                          toolbarDelegate: any AddressToolbarDelegate,
                          leadingSpace: CGFloat,
                          trailingSpace: CGFloat,
                          isUnifiedSearchEnabled: Bool,
                          animated: Bool) {
        self.toolbarDelegate = toolbarDelegate
        self.isUnifiedSearchEnabled = isUnifiedSearchEnabled
        self.previousConfiguration = config
        configureUX(config: config.uxConfiguration)
        updateSpacing(uxConfig: config.uxConfiguration, leading: leadingSpace, trailing: trailingSpace)
        configure(config: config,
                  isUnifiedSearchEnabled: isUnifiedSearchEnabled,
                  animated: animated)
    }

    public func configure(config: AddressToolbarConfiguration, isUnifiedSearchEnabled: Bool, animated: Bool) {
        updateBorder(borderPosition: config.borderPosition)

        locationView.configure(
            config.locationViewConfiguration,
            delegate: self,
            isUnifiedSearchEnabled: isUnifiedSearchEnabled,
            toolbarCornerRadius: config.uxConfiguration.toolbarCornerRadius,
            isLocationTextCentered: config.uxConfiguration.isLocationTextCentered
        )
        updateActions(config: config, animated: animated)
        droppableUrl = config.locationViewConfiguration.droppableUrl
    }

    private func configureUX(config: AddressToolbarUXConfiguration) {
        locationContainer.layer.cornerRadius = config.toolbarCornerRadius
        dividerWidthConstraint?.constant = config.browserActionsAddressBarDividerWidth

        if config.isNavigationActionsInsideLocationView {
            guard navigationActionStack.superview != locationContainer else { return }
            navigationActionStack.removeFromSuperview()
            constraintNavigationStackToLocationContainer()
        } else {
            guard navigationActionStack.superview != toolbarContainerView else { return }
            navigationActionStack.removeFromSuperview()
            constraintNavigationStackToToolbarContainer()
        }
    }

    private func constraintNavigationStackToLocationContainer() {
        NSLayoutConstraint.deactivate(navigationStackConstrains)
        locationContainer.addSubview(navigationActionStack)

        leadingLocationContainerConstraint?.isActive = false
        leadingLocationContainerConstraint = locationContainer.leadingAnchor.constraint(
            equalTo: toolbarContainerView.leadingAnchor,
            constant: UX.horizontalSpace
        )
        leadingLocationContainerConstraint?.isActive = true

        leadingNavigationActionStackConstraint?.isActive = false
        leadingNavigationActionStackConstraint = navigationActionStack.leadingAnchor
            .constraint(equalTo: locationContainer.leadingAnchor)
        leadingNavigationActionStackConstraint?.isActive = true

        navigationStackConstrains = [
            navigationActionStack.topAnchor.constraint(equalTo: locationContainer.topAnchor),
            navigationActionStack.bottomAnchor.constraint(equalTo: locationContainer.bottomAnchor),
            navigationActionStack.trailingAnchor.constraint(equalTo: locationView.leadingAnchor),
            locationView.leadingAnchor.constraint(equalTo: navigationActionStack.trailingAnchor)
        ]
        NSLayoutConstraint.activate(navigationStackConstrains)
    }

    private func constraintNavigationStackToToolbarContainer() {
        NSLayoutConstraint.deactivate(navigationStackConstrains)
        toolbarContainerView.addSubview(navigationActionStack)

        leadingNavigationActionStackConstraint?.isActive = false
        leadingNavigationActionStackConstraint = navigationActionStack.leadingAnchor.constraint(
            equalTo: toolbarContainerView.leadingAnchor)
        leadingNavigationActionStackConstraint?.isActive = true

        leadingLocationContainerConstraint?.isActive = false
        leadingLocationContainerConstraint = navigationActionStack.trailingAnchor.constraint(
            equalTo: locationContainer.leadingAnchor,
            constant: -UX.horizontalSpace)
        leadingLocationContainerConstraint?.isActive = true

        navigationStackConstrains = [
            navigationActionStack.topAnchor.constraint(equalTo: toolbarContainerView.topAnchor),
            navigationActionStack.bottomAnchor.constraint(equalTo: toolbarContainerView.bottomAnchor),
            locationView.leadingAnchor.constraint(equalTo: locationContainer.leadingAnchor)
        ]
        NSLayoutConstraint.activate(navigationStackConstrains)
    }

    public func setAutocompleteSuggestion(_ suggestion: String?) {
        locationView.setAutocompleteSuggestion(suggestion)
    }

    override public func becomeFirstResponder() -> Bool {
        return locationView.becomeFirstResponder()
    }

    override public func resignFirstResponder() -> Bool {
        return locationView.resignFirstResponder()
    }

    // MARK: - Private
    private func setupLayout() {
        addSubview(toolbarContainerView)
        addSubview(toolbarTopBorderView)
        addSubview(toolbarBottomBorderView)

        locationContainer.addSubview(locationView)
        locationContainer.addSubview(locationDividerView)
        locationContainer.addSubview(pageActionStack)

        toolbarContainerView.addSubview(locationContainer)
        toolbarContainerView.addSubview(browserActionStack)

        leadingBrowserActionConstraint = browserActionStack.leadingAnchor.constraint(
            equalTo: locationContainer.trailingAnchor,
            constant: UX.horizontalSpace)
        leadingBrowserActionConstraint?.isActive = true

        dividerWidthConstraint = locationDividerView.widthAnchor.constraint(equalToConstant: 0)
        dividerWidthConstraint?.isActive = true

        [navigationActionStack, pageActionStack, browserActionStack].forEach(setZeroWidthConstraint)

        toolbarTopBorderHeightConstraint = toolbarTopBorderView.heightAnchor.constraint(equalToConstant: 0)
        toolbarBottomBorderHeightConstraint = toolbarBottomBorderView.heightAnchor.constraint(equalToConstant: 0)
        toolbarTopBorderHeightConstraint?.isActive = true
        toolbarBottomBorderHeightConstraint?.isActive = true

        trailingBrowserActionStackConstraint = browserActionStack.trailingAnchor.constraint(
            equalTo: toolbarContainerView.trailingAnchor)
        trailingBrowserActionStackConstraint?.isActive = true

        locationContainerHeightConstraint = locationContainer.heightAnchor.constraint(equalToConstant: UX.locationHeight)
        locationContainerHeightConstraint?.isActive = true

        constraintNavigationStackToToolbarContainer()

        NSLayoutConstraint.activate([
            toolbarContainerView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            toolbarContainerView.topAnchor.constraint(equalTo: toolbarTopBorderView.topAnchor,
                                                      constant: UX.verticalEdgeSpace),
            toolbarContainerView.bottomAnchor.constraint(equalTo: toolbarBottomBorderView.bottomAnchor,
                                                         constant: -UX.verticalEdgeSpace),
            toolbarContainerView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),

            toolbarTopBorderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbarTopBorderView.topAnchor.constraint(equalTo: topAnchor),
            toolbarTopBorderView.trailingAnchor.constraint(equalTo: trailingAnchor),

            toolbarBottomBorderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbarBottomBorderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            toolbarBottomBorderView.bottomAnchor.constraint(equalTo: bottomAnchor),

            locationContainer.topAnchor.constraint(equalTo: toolbarContainerView.topAnchor),
            locationContainer.bottomAnchor.constraint(equalTo: toolbarContainerView.bottomAnchor),

            locationView.topAnchor.constraint(equalTo: locationContainer.topAnchor),
            locationView.trailingAnchor.constraint(equalTo: locationDividerView.leadingAnchor),
            locationView.bottomAnchor.constraint(equalTo: locationContainer.bottomAnchor),

            locationDividerView.topAnchor.constraint(equalTo: locationContainer.topAnchor),
            locationDividerView.trailingAnchor.constraint(equalTo: pageActionStack.leadingAnchor),
            locationDividerView.bottomAnchor.constraint(equalTo: locationContainer.bottomAnchor),

            pageActionStack.topAnchor.constraint(equalTo: locationContainer.topAnchor),
            pageActionStack.trailingAnchor.constraint(equalTo: locationContainer.trailingAnchor),
            pageActionStack.bottomAnchor.constraint(equalTo: locationContainer.bottomAnchor),

            browserActionStack.topAnchor.constraint(equalTo: toolbarContainerView.topAnchor),
            browserActionStack.bottomAnchor.constraint(equalTo: toolbarContainerView.bottomAnchor),
        ])

        updateActionSpacing(uxConfig: .default)

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
        setNeedsLayout()
    }

    // MARK: - Toolbar Actions and Layout Updates
    internal func updateActions(config: AddressToolbarConfiguration, animated: Bool) {
        // Browser actions
        updateActionStack(stackView: browserActionStack, toolbarElements: config.browserActions)

        // Navigation actions
        updateActionStack(stackView: navigationActionStack, toolbarElements: config.navigationActions)

        // Page actions
        updateActionStack(stackView: pageActionStack, toolbarElements: config.pageActions)

        updateActionSpacing(uxConfig: config.uxConfiguration)
        updateToolbarLayout(animated: animated)
    }

    private func updateToolbarLayout(animated: Bool) {
        let stacks = browserActionStack.arrangedSubviews +
                     navigationActionStack.arrangedSubviews +
                     pageActionStack.arrangedSubviews
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
            layoutIfNeeded()
        }
    }

    private func updateSpacing(uxConfig: AddressToolbarUXConfiguration,
                               leading: CGFloat,
                               trailing: CGFloat) {
        if uxConfig.isNavigationActionsInsideLocationView {
            leadingNavigationActionStackConstraint?.constant = leading
            leadingLocationContainerConstraint?.constant = trailing
        } else {
            leadingNavigationActionStackConstraint?.constant = leading
        }
        trailingBrowserActionStackConstraint?.constant = -trailing
    }

    private func setZeroWidthConstraint(_ stackView: UIStackView) {
        let widthAnchor = stackView.widthAnchor.constraint(equalToConstant: 0)
        widthAnchor.isActive = true
        widthAnchor.priority = .defaultHigh
    }

    /// Retrieves a `ToolbarButton` for the given `ToolbarElement`.
    /// If a cached button exists for the element's accessibility identifier, it returns the cached button.
    /// Otherwise, it creates a new button, caches it, and then returns it.
    /// - Parameter toolbarElement: The `ToolbarElement` for which to retrieve the button.
    /// - Returns: A `ToolbarButton` instance configured for the given `ToolbarElement`.
    func getToolbarButton(for toolbarElement: ToolbarElement) -> ToolbarButton {
        let button: ToolbarButton
        if let cachedButton = cachedButtonReferences[toolbarElement.a11yId] {
            button = cachedButton
        } else {
            button = toolbarElement.numberOfTabs != nil ? TabNumberButton() : ToolbarButton()
            cachedButtonReferences[toolbarElement.a11yId] = button
        }

        return button
    }

    private func updateActionStack(stackView: UIStackView, toolbarElements: [ToolbarElement]) {
        let buttons = toolbarElements.map { toolbarElement in
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
            return button
        }

        stackView.removeAllArrangedViews()

        buttons.forEach { button in
            stackView.addArrangedSubview(button)

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
    }

    private func updateActionSpacing(uxConfig: AddressToolbarUXConfiguration) {
        // Browser action spacing
        let hasBrowserActions = !browserActionStack.arrangedSubviews.isEmpty
        leadingBrowserActionConstraint?.constant = hasBrowserActions ? UX.horizontalSpace : 0

        // Navigation action spacing
        let hasNavigationActions = !navigationActionStack.arrangedSubviews.isEmpty
        let isRegular = traitCollection.horizontalSizeClass == .regular
        if !uxConfig.isNavigationActionsInsideLocationView {
            leadingLocationContainerConstraint?.constant = hasNavigationActions && isRegular ? -UX.horizontalSpace : 0
        }

        // Page action spacing
        let hasPageActions = !pageActionStack.arrangedSubviews.isEmpty
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
    public func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIContentSizeCategory.didChangeNotification:
            adjustHeightConstraintForA11ySizeCategory()
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
        backgroundColor = previousConfiguration?.uxConfiguration
            .addressToolbarBackgroundColor(theme: theme)
        locationContainer.backgroundColor = previousConfiguration?.uxConfiguration
            .locationContainerBackgroundColor(theme: theme)
        locationDividerView.backgroundColor = colors.layer1
        toolbarTopBorderView.backgroundColor = colors.borderPrimary
        toolbarBottomBorderView.backgroundColor = colors.borderPrimary
        locationView.applyTheme(theme: theme)
        self.theme = theme
    }

    // MARK: - UIDragInteractionDelegate
    public func dragInteraction(_ interaction: UIDragInteraction,
                                itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        guard let url = droppableUrl, let itemProvider = NSItemProvider(contentsOf: url) else { return [] }

        toolbarDelegate?.addressToolbarDidProvideItemsForDragInteraction()

        let dragItem = UIDragItem(itemProvider: itemProvider)
        return [dragItem]
    }

    public func dragInteraction(_ interaction: UIDragInteraction, sessionWillBegin session: UIDragSession) {
        toolbarDelegate?.addressToolbarDidBeginDragInteraction()
    }
}
