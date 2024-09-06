// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit

final class ToolbarMiddleware: FeatureFlaggable {
    private let profile: Profile
    private let manager: ToolbarManager
    private let logger: Logger

    init(profile: Profile = AppContainer.shared.resolve(),
         manager: ToolbarManager = DefaultToolbarManager(),
         logger: Logger = DefaultLogger.shared) {
        self.profile = profile
        self.manager = manager
        self.logger = logger
    }

    lazy var toolbarProvider: Middleware<AppState> = { state, action in
        if let action = action as? GeneralBrowserMiddlewareAction {
            self.resolveGeneralBrowserMiddlewareActions(action: action, state: state)
        } else if let action = action as? ToolbarMiddlewareAction {
            self.resolveToolbarMiddlewareActions(action: action, state: state)
        }
    }

    lazy var stopLoadingAction = ToolbarActionState(
        actionType: .stopLoading,
        iconName: StandardImageIdentifiers.Large.cross,
        isEnabled: true,
        a11yLabel: .TabToolbarStopAccessibilityLabel,
        a11yId: AccessibilityIdentifiers.Toolbar.stopButton)

    lazy var reloadAction = ToolbarActionState(
        actionType: .reload,
        iconName: StandardImageIdentifiers.Large.arrowClockwise,
        isEnabled: true,
        a11yLabel: .TabLocationReloadAccessibilityLabel,
        a11yHint: .TabLocationReloadAccessibilityHint,
        a11yId: AccessibilityIdentifiers.Toolbar.reloadButton)

    private lazy var readerModeAction = ToolbarActionState(
        actionType: .readerMode,
        iconName: StandardImageIdentifiers.Large.readerView,
        isEnabled: true,
        a11yLabel: .TabLocationReaderModeAccessibilityLabel,
        a11yHint: .TabLocationReloadAccessibilityHint,
        a11yId: AccessibilityIdentifiers.Toolbar.readerModeButton,
        a11yCustomActionName: .TabLocationReaderModeAddToReadingListAccessibilityLabel)

    lazy var qrCodeScanAction = ToolbarActionState(
        actionType: .qrCode,
        iconName: StandardImageIdentifiers.Large.qrCode,
        isEnabled: true,
        a11yLabel: .QRCode.ToolbarButtonA11yLabel,
        a11yId: AccessibilityIdentifiers.Browser.ToolbarButtons.qrCode)

    lazy var cancelEditAction = ToolbarActionState(
        actionType: .cancelEdit,
        iconName: StandardImageIdentifiers.Large.chevronLeft,
        isFlippedForRTL: true,
        isEnabled: true,
        a11yLabel: AccessibilityIdentifiers.GeneralizedIdentifiers.back,
        a11yId: AccessibilityIdentifiers.Browser.UrlBar.cancelButton)

    lazy var homeAction = ToolbarActionState(
        actionType: .home,
        iconName: StandardImageIdentifiers.Large.home,
        isEnabled: true,
        a11yLabel: .TabToolbarHomeAccessibilityLabel,
        a11yId: AccessibilityIdentifiers.Toolbar.homeButton)

    lazy var newTabAction = ToolbarActionState(
        actionType: .newTab,
        iconName: StandardImageIdentifiers.Large.plus,
        isEnabled: true,
        a11yLabel: .Toolbars.NewTabButton,
        a11yId: AccessibilityIdentifiers.Toolbar.addNewTabButton)

    lazy var shareAction = ToolbarActionState(
        actionType: .share,
        iconName: StandardImageIdentifiers.Large.share,
        isEnabled: true,
        a11yLabel: .TabLocationShareAccessibilityLabel,
        a11yId: AccessibilityIdentifiers.Toolbar.shareButton)

    lazy var searchAction = ToolbarActionState(
        actionType: .search,
        iconName: StandardImageIdentifiers.Large.search,
        isEnabled: true,
        a11yLabel: .TabToolbarSearchAccessibilityLabel,
        a11yId: AccessibilityIdentifiers.Toolbar.searchButton)

