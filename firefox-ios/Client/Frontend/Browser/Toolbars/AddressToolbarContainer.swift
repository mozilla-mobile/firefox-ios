// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit
import UIKit

protocol URLBarViewProtocol {
    @MainActor
    var inOverlayMode: Bool { get }
    @MainActor
    func enterOverlayMode(_ locationText: String?, pasted: Bool, search: Bool)
    @MainActor
    func leaveOverlayMode(reason: URLBarLeaveOverlayModeReason, shouldCancelLoading cancel: Bool)
}

/// Describes the reason for leaving overlay mode.
enum URLBarLeaveOverlayModeReason {
    /// The user committed their edits.
    case finished

    /// The user aborted their edits.
    case cancelled
}

protocol AddressToolbarContainerDelegate: AnyObject {
    @MainActor
    func searchSuggestions(searchTerm: String)
    @MainActor
    func openBrowser(searchTerm: String)
    @MainActor
    func openSuggestions(searchTerm: String)
    @MainActor
    func configureContextualHint(for button: UIButton, with contextualHintType: String)
    @MainActor
    func addressToolbarDidBeginEditing(searchTerm: String, shouldShowSuggestions: Bool)
    @MainActor
    func addressToolbarContainerAccessibilityActions() -> [UIAccessibilityCustomAction]?
    @MainActor
    func addressToolbarDidEnterOverlayMode(_ view: UIView)
    @MainActor
    func addressToolbar(_ view: UIView, didLeaveOverlayModeForReason: URLBarLeaveOverlayModeReason)
    @MainActor
    func addressToolbarDidBeginDragInteraction()
    @MainActor
    func addressToolbarDidTapSearchEngine(_ searchEngineView: UIView)
}

