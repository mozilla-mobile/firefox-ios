// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit

class ToolbarMiddleware: FeatureFlaggable {
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

    private func resolveGeneralBrowserMiddlewareActions(action: GeneralBrowserMiddlewareAction, state: AppState) {
        let uuid = action.windowUUID

        switch action.actionType {
        case GeneralBrowserMiddlewareActionType.browserDidLoad:
            guard let toolbarPosition = action.toolbarPosition else { return }

            let position = addressToolbarPositionFromSearchBarPosition(toolbarPosition)
            let addressToolbarModel = loadInitialAddressToolbarState(toolbarPosition: position)
            let navigationToolbarModel = loadInitialNavigationToolbarState(toolbarPosition: position)

            let action = ToolbarAction(addressToolbarModel: addressToolbarModel,
                                       navigationToolbarModel: navigationToolbarModel,
                                       toolbarPosition: position,
                                       windowUUID: uuid,
                                       actionType: ToolbarActionType.didLoadToolbars)
            store.dispatch(action)

        case GeneralBrowserMiddlewareActionType.didScroll:
            updateBorderPosition(action: action, state: state)

        case GeneralBrowserMiddlewareActionType.toolbarPositionChanged:
            updateToolbarPosition(action: action, state: state)

        default:
            break
        }
    }

    private func resolveToolbarMiddlewareActions(action: ToolbarMiddlewareAction, state: AppState) {
        switch action.actionType {
        case ToolbarMiddlewareActionType.didTapButton:
            resolveToolbarMiddlewareButtonTapActions(action: action, state: state)

        case ToolbarMiddlewareActionType.urlDidChange:
            updateAddressToolbarNavigationActions(action: action, state: state)

        default:
            break
        }
    }

    private func resolveToolbarMiddlewareButtonTapActions(action: ToolbarMiddlewareAction, state: AppState) {
        guard let buttonType = action.buttonType, let gestureType = action.gestureType else { return }

        let uuid = action.windowUUID
        switch gestureType {
        case .tap: handleToolbarButtonTapActions(actionType: buttonType, buttonTapped: action.buttonTapped, windowUUID: uuid)
        case .longPress: handleToolbarButtonLongPressActions(actionType: buttonType, windowUUID: uuid)
        }
    }

    private func loadInitialAddressToolbarState(toolbarPosition: AddressToolbarPosition) -> AddressToolbarModel {
        let borderPosition = getAddressBorderPosition(toolbarPosition: toolbarPosition)

        return AddressToolbarModel(navigationActions: [ToolbarActionState](),
                                   pageActions: loadAddressToolbarPageElements(),
                                   browserActions: loadAddressToolbarBrowserElements(),
                                   borderPosition: borderPosition,
                                   url: nil)
    }

    private func loadAddressToolbarPageElements() -> [ToolbarActionState] {
        var pageActions = [ToolbarActionState]()
        pageActions.append(ToolbarActionState(
            actionType: .qrCode,
            iconName: StandardImageIdentifiers.Large.qrCode,
            isEnabled: true,
            a11yLabel: .QRCode.ToolbarButtonA11yLabel,
            a11yId: AccessibilityIdentifiers.Browser.ToolbarButtons.qrCode))
        return pageActions
    }

    private func loadAddressToolbarBrowserElements() -> [ToolbarActionState] {
        var elements = [ToolbarActionState]()
        elements.append(ToolbarActionState(actionType: .tabs,
                                           iconName: StandardImageIdentifiers.Large.tab,
                                           numberOfTabs: 1,
                                           isEnabled: true,
                                           a11yLabel: .TabsButtonShowTabsAccessibilityLabel,
                                           a11yId: AccessibilityIdentifiers.Toolbar.tabsButton))
        elements.append(ToolbarActionState(actionType: .menu,
                                           iconName: StandardImageIdentifiers.Large.appMenu,
                                           isEnabled: true,
                                           a11yLabel: .AppMenu.Toolbar.MenuButtonAccessibilityLabel,
                                           a11yId: AccessibilityIdentifiers.Toolbar.settingsMenuButton))
        return elements
    }

    private func loadInitialNavigationToolbarState(toolbarPosition: AddressToolbarPosition) -> NavigationToolbarModel {
        let actions = loadNavigationToolbarElements()
        let displayBorder = shouldDisplayNavigationToolbarBorder(toolbarPosition: toolbarPosition)
        return NavigationToolbarModel(actions: actions, displayBorder: displayBorder)
    }