    lazy var dataClearanceAction = ToolbarActionState(
        actionType: .dataClearance,
        iconName: StandardImageIdentifiers.Large.dataClearance,
        isEnabled: true,
        hasContextualHint: true,
        a11yLabel: .TabToolbarDataClearanceAccessibilityLabel,
        a11yId: AccessibilityIdentifiers.Toolbar.fireButton)

    private func resolveGeneralBrowserMiddlewareActions(action: GeneralBrowserMiddlewareAction, state: AppState) {
        let uuid = action.windowUUID

        switch action.actionType {
        case GeneralBrowserMiddlewareActionType.browserDidLoad:
            guard let toolbarPosition = action.toolbarPosition else { return }

            let position = addressToolbarPositionFromSearchBarPosition(toolbarPosition)
            let borderPosition = getAddressBorderPosition(toolbarPosition: position)
            let displayBorder = shouldDisplayNavigationToolbarBorder(toolbarPosition: position)

            let action = ToolbarAction(toolbarPosition: toolbarPosition,
                                       addressBorderPosition: borderPosition,
                                       displayNavBorder: displayBorder,
                                       windowUUID: uuid,
                                       actionType: ToolbarActionType.didLoadToolbars)
            store.dispatch(action)

        case GeneralBrowserMiddlewareActionType.websiteDidScroll:
            updateBorderPosition(action: action, state: state)

        case GeneralBrowserMiddlewareActionType.toolbarPositionChanged:
            updateToolbarPosition(action: action, state: state)

        default:
            break
        }
    }

    private func resolveToolbarMiddlewareActions(action: ToolbarMiddlewareAction, state: AppState) {
        switch action.actionType {
        case ToolbarMiddlewareActionType.customA11yAction:
            resolveToolbarMiddlewareCustomA11yActions(action: action, state: state)

        case ToolbarMiddlewareActionType.didTapButton:
            resolveToolbarMiddlewareButtonTapActions(action: action, state: state)

        default:
            break
        }
    }

    private func resolveToolbarMiddlewareButtonTapActions(action: ToolbarMiddlewareAction, state: AppState) {
        guard let gestureType = action.gestureType else { return }

        switch gestureType {
        case .tap:
            handleToolbarButtonTapActions(action: action, state: state)
        case .longPress:
            handleToolbarButtonLongPressActions(action: action)
        }
    }