final class AddressToolbarContainer: UIView,
                                     ThemeApplicable,
                                     TopBottomInterchangeable,
                                     AlphaDimmable,
                                     StoreSubscriber,
                                     AddressToolbarDelegate,
                                     Autocompletable,
                                     URLBarViewProtocol,
                                     FeatureFlaggable,
                                     PrivateModeUI {
    private enum UX {
        static let toolbarHorizontalPadding: CGFloat = 16
        static let toolbarIsEditingLeadingPadding: CGFloat = 0
        static let skeletonBarOffset: CGFloat = 8
        static let skeletonBarBottomPositionOffset: CGFloat = 4
        static let skeletonBarWidthOffset: CGFloat = 32
        static let addNewTabFadeAnimationDuration: TimeInterval = 0.2
        static let addNewTabPercentageAnimationThreshold: CGFloat = 0.3
        static let keyboardAccessoryViewOffset: CGFloat = 22
        static let accessoryViewGradientOffset: CGFloat = 74
    }

    typealias SubscriberStateType = ToolbarState

    private let isMinimalAddressBarEnabled: Bool
    private let toolbarHelper: ToolbarHelperInterface
    private var windowUUID: WindowUUID?
    private var profile: Profile?
    private var model: AddressToolbarContainerModel?
    private var state: ToolbarState?
    private(set) weak var delegate: AddressToolbarContainerDelegate?

    // FXIOS-10210 Temporary to support updating the Unified Search feature flag during runtime
    public var isUnifiedSearchEnabled = false {
        didSet {
            guard oldValue != isUnifiedSearchEnabled else { return }

            regularToolbar.isUnifiedSearchEnabled = isUnifiedSearchEnabled
        }
    }

    private var toolbar: BrowserAddressToolbar {
        return regularToolbar
    }

    private var searchTerm = ""
    private var shouldDisplayCompact = true
    private var isTransitioning = false {
        didSet {
            if isTransitioning {
                // Cancel any pending/in-progress animations related to the progress bar
                self.progressBar.setProgress(1, animated: false)
                self.progressBar.alpha = 0.0
            }
        }
    }

    var parent: UIStackView?
    var onContainerTap: (() -> Void)?
    private lazy var regularToolbar: RegularBrowserAddressToolbar = .build()
    private lazy var leftSkeletonAddressBar: RegularBrowserAddressToolbar = .build()
    private lazy var rightSkeletonAddressBar: RegularBrowserAddressToolbar = .build()
    private lazy var progressBar: GradientProgressBar = .build { bar in
        bar.clipsToBounds = false
    }
    private lazy var addNewTabView: AddressToolbarAddTabView = .build()
    private lazy var accessoryViewGradient = CAGradientLayer()

    private var addNewTabTrailingConstraint: NSLayoutConstraint?
    private var addNewTabLeadingConstraint: NSLayoutConstraint?
    private var addNewTabTopConstraint: NSLayoutConstraint?
    private var addNewTabBottomConstraint: NSLayoutConstraint?

    private var progressBarTopConstraint: NSLayoutConstraint?
    private var progressBarBottomConstraint: NSLayoutConstraint?

    private func calculateToolbarTrailingSpace() -> CGFloat {
        if shouldDisplayCompact {
            return UX.toolbarHorizontalPadding
        }
        if traitCollection.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .regular {
            return UX.toolbarHorizontalPadding
        }
        // Provide 0 padding in iPhone landscape due to safe area insets
        return 0
    }

    private func calculateToolbarLeadingSpace(isEditing: Bool, toolbarLayoutStyle: ToolbarLayoutStyle) -> CGFloat {
        if shouldDisplayCompact {
            return UX.toolbarHorizontalPadding
        }

        // Provide 0 padding in iPhone landscape due to safe area insets
        if traitCollection.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .regular {
            return UX.toolbarHorizontalPadding
        }
        return 0
    }

    /// Overlay mode is the state where the lock/reader icons are hidden, the home panels are shown,
    /// and the Cancel button is visible (allowing the user to leave overlay mode).
    var inOverlayMode = false

    init(isMinimalAddressBarEnabled: Bool, toolbarHelper: ToolbarHelperInterface = ToolbarHelper()) {
        self.isMinimalAddressBarEnabled = isMinimalAddressBarEnabled
        self.toolbarHelper = toolbarHelper
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        // TODO: FXIOS-13097 This is a work around until we can leverage isolated deinits
        guard Thread.isMainThread else {
            DefaultLogger.shared.log(
                "AddressToolbarContainer was not deallocated on the main thread. Redux was not cleaned up.",
                level: .fatal,
                category: .lifecycle
            )
            assertionFailure("The view was not deallocated on the main thread. Redux was not cleaned up.")
            return
        }

        MainActor.assumeIsolated {
            unsubscribeFromRedux()
        }
    }

    func configure(
        windowUUID: WindowUUID,
        profile: Profile,
        searchEnginesManager: SearchEnginesManagerProvider,
        delegate: AddressToolbarContainerDelegate,
        isUnifiedSearchEnabled: Bool,
        isBottomSearchBar: Bool
    ) {
        self.windowUUID = windowUUID
        self.profile = profile
        self.delegate = delegate
        self.isUnifiedSearchEnabled = isUnifiedSearchEnabled
        setupLayout(isBottomSearchBar: isBottomSearchBar)
        subscribeToRedux()
    }

    func updateProgressBar(progress: Double) {
        DispatchQueue.main.async { [unowned self] in
            progressBar.alpha = 1
            progressBar.isHidden = false
            progressBar.setProgress(Float(progress), animated: !isTransitioning)
        }
    }

    func hideProgressBar() {
        progressBar.isHidden = true
        progressBar.setProgress(0, animated: false)
    }

    func hideSkeletonBars() {
        let needsConfiguration = !leftSkeletonAddressBar.isHidden || !rightSkeletonAddressBar.isHidden

        if toolbarHelper.isToolbarTranslucencyRefactorEnabled && needsConfiguration {
            configureSkeletonAddressBars(previousTab: nil, forwardTab: nil)
        }

        leftSkeletonAddressBar.isHidden = true
        rightSkeletonAddressBar.isHidden = true
    }

    func offsetForKeyboardAccessory(hasAccessoryView: Bool) -> CGFloat {
        guard #available(iOS 26.0, *), let windowUUID else { return 0 }

        let isEditingAddress = state?.addressToolbar.isEditing == true
        let shouldShowKeyboard = state?.addressToolbar.shouldShowKeyboard
        let isBottomToolbar = state?.toolbarPosition == .bottom
        let shouldAdjustForAccessory = hasAccessoryView &&
                                       !isEditingAddress &&
                                       isBottomToolbar

        let accessoryViewOffset = shouldAdjustForAccessory ? UX.keyboardAccessoryViewOffset : 0

        /// We want to check here if the keyboard accessory view state has changed
        /// To avoid spamming redux actions.
        guard hasAccessoryView != shouldShowKeyboard else { return accessoryViewOffset }
        store.dispatch(
            ToolbarAction(
                shouldShowKeyboard: hasAccessoryView,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.keyboardStateDidChange
            )
        )

        if shouldAdjustForAccessory {
            let height = frame.height + UX.accessoryViewGradientOffset
            accessoryViewGradient.frame = CGRect(width: bounds.width, height: height)
            accessoryViewGradient.opacity = 1
            store.dispatch(
                ToolbarAction(
                    scrollAlpha: 0,
                    windowUUID: windowUUID,
                    actionType: ToolbarActionType.scrollAlphaNeedsUpdate
                )
            )
        }
        return accessoryViewOffset
    }

    func updateSkeletonAddressBarsVisibility(tabManager: TabManager) {
        let isToolbarAtBottom = state?.toolbarPosition == .bottom
        guard let selectedTab = tabManager.selectedTab, isToolbarAtBottom else {
            hideSkeletonBars()
            return
        }

        let tabs = selectedTab.isPrivate ? tabManager.privateTabs : tabManager.normalTabs
        guard let index = tabs.firstIndex(where: { $0 === selectedTab }) else { return }

        let previousTab = tabs[safe: index-1]
        let forwardTab = tabs[safe: index+1]

        configureSkeletonAddressBars(previousTab: previousTab, forwardTab: forwardTab)
        leftSkeletonAddressBar.isHidden = previousTab == nil
        rightSkeletonAddressBar.isHidden = forwardTab == nil
    }

    override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        return toolbar.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        return toolbar.resignFirstResponder()
    }

    // MARK: - Redux

    func subscribeToRedux() {
        guard let windowUUID else { return }

        let action = ScreenAction(windowUUID: windowUUID,
                                  actionType: ScreenActionType.showScreen,
                                  screen: .toolbar)
        store.dispatch(action)

        store.subscribe(self, transform: {
            $0.select({ appState in
                return ToolbarState(appState: appState, uuid: windowUUID)
            })
        })
    }

    func unsubscribeFromRedux() {
        guard let windowUUID else {
            store.unsubscribe(self)
            return
        }

        let action = ScreenAction(windowUUID: windowUUID,
                                  actionType: ScreenActionType.closeScreen,
                                  screen: .toolbar)
        store.dispatch(action)
        store.unsubscribe(self)
    }

    func newState(state: ToolbarState) {
        self.state = state
        updateModel(toolbarState: state)
    }

    // MARK: - AlphaDimmable
    func updateAlphaForSubviews(_ alpha: CGFloat) {
        let isReaderModeActive = state?.addressToolbar.readerModeState == .active
        if !isMinimalAddressBarEnabled || isReaderModeActive {
            // when the user scrolls the webpage the address toolbar gets hidden by changing its alpha
            regularToolbar.alpha = alpha
        }
        updateSkeletonAddressBarsAlpha(to: alpha)
    }

    private func updateModel(toolbarState: ToolbarState) {
        guard let windowUUID, let profile else { return }
        let newModel = AddressToolbarContainerModel(state: toolbarState,
                                                    profile: profile,
                                                    windowUUID: windowUUID)

        shouldDisplayCompact = newModel.shouldDisplayCompact

        guard self.model != newModel else { return }

        updateSkeletonAddressBarsAlpha(to: CGFloat(newModel.scrollAlpha))
        if #available(iOS 26.0, *), !newModel.shouldShowKeyboard, !newModel.scrollAlpha.isZero {
            accessoryViewGradient.opacity = 0
        }
        // in case we are in edit mode but overlay is not active yet we have to activate it
        // so that `inOverlayMode` is set to true so we avoid getting stuck in overlay mode
        if newModel.isEditing, !inOverlayMode {
            enterOverlayMode(nil, pasted: false, search: true)
        }
        updateProgressBarPosition(toolbarState.toolbarPosition)
        // When frame is zero it means the toolbar hasn't appeared on screen yet for the first time
        // so to prevent a flashy animation on start disable the animation.
        let shouldAnimate = newModel.shouldAnimate && frame != .zero
        regularToolbar.configure(
            config: newModel.addressToolbarConfig,
            toolbarPosition: toolbarState.toolbarPosition,
            toolbarDelegate: self,
            leadingSpace: calculateToolbarLeadingSpace(isEditing: newModel.isEditing,
                                                       toolbarLayoutStyle: newModel.toolbarLayoutStyle),
            trailingSpace: calculateToolbarTrailingSpace(),
            isUnifiedSearchEnabled: isUnifiedSearchEnabled,
            animated: shouldAnimate)

        let addressBarVerticalPaddings = newModel.addressToolbarConfig.uxConfiguration
            .locationViewVerticalPaddings(addressBarPosition: toolbarState.toolbarPosition)
        addNewTabTopConstraint?.constant = addressBarVerticalPaddings.top
        addNewTabBottomConstraint?.constant = -addressBarVerticalPaddings.bottom
        addNewTabView.configure(newModel.addressToolbarConfig.uxConfiguration)

        // Replace the old model after we are done using it for comparison
        // All functionality that depends on the new model should come after this
        self.model = newModel

        self.maximumContentSizeCategory = .extraExtraExtraLarge
    }

    private func configureSkeletonAddressBars(previousTab: Tab?, forwardTab: Tab?) {
        guard let model else { return }
        leftSkeletonAddressBar.configureNonInteractive(
            config: model.getSkeletonAddressBarConfiguration(for: previousTab),
            leadingSpace: UX.skeletonBarOffset,
            trailingSpace: -UX.skeletonBarOffset
        )
        rightSkeletonAddressBar.configureNonInteractive(
            config: model.getSkeletonAddressBarConfiguration(for: forwardTab),
            leadingSpace: -UX.skeletonBarOffset,
            trailingSpace: UX.skeletonBarOffset
        )
        leftSkeletonAddressBar.accessibilityIdentifier = AccessibilityIdentifiers.Browser.AddressToolbar.leadingSkeleton
        rightSkeletonAddressBar.accessibilityIdentifier = AccessibilityIdentifiers.Browser.AddressToolbar.trailingSkeleton
    }

    private func updateSkeletonAddressBarsAlpha(to alpha: CGFloat) {
        guard toolbarHelper.isSwipingTabsEnabled else { return }

        leftSkeletonAddressBar.alpha = alpha
        rightSkeletonAddressBar.alpha = alpha
    }

    private func setupLayout(isBottomSearchBar: Bool) {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onContainerTapped))
        addGestureRecognizer(tapGesture)

        addSubview(progressBar)
        setupAccessoryViewGradient()

        NSLayoutConstraint.activate([
            progressBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        setupToolbarConstraints(isBottomSearchBar: isBottomSearchBar)
        setupSkeletonAddressBarsLayout(isBottomSearchBar: isBottomSearchBar)

        addSubview(addNewTabView)
        addNewTabLeadingConstraint = addNewTabView.leadingAnchor.constraint(equalTo: trailingAnchor)
        addNewTabTrailingConstraint = addNewTabView.trailingAnchor.constraint(equalTo: trailingAnchor)
        addNewTabTopConstraint = addNewTabView.topAnchor.constraint(equalTo: topAnchor)
        addNewTabBottomConstraint = addNewTabView.bottomAnchor.constraint(equalTo: bottomAnchor)

        addNewTabTrailingConstraint?.isActive = true
        addNewTabTopConstraint?.isActive = true
        addNewTabBottomConstraint?.isActive = true
        addNewTabLeadingConstraint?.isActive = true
    }

    private func setupToolbarConstraints(isBottomSearchBar: Bool) {
        addSubview(toolbar)
        if toolbarHelper.isSwipingTabsEnabled && isBottomSearchBar {
            insertSubview(leftSkeletonAddressBar, aboveSubview: toolbar)
            insertSubview(rightSkeletonAddressBar, aboveSubview: toolbar)

            toolbar.leadingAnchor.constraint(equalTo: leftSkeletonAddressBar.trailingAnchor).isActive = true
            toolbar.trailingAnchor.constraint(equalTo: rightSkeletonAddressBar.leadingAnchor).isActive = true
        } else {
            toolbar.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            toolbar.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        }

        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: topAnchor),
            toolbar.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func setupSkeletonAddressBarsLayout(isBottomSearchBar: Bool) {
        guard toolbarHelper.isSwipingTabsEnabled, isBottomSearchBar else { return }

        NSLayoutConstraint.activate([
            leftSkeletonAddressBar.topAnchor.constraint(equalTo: topAnchor),
            leftSkeletonAddressBar.trailingAnchor.constraint(equalTo: leadingAnchor),
            leftSkeletonAddressBar.bottomAnchor.constraint(equalTo: bottomAnchor),
            leftSkeletonAddressBar.widthAnchor.constraint(equalTo: widthAnchor, constant: -UX.skeletonBarWidthOffset),

            rightSkeletonAddressBar.topAnchor.constraint(equalTo: topAnchor),
            rightSkeletonAddressBar.leadingAnchor.constraint(equalTo: trailingAnchor),
            rightSkeletonAddressBar.bottomAnchor.constraint(equalTo: bottomAnchor),
            rightSkeletonAddressBar.widthAnchor.constraint(equalTo: widthAnchor, constant: -UX.skeletonBarWidthOffset)
        ])
    }

    private func updateProgressBarPosition(_ position: AddressToolbarPosition) {
        progressBarTopConstraint?.isActive = false
        progressBarBottomConstraint?.isActive = false

        switch position {
        case .top:
            progressBarTopConstraint = progressBar.topAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
            progressBarTopConstraint?.isActive = true
        case .bottom:
            progressBarBottomConstraint = progressBar.bottomAnchor.constraint(lessThanOrEqualTo: topAnchor)
            progressBarBottomConstraint?.isActive = true
        }
    }

    private func setupAccessoryViewGradient() {
        guard #available(iOS 26.0, *) else { return }
        accessoryViewGradient.startPoint = CGPoint(x: 0.5, y: 0)
        accessoryViewGradient.endPoint = CGPoint(x: 0.5, y: 1)
        layer.insertSublayer(accessoryViewGradient, at: 0)
    }

    func applyTransform(_ transform: CGAffineTransform, shouldAddNewTab: Bool) {
        regularToolbar.transform = transform
        leftSkeletonAddressBar.transform = transform
        rightSkeletonAddressBar.transform = transform
        if shouldAddNewTab {
            let percentageTransform = abs(transform.tx) / bounds.width
            UIView.animate(withDuration: UX.addNewTabFadeAnimationDuration) {
                self.addNewTabView.showHideAddTabIcon(shouldShow:
                                                        percentageTransform > UX.addNewTabPercentageAnimationThreshold)
                self.addNewTabTrailingConstraint?.constant =
                percentageTransform > UX.addNewTabPercentageAnimationThreshold ?
                    -UX.toolbarHorizontalPadding : 0.0
                self.layoutIfNeeded()
            }
            let isRTL = UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft
            addNewTabLeadingConstraint?.constant = isRTL ? -transform.tx : transform.tx
        // if the add new tab was modified but we are not adding a new tab then restore it.
        } else if addNewTabLeadingConstraint?.constant != 0 {
            addNewTabLeadingConstraint?.constant = 0
            addNewTabTrailingConstraint?.constant = 0
            addNewTabView.showHideAddTabIcon(shouldShow: false)
        }
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        regularToolbar.applyTheme(theme: theme)
        if toolbarHelper.isSwipingTabsEnabled {
            leftSkeletonAddressBar.applyTheme(theme: theme)
            rightSkeletonAddressBar.applyTheme(theme: theme)
            addNewTabView.applyTheme(theme: theme)
        }
        applyProgressBarTheme(isPrivateMode: model?.isPrivateMode ?? false, theme: theme)

        guard #available(iOS 26.0, *) else { return }
        accessoryViewGradient.colors = [
            theme.colors.layer3.withAlphaComponent(0).cgColor,
            theme.colors.layer3.cgColor
        ]
    }

    // MARK: - GestureRecognizer
    @objc
    private func onContainerTapped() {
        onContainerTap?()
    }

    // MARK: - AddressToolbarDelegate
    func searchSuggestions(searchTerm: String) {
        if let windowUUID,
           let toolbarState = store.state.screenState(ToolbarState.self, for: .toolbar, window: windowUUID) {
            if searchTerm.isEmpty, !toolbarState.addressToolbar.isEmptySearch {
                let action = ToolbarAction(windowUUID: windowUUID, actionType: ToolbarActionType.didDeleteSearchTerm)
                store.dispatch(action)
            } else if !searchTerm.isEmpty, toolbarState.addressToolbar.isEmptySearch {
                let action = ToolbarAction(windowUUID: windowUUID, actionType: ToolbarActionType.didEnterSearchTerm)
                store.dispatch(action)
            } else if !toolbarState.addressToolbar.didStartTyping {
                let action = ToolbarAction(windowUUID: windowUUID, actionType: ToolbarActionType.didStartTyping)
                store.dispatch(action)
            }
        }
        self.searchTerm = searchTerm
        delegate?.searchSuggestions(searchTerm: searchTerm)
    }

    func didClearSearch() {
        searchTerm = ""
        delegate?.searchSuggestions(searchTerm: "")

        guard let windowUUID else { return }

        let action = ToolbarMiddlewareAction(windowUUID: windowUUID,
                                             actionType: ToolbarMiddlewareActionType.didClearSearch)
        store.dispatch(action)
    }

    func openBrowser(searchTerm: String) {
        delegate?.openBrowser(searchTerm: searchTerm)
    }

    func addressToolbarDidTapSearchEngine(_ searchEngineView: UIView) {
        delegate?.addressToolbarDidTapSearchEngine(searchEngineView)
    }

    func addressToolbarDidBeginEditing(searchTerm: String, shouldShowSuggestions: Bool) {
        let locationText = shouldShowSuggestions ? searchTerm : nil
        enterOverlayMode(locationText, pasted: false, search: false)

        // We want to show suggestions if we turn on the trending searches or recent searches
        // which displays the zero search state. Only if not in private mode.
        let isTrendingSearchEnabled = featureFlags.isFeatureEnabled(.trendingSearches, checking: .buildOnly)
        let isRecentSearchEnabled = featureFlags.isFeatureEnabled(.recentSearches, checking: .buildOnly)
        let isRecentOrTrendingSearchEnabled = isTrendingSearchEnabled || isRecentSearchEnabled
        let isPrivateMode = model?.isPrivateMode ?? false
        let isZeroSearchEnabled = isRecentOrTrendingSearchEnabled && !isPrivateMode

        if shouldShowSuggestions || isZeroSearchEnabled {
            delegate?.openSuggestions(searchTerm: locationText ?? "")
        }
    }

    func addressToolbarAccessibilityActions() -> [UIAccessibilityCustomAction]? {
        delegate?.addressToolbarContainerAccessibilityActions()
    }

    func configureContextualHint(
        _ addressToolbar: BrowserAddressToolbar,
        for button: UIButton,
        with contextualHintType: String
    ) {
        guard addressToolbar == toolbar,
              let toolbarState = store.state.screenState(ToolbarState.self, for: .toolbar, window: windowUUID)
        else { return }

        if contextualHintType == ContextualHintType.navigation.rawValue && !toolbarState.canShowNavigationHint { return }

        delegate?.configureContextualHint(for: button, with: contextualHintType)
    }

    func addressToolbarDidProvideItemsForDragInteraction() {
        guard let windowUUID else { return }

        let action = ToolbarMiddlewareAction(windowUUID: windowUUID,
                                             actionType: ToolbarMiddlewareActionType.didStartDragInteraction)
        store.dispatch(action)
    }

    func addressToolbarDidBeginDragInteraction() {
        delegate?.addressToolbarDidBeginDragInteraction()
    }

    func addressToolbarNeedsSearchReset() {
        delegate?.searchSuggestions(searchTerm: "")
    }

    // MARK: - Autocompletable
    func setAutocompleteSuggestion(_ suggestion: String?) {
        toolbar.setAutocompleteSuggestion(suggestion)
    }

    // MARK: - Overlay Mode
    func enterOverlayMode(_ locationText: String?, pasted: Bool, search: Bool) {
        guard let windowUUID else { return }
        inOverlayMode = true
        delegate?.addressToolbarDidEnterOverlayMode(self)

        if pasted {
            let action = ToolbarAction(
                searchTerm: locationText,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.didPasteSearchTerm
            )
            store.dispatch(action)

            delegate?.openSuggestions(searchTerm: locationText ?? "")
        } else {
            let action = ToolbarAction(searchTerm: locationText,
                                       shouldAnimate: true,
                                       windowUUID: windowUUID,
                                       actionType: ToolbarActionType.didStartEditingUrl)
            store.dispatch(action)
        }
    }

    func leaveOverlayMode(reason: URLBarLeaveOverlayModeReason, shouldCancelLoading cancel: Bool) {
        guard let windowUUID,
              let toolbarState = store.state.screenState(ToolbarState.self, for: .toolbar, window: windowUUID)
        else { return }

        _ = toolbar.resignFirstResponder()
        inOverlayMode = false
        delegate?.addressToolbar(self, didLeaveOverlayModeForReason: reason)

        if toolbarState.addressToolbar.isEditing {
            let action = ToolbarAction(windowUUID: windowUUID, actionType: ToolbarActionType.cancelEdit)
            store.dispatch(action)
        }
    }

    private func applyProgressBarTheme(isPrivateMode: Bool, theme: Theme) {
        let gradientStartColor = isPrivateMode ? theme.colors.borderAccentPrivate : theme.colors.borderAccent
        let gradientMiddleColor = isPrivateMode ? nil : theme.colors.iconAccentPink
        let gradientEndColor = isPrivateMode ? theme.colors.borderAccentPrivate : theme.colors.iconAccentYellow

        progressBar.setGradientColors(
            startColor: gradientStartColor,
            middleColor: gradientMiddleColor,
            endColor: gradientEndColor
        )
    }

    // MARK: - PrivateModeUI
    func applyUIMode(isPrivate: Bool, theme: Theme) {
        applyProgressBarTheme(isPrivateMode: isPrivate, theme: theme)
    }
}