    private func loadNavigationToolbarElements() -> [ToolbarActionState] {
        var elements = [ToolbarActionState]()
        elements.append(ToolbarActionState(actionType: .back,
                                           iconName: StandardImageIdentifiers.Large.back,
                                           isEnabled: false,
                                           a11yLabel: .TabToolbarBackAccessibilityLabel,
                                           a11yId: AccessibilityIdentifiers.Toolbar.backButton))
        elements.append(ToolbarActionState(actionType: .forward,
                                           iconName: StandardImageIdentifiers.Large.forward,
                                           isEnabled: false,
                                           a11yLabel: .TabToolbarForwardAccessibilityLabel,
                                           a11yId: AccessibilityIdentifiers.Toolbar.forwardButton))
        elements.append(ToolbarActionState(actionType: .home,
                                           iconName: StandardImageIdentifiers.Large.home,
                                           isEnabled: true,
                                           a11yLabel: .TabToolbarHomeAccessibilityLabel,
                                           a11yId: AccessibilityIdentifiers.Toolbar.homeButton))
        elements.append(ToolbarActionState(actionType: .tabs,
                                           iconName: StandardImageIdentifiers.Large.tab,
                                           numberOfTabs: 1,
                                           isEnabled: true,
                                           a11yLabel: .TabsButtonShowTabsAccessibilityLabel,
                                           a11yId: AccessibilityIdentifiers.Toolbar.tabsButton))
        elements.append(ToolbarActionState(actionType: .menu,
                                           iconName: StandardImageIdentifiers.Large.appMenu,
                                           isEnabled: true,
                                           a11yLabel: .AppMenu.Toolbar.MenuButtonAccessibilityLabel,
                                           a11yId: AccessibilityIdentifiers.Toolbar.settingsMenuButton))
        return elements
    }

    private func getAddressBorderPosition(toolbarPosition: AddressToolbarPosition,
                                          isPrivate: Bool = false,
                                          scrollY: CGFloat = 0) -> AddressToolbarBorderPosition? {
        return manager.getAddressBorderPosition(for: toolbarPosition, isPrivate: isPrivate, scrollY: scrollY)
    }

    private func shouldDisplayNavigationToolbarBorder(toolbarPosition: AddressToolbarPosition) -> Bool {
        return manager.shouldDisplayNavigationBorder(toolbarPosition: toolbarPosition)
    }

    private func handleToolbarButtonTapActions(actionType: ToolbarActionState.ActionType,
                                               buttonTapped: UIButton?,
                                               windowUUID: WindowUUID) {
        switch actionType {
        case .home:
            let action = GeneralBrowserAction(windowUUID: windowUUID,
                                              actionType: GeneralBrowserActionType.goToHomepage)
            store.dispatch(action)
        case .qrCode:
            let action = GeneralBrowserAction(windowUUID: windowUUID,
                                              actionType: GeneralBrowserActionType.showQRcodeReader)
            store.dispatch(action)

        case .back:
            let action = GeneralBrowserAction(windowUUID: windowUUID,
                                              actionType: GeneralBrowserActionType.navigateBack)
            store.dispatch(action)

        case .forward:
            let action = GeneralBrowserAction(windowUUID: windowUUID,
                                              actionType: GeneralBrowserActionType.navigateForward)
            store.dispatch(action)

        case .tabs:
            let action = GeneralBrowserAction(windowUUID: windowUUID,
                                              actionType: GeneralBrowserActionType.showTabTray)
            store.dispatch(action)

        case .trackingProtection:
            let action = GeneralBrowserAction(windowUUID: windowUUID,
                                              actionType: GeneralBrowserActionType.showTrackingProtectionDetails)
            store.dispatch(action)

        case .menu:
            let action = GeneralBrowserAction(buttonTapped: buttonTapped,
                                              windowUUID: windowUUID,
                                              actionType: GeneralBrowserActionType.showMenu)
            store.dispatch(action)

        default:
            break
        }
    }