    func resolveToolbarMiddlewareCustomA11yActions(action: ToolbarMiddlewareAction, state: AppState) {
        switch action.buttonType {
        case .readerMode:
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.addToReadingListLongPressAction)
            store.dispatch(action)
        default: break
        }
    }

    private func handleToolbarButtonTapActions(action: ToolbarMiddlewareAction, state: AppState) {
        switch action.buttonType {
        case .home:
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.goToHomepage)
            store.dispatch(action)
        case .newTab:
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.addNewTab)
            store.dispatch(action)
        case .qrCode:
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.showQRcodeReader)
            store.dispatch(action)

        case .back:
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.navigateBack)
            store.dispatch(action)

        case .forward:
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.navigateForward)
            store.dispatch(action)

        case .tabs:
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.showTabTray)
            store.dispatch(action)

        case .trackingProtection:
            let action = GeneralBrowserAction(buttonTapped: action.buttonTapped,
                                              windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.showTrackingProtectionDetails)
            store.dispatch(action)

        case .menu:
            let action = GeneralBrowserAction(buttonTapped: action.buttonTapped,
                                              windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.showMenu)
            store.dispatch(action)

        case .cancelEdit:
            let action = ToolbarAction(windowUUID: action.windowUUID, actionType: ToolbarActionType.cancelEdit)
            store.dispatch(action)

        case .readerMode:
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.showReaderMode)
            store.dispatch(action)

        case .reload:
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.reloadWebsite)
            store.dispatch(action)

        case .stopLoading:
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.stopLoadingWebsite)
            store.dispatch(action)

        case .share:
            let action = GeneralBrowserAction(buttonTapped: action.buttonTapped,
                                              windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.showShare)
            store.dispatch(action)

        case .search:
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .startSearchButton)
            updateAddressToolbarNavigationActions(action: action, state: state, isEditing: true)

        case .dataClearance:
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.clearData)
            store.dispatch(action)
        default:
            break
        }
    }

    private func handleToolbarButtonLongPressActions(action: ToolbarMiddlewareAction) {
        switch action.buttonType {
        case .back, .forward:
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.showBackForwardList)
            store.dispatch(action)
        case .tabs:
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.showTabsLongPressActions)
            store.dispatch(action)
        case .locationView:
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.showLocationViewLongPressActionSheet)
            store.dispatch(action)
        case .reload:
            let action = GeneralBrowserAction(buttonTapped: action.buttonTapped,
                                              windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.showReloadLongPressAction)
            store.dispatch(action)
        case .newTab:
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.showNewTabLongPressActions)
            store.dispatch(action)
        case .readerMode:
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.addToReadingListLongPressAction)
            store.dispatch(action)
        default:
            break
        }
    }

    private func updateBorderPosition(action: GeneralBrowserMiddlewareAction, state: AppState) {
        guard let scrollOffset = action.scrollOffset,
              let toolbarState = state.screenState(ToolbarState.self,
                                                   for: .toolbar,
                                                   window: action.windowUUID)
        else { return }

        let addressBorderPosition = getAddressBorderPosition(toolbarPosition: toolbarState.toolbarPosition,
                                                             isPrivate: toolbarState.isPrivateMode,
                                                             scrollY: scrollOffset.y)
        let displayNavToolbarBorder = shouldDisplayNavigationToolbarBorder(
            toolbarPosition: toolbarState.toolbarPosition)

        let needsAddressToolbarUpdate = toolbarState.addressToolbar.borderPosition != addressBorderPosition
        let needsNavToolbarUpdate = toolbarState.navigationToolbar.displayBorder != displayNavToolbarBorder
        guard needsAddressToolbarUpdate || needsNavToolbarUpdate else { return }

        let toolbarAction = ToolbarAction(addressBorderPosition: addressBorderPosition,
                                          displayNavBorder: displayNavToolbarBorder,
                                          windowUUID: action.windowUUID,
                                          actionType: ToolbarActionType.didLoadToolbars)
        store.dispatch(toolbarAction)
    }

    private func updateToolbarPosition(action: GeneralBrowserMiddlewareAction, state: AppState) {
        guard let toolbarPosition = action.toolbarPosition,
              let scrollOffset = action.scrollOffset,
              let toolbarState = state.screenState(ToolbarState.self,
                                                   for: .toolbar,
                                                   window: action.windowUUID)
        else { return }

        let position = addressToolbarPositionFromSearchBarPosition(toolbarPosition)
        let addressBorderPosition = getAddressBorderPosition(toolbarPosition: position,
                                                             isPrivate: toolbarState.isPrivateMode,
                                                             scrollY: scrollOffset.y)
        let displayNavToolbarBorder = shouldDisplayNavigationToolbarBorder(toolbarPosition: position)

        let toolbarAction = ToolbarAction(addressBorderPosition: addressBorderPosition,
                                          displayNavBorder: displayNavToolbarBorder,
                                          windowUUID: action.windowUUID,
                                          actionType: ToolbarActionType.toolbarPositionChanged)
        store.dispatch(toolbarAction)
    }

    private func addressToolbarPositionFromSearchBarPosition(_ position: SearchBarPosition) -> AddressToolbarPosition {
        switch position {
        case .top: return .top
        case .bottom: return .bottom
        }
    }

    // MARK: Address Toolbar Actions

    private func addressToolbarBrowserActions(
        action: ToolbarMiddlewareAction,
        state: AppState
    ) -> [ToolbarActionState] {
        var actions = [ToolbarActionState]()

        guard let toolbarState = state.screenState(ToolbarState.self,
                                                   for: .toolbar,
                                                   window: action.windowUUID)
        else { return actions }

        if !(action.isShowingTopTabs ?? toolbarState.isShowingTopTabs) {
            actions.append(newTabAction)
        }

        let numberOfTabs = action.numberOfTabs ?? toolbarState.numberOfTabs
        let isShowMenuWarningAction = action.actionType as? ToolbarActionType == .showMenuWarningBadge
        let menuBadgeImageName = isShowMenuWarningAction ? action.badgeImageName : toolbarState.badgeImageName
        let maskImageName = isShowMenuWarningAction ? action.maskImageName : toolbarState.maskImageName

        actions.append(contentsOf: [
            tabsAction(numberOfTabs: numberOfTabs, isPrivateMode: toolbarState.isPrivateMode),
            menuAction(badgeImageName: menuBadgeImageName, maskImageName: maskImageName)])

        return actions
    }

    private func addressToolbarNavigationActions(
        action: ToolbarMiddlewareAction,
        state: AppState,
        isEditing: Bool = false
    ) -> [ToolbarActionState] {
        var actions = [ToolbarActionState]()

        guard let toolbarState = state.screenState(ToolbarState.self,
                                                   for: .toolbar,
                                                   window: action.windowUUID)
        else { return actions }

        let isUrlChangeAction = action.actionType as? ToolbarMiddlewareActionType == .urlDidChange
        let url = isUrlChangeAction ? action.url : toolbarState.addressToolbar.url
        let isShowingNavToolbar = action.isShowingNavigationToolbar ?? toolbarState.isShowingNavigationToolbar
        let canGoBack = action.canGoBack ?? toolbarState.canGoBack
        let canGoForward = action.canGoForward ?? toolbarState.canGoForward

        if isEditing {
            // back carrot when in edit mode
            actions.append(cancelEditAction)
        } else if isShowingNavToolbar || url == nil {
            // there are no navigation actions if on homepage or when nav toolbar is shown
            return actions
        } else if url != nil {
            // back/forward when url exists and nav toolbar is not shown
            let isBackButtonEnabled = canGoBack
            let isForwardButtonEnabled = canGoForward
            actions.append(backAction(enabled: isBackButtonEnabled))
            actions.append(forwardAction(enabled: isForwardButtonEnabled))
            if canShowDataClearanceAction(isPrivate: toolbarState.isPrivateMode) {
                actions.append(dataClearanceAction)
            }
        }

        return actions
    }

    private func addressToolbarPageActions(
        action: ToolbarMiddlewareAction,
        toolbarState: borrowing ToolbarState,
        isEditing: Bool
    ) -> [ToolbarActionState] {
        var actions = [ToolbarActionState]()

        let isUrlChangeAction = action.actionType as? ToolbarMiddlewareActionType == .urlDidChange
        let isReaderModeAction = action.actionType as? ToolbarMiddlewareActionType == .readerModeStateChanged
        let readerModeState = isReaderModeAction ? action.readerModeState : toolbarState.addressToolbar.readerModeState
        let url = (isUrlChangeAction || isReaderModeAction) ? action.url : toolbarState.addressToolbar.url
        readerModeAction.shouldDisplayAsHighlighted = readerModeState == .active

        guard url != nil, !isEditing else {
            // On homepage we only show the QR code button
            return [qrCodeScanAction]
        }

        switch readerModeState {
        case .active, .available:
            actions.append(readerModeAction)
        default: break
        }

        actions.append(shareAction)

        let isLoadingChangeAction = action.actionType as? ToolbarActionType == .websiteLoadingStateDidChange
        let isLoading = isLoadingChangeAction ? action.isLoading : toolbarState.addressToolbar.isLoading

        if isLoading == true {
            actions.append(stopLoadingAction)
        } else if isLoading == false {
            actions.append(reloadAction)
        }

        return actions
    }

    private func updateAddressToolbarNavigationActions(
        action: ToolbarMiddlewareAction,
        state: AppState,
        isEditing: Bool? = nil,
        dispatchActionType: ToolbarActionType = ToolbarActionType.addressToolbarActionsDidChange) {
        guard let toolbarState = state.screenState(ToolbarState.self, for: .toolbar, window: action.windowUUID),
              let addressToolbarModel = generateAddressToolbarActions(action: action,
                                                                      state: state,
                                                                      isEditing: isEditing)
        else { return }

        let toolbarAction = ToolbarAction(addressToolbarModel: addressToolbarModel,
                                          searchTerm: action.searchTerm ?? toolbarState.addressToolbar.searchTerm,
                                          isShowingTopTabs: action.isShowingTopTabs ?? toolbarState.isShowingTopTabs,
                                          windowUUID: action.windowUUID,
                                          actionType: dispatchActionType)
        store.dispatch(toolbarAction)
    }

    private func generateAddressToolbarActions(
        action: ToolbarMiddlewareAction,
        state: AppState,
        lockIconImageName: String? = nil,
        isEditing: Bool? = nil)
    -> AddressToolbarModel? {
        guard let toolbarState = state.screenState(ToolbarState.self, for: .toolbar, window: action.windowUUID)
        else { return nil }

        let editing = isEditing ?? toolbarState.addressToolbar.isEditing
        let navigationActions = addressToolbarNavigationActions(
            action: action,
            state: state,
            isEditing: editing)
        let pageActions = addressToolbarPageActions(action: action, toolbarState: toolbarState, isEditing: editing)
        let browserActions = addressToolbarBrowserActions(action: action, state: state)
        let isUrlChangeAction = action.actionType as? ToolbarMiddlewareActionType == .urlDidChange
        let isReaderModeAction = action.actionType as? ToolbarMiddlewareActionType == .readerModeStateChanged
        let url = (isUrlChangeAction || isReaderModeAction) ? action.url : toolbarState.addressToolbar.url

        let addressToolbarModel = AddressToolbarModel(
            navigationActions: navigationActions,
            pageActions: pageActions,
            browserActions: browserActions,
            borderPosition: toolbarState.addressToolbar.borderPosition,
            url: url,
            lockIconImageName: lockIconImageName,
            isEditing: isEditing)
        return addressToolbarModel
    }

    // MARK: - Navigation Toolbar

    private func generateNavigationToolbarActions(
        action: ToolbarMiddlewareAction,
        state: AppState,
        isEditing: Bool? = nil)
    -> NavigationToolbarModel? {
        guard let toolbarState = state.screenState(ToolbarState.self, for: .toolbar, window: action.windowUUID)
        else { return nil }

        let isUrlChangeAction = action.actionType as? ToolbarMiddlewareActionType == .urlDidChange
        let url = isUrlChangeAction ? action.url : toolbarState.addressToolbar.url

        let middleAction = getMiddleButtonAction(url: url, isPrivateMode: toolbarState.isPrivateMode)

        let canGoBack = action.canGoBack ?? toolbarState.canGoBack
        let canGoForward = action.canGoForward ?? toolbarState.canGoForward
        let numberOfTabs = action.numberOfTabs ?? toolbarState.numberOfTabs

        let isShowMenuWarningAction = action.actionType as? ToolbarActionType == .showMenuWarningBadge
        let menuBadgeImageName = isShowMenuWarningAction ? action.badgeImageName : toolbarState.badgeImageName
        let maskImageName = isShowMenuWarningAction ? action.maskImageName : toolbarState.maskImageName

        let actions = [
            backAction(enabled: canGoBack),
            forwardAction(enabled: canGoForward),
            middleAction,
            tabsAction(numberOfTabs: numberOfTabs, isPrivateMode: toolbarState.isPrivateMode),
            menuAction(badgeImageName: menuBadgeImageName, maskImageName: maskImageName)
        ]

        let displayBorder = shouldDisplayNavigationToolbarBorder(toolbarPosition: toolbarState.toolbarPosition)

        let navToolbarModel = NavigationToolbarModel(
            actions: actions,
            displayBorder: displayBorder)
        return navToolbarModel
    }

    private func getMiddleButtonAction(url: URL?, isPrivateMode: Bool) -> ToolbarActionState {
        let canShowDataClearanceAction = canShowDataClearanceAction(isPrivate: isPrivateMode)
        let isNewTabEnabled = featureFlags.isFeatureEnabled(.toolbarOneTapNewTab, checking: .buildOnly)
        let middleActionForWebpage = canShowDataClearanceAction ?
                                     dataClearanceAction : isNewTabEnabled ? newTabAction : homeAction
        let middleActionForHomepage = searchAction
        let middleAction = url == nil ? middleActionForHomepage : middleActionForWebpage

        return middleAction
    }

    // MARK: - Helper

    private func backAction(enabled: Bool) -> ToolbarActionState {
        return ToolbarActionState(
            actionType: .back,
            iconName: StandardImageIdentifiers.Large.back,
            isFlippedForRTL: true,
            isEnabled: enabled,
            a11yLabel: .TabToolbarBackAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.backButton)
    }

    private func forwardAction(enabled: Bool) -> ToolbarActionState {
        return ToolbarActionState(
            actionType: .forward,
            iconName: StandardImageIdentifiers.Large.forward,
            isFlippedForRTL: true,
            isEnabled: enabled,
            a11yLabel: .TabToolbarForwardAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.forwardButton)
    }

    private func tabsAction(numberOfTabs: Int = 1,
                            isPrivateMode: Bool = false) -> ToolbarActionState {
        return ToolbarActionState(
            actionType: .tabs,
            iconName: StandardImageIdentifiers.Large.tab,
            badgeImageName: isPrivateMode ? StandardImageIdentifiers.Medium.privateModeCircleFillPurple : nil,
            maskImageName: isPrivateMode ? ImageIdentifiers.badgeMask : nil,
            numberOfTabs: numberOfTabs,
            isEnabled: true,
            a11yLabel: .TabsButtonShowTabsAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.tabsButton)
    }

    private func menuAction(badgeImageName: String? = nil, maskImageName: String? = nil) -> ToolbarActionState {
        return ToolbarActionState(
            actionType: .menu,
            iconName: StandardImageIdentifiers.Large.appMenu,
            badgeImageName: badgeImageName,
            maskImageName: maskImageName,
            isEnabled: true,
            a11yLabel: .LegacyAppMenu.Toolbar.MenuButtonAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.settingsMenuButton)
    }

    private func getAddressBorderPosition(toolbarPosition: AddressToolbarPosition,
                                          isPrivate: Bool = false,
                                          scrollY: CGFloat = 0) -> AddressToolbarBorderPosition? {
        return manager.getAddressBorderPosition(for: toolbarPosition, isPrivate: isPrivate, scrollY: scrollY)
    }

    private func shouldDisplayNavigationToolbarBorder(toolbarPosition: AddressToolbarPosition) -> Bool {
        return manager.shouldDisplayNavigationBorder(toolbarPosition: toolbarPosition)
    }

    private func canShowDataClearanceAction(isPrivate: Bool) -> Bool {
        let isFeltPrivacyUIEnabled = featureFlags.isFeatureEnabled(.feltPrivacySimplifiedUI, checking: .buildOnly)
        let isFeltPrivacyDeletionEnabled = featureFlags.isFeatureEnabled(.feltPrivacyFeltDeletion, checking: .buildOnly)

        return isPrivate && isFeltPrivacyUIEnabled && isFeltPrivacyDeletionEnabled
    }
}
