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
            let action = ToolbarAction(windowUUID: action.windowUUID, actionType: ToolbarActionType.didStartEditingUrl)
            store.dispatch(action)

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
                                          actionType: ToolbarActionType.borderPositionChanged)
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

    // MARK: - Helper

    private func getAddressBorderPosition(toolbarPosition: AddressToolbarPosition,
                                          isPrivate: Bool = false,
                                          scrollY: CGFloat = 0) -> AddressToolbarBorderPosition? {
        return manager.getAddressBorderPosition(for: toolbarPosition, isPrivate: isPrivate, scrollY: scrollY)
    }

    private func shouldDisplayNavigationToolbarBorder(toolbarPosition: AddressToolbarPosition) -> Bool {
        return manager.shouldDisplayNavigationBorder(toolbarPosition: toolbarPosition)
    }
}