    private func handleToolbarButtonLongPressActions(actionType: ToolbarActionState.ActionType,
                                                     windowUUID: WindowUUID) {
        switch actionType {
        case .back, .forward:
            let action = GeneralBrowserAction(windowUUID: windowUUID,
                                              actionType: GeneralBrowserActionType.showBackForwardList)
            store.dispatch(action)
        case .tabs:
            let action = GeneralBrowserAction(windowUUID: windowUUID,
                                              actionType: GeneralBrowserActionType.showTabsLongPressActions)
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

        let addressToolbarState = toolbarState.addressToolbar
        let addressBorderPosition = getAddressBorderPosition(toolbarPosition: toolbarState.toolbarPosition,
                                                             isPrivate: toolbarState.isPrivateMode,
                                                             scrollY: scrollOffset.y)
        let displayNavToolbarBorder = shouldDisplayNavigationToolbarBorder(
            toolbarPosition: toolbarState.toolbarPosition)

        let needsAddressToolbarUpdate = addressToolbarState.borderPosition != addressBorderPosition
        let needsNavToolbarUpdate = toolbarState.navigationToolbar.displayBorder != displayNavToolbarBorder
        guard needsAddressToolbarUpdate || needsNavToolbarUpdate else { return }

        let addressToolbarModel = AddressToolbarModel(borderPosition: addressBorderPosition)
        let navToolbarModel = NavigationToolbarModel(displayBorder: displayNavToolbarBorder)

        let action = ToolbarAction(addressToolbarModel: addressToolbarModel,
                                   navigationToolbarModel: navToolbarModel,
                                   windowUUID: action.windowUUID,
                                   actionType: ToolbarActionType.scrollOffsetChanged)
        store.dispatch(action)
    }

    private func updateToolbarPosition(action: GeneralBrowserMiddlewareAction, state: AppState) {
        guard let toolbarPosition = action.toolbarPosition else { return }

        let position = addressToolbarPositionFromSearchBarPosition(toolbarPosition)
        let toolbarAction = ToolbarAction(toolbarPosition: position,
                                          windowUUID: action.windowUUID,
                                          actionType: ToolbarActionType.toolbarPositionChanged)
        store.dispatch(toolbarAction)

        updateBorderPosition(action: action, state: state)
    }

    private func addressToolbarPositionFromSearchBarPosition(_ position: SearchBarPosition) -> AddressToolbarPosition {
        switch position {
        case .top: return .top
        case .bottom: return .bottom
        }
    }

    // MARK: Address Toolbar Actions

    private func updateAddressToolbarNavigationActions(action: ToolbarMiddlewareAction, state: AppState) {
        guard let traitCollection = action.traitCollection,
              let toolbarState = state.screenState(ToolbarState.self, for: .toolbar, window: action.windowUUID)
        else { return }

        let navToolbarActions = toolbarState.navigationToolbar.actions
        let isBackButtonEnabled = action.canGoBack ?? false
        let isForwardButtonEnabled = action.canGoForward ?? false

        if let url = action.url, !ToolbarHelper().shouldShowNavigationToolbar(for: traitCollection) {
            // Show navigation actions in address toolbar when the navigation toolbar is not shown
            var navigationActions = [ToolbarActionState]()
            navigationActions.append(ToolbarActionState(actionType: .back,
                                                        iconName: StandardImageIdentifiers.Large.back,
                                                        isEnabled: isBackButtonEnabled,
                                                        a11yLabel: .TabToolbarBackAccessibilityLabel,
                                                        a11yId: AccessibilityIdentifiers.Toolbar.backButton))
            navigationActions.append(ToolbarActionState(actionType: .forward,
                                                        iconName: StandardImageIdentifiers.Large.forward,
                                                        isEnabled: isForwardButtonEnabled,
                                                        a11yLabel: .TabToolbarForwardAccessibilityLabel,
                                                        a11yId: AccessibilityIdentifiers.Toolbar.forwardButton))

            let addressToolbarModel = AddressToolbarModel(
                navigationActions: navigationActions,
                pageActions: toolbarState.addressToolbar.pageActions,
                browserActions: toolbarState.addressToolbar.browserActions,
                borderPosition: toolbarState.addressToolbar.borderPosition,
                url: action.url)

            let action = ToolbarAction(addressToolbarModel: addressToolbarModel,
                                       url: url,
                                       windowUUID: action.windowUUID,
                                       actionType: ToolbarActionType.urlDidChange)
            store.dispatch(action)
        } else {
            // Hide navigation actions in address toolbar when navigation toolbar is shown as they are shown there
            let addressToolbarModel = AddressToolbarModel(
                navigationActions: [ToolbarActionState](),
                pageActions: toolbarState.addressToolbar.pageActions,
                browserActions: toolbarState.addressToolbar.browserActions,
                borderPosition: toolbarState.addressToolbar.borderPosition,
                url: action.url)
            let action = ToolbarAction(addressToolbarModel: addressToolbarModel,
                                       url: action.url,
                                       windowUUID: action.windowUUID,
                                       actionType: ToolbarActionType.urlDidChange)
            store.dispatch(action)
        }
    }
}
