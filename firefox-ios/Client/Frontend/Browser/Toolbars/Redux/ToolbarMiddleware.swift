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
        } else if let action = action as? MicrosurveyPromptMiddlewareAction {
            self.resolveMicrosurveyActions(windowUUID: action.windowUUID, actionType: action.actionType, state: state)
        } else if let action = action as? MicrosurveyPromptAction {
            self.resolveMicrosurveyActions(windowUUID: action.windowUUID, actionType: action.actionType, state: state)
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
            let borderPosition = getAddressBorderPosition(toolbarPosition: position)
            let displayBorder = shouldDisplayNavigationToolbarBorder(toolbarPosition: position)

            let action = ToolbarAction(
                toolbarPosition: toolbarPosition,
                addressBorderPosition: borderPosition,
                displayNavBorder: displayBorder,
                isNewTabFeatureEnabled: featureFlags.isFeatureEnabled(.toolbarOneTapNewTab, checking: .buildOnly),
                canShowDataClearanceAction: canShowDataClearanceAction(),
                windowUUID: uuid,
                actionType: ToolbarActionType.didLoadToolbars)
            store.dispatch(action)

        case GeneralBrowserMiddlewareActionType.websiteDidScroll:
            updateTopAddressBorderPosition(action: action, state: state)

        case GeneralBrowserMiddlewareActionType.toolbarPositionChanged:
            updateToolbarPosition(action: action, state: state)

        default:
            break
        }
    }

    private func resolveMicrosurveyActions(windowUUID: WindowUUID, actionType: ActionType, state: AppState) {
        switch actionType {
        case MicrosurveyPromptMiddlewareActionType.initialize:
            updateToolbarBorders(windowUUID: windowUUID, state: state, isMicrosurveyShown: true)
        case MicrosurveyPromptActionType.closePrompt:
            updateToolbarBorders(windowUUID: windowUUID, state: state, isMicrosurveyShown: false)
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

    // MARK: - Border
    private func updateTopAddressBorderPosition(action: GeneralBrowserMiddlewareAction, state: AppState) {
        guard let scrollOffset = action.scrollOffset,
              let toolbarState = state.screenState(ToolbarState.self,
                                                   for: .toolbar,
                                                   window: action.windowUUID),
              toolbarState.toolbarPosition == .top
        else { return }

        let addressBorderPosition = getAddressBorderPosition(
            toolbarPosition: toolbarState.toolbarPosition,
            isPrivate: toolbarState.isPrivateMode,
            scrollY: scrollOffset.y
        )

        let needsAddressToolbarUpdate = toolbarState.addressToolbar.borderPosition != addressBorderPosition

        guard needsAddressToolbarUpdate else { return }

        let toolbarAction = ToolbarAction(
            addressBorderPosition: addressBorderPosition,
            windowUUID: action.windowUUID,
            actionType: ToolbarActionType.borderPositionChanged
        )
        store.dispatch(toolbarAction)
    }

    private func isMicrosurveyShown(action: GeneralBrowserMiddlewareAction, state: AppState) -> Bool {
        let bvcState = state.screenState(BrowserViewControllerState.self, for: .browserViewController, window: action.windowUUID)
        return bvcState?.microsurveyState.showPrompt ?? false
    }

    // Update border to hide for bottom toolbars when microsurvey is shown,
    // so that it appears to belong to the app and harder to spoof
    private func updateToolbarBorders(windowUUID: WindowUUID, state: AppState, isMicrosurveyShown: Bool) {
        guard let toolbarState = state.screenState(ToolbarState.self,
                                                   for: .toolbar,
                                                   window: windowUUID) else { return }

        if toolbarState.toolbarPosition == .top {
            let toolbarAction = ToolbarAction(displayNavBorder: !isMicrosurveyShown,
                                              windowUUID: windowUUID,
                                              actionType: ToolbarActionType.borderPositionChanged)
            store.dispatch(toolbarAction)
        } else {
            let toolbarAction = ToolbarAction(addressBorderPosition: isMicrosurveyShown ? .none : .top,
                                              displayNavBorder: false,
                                              windowUUID: windowUUID,
                                              actionType: ToolbarActionType.borderPositionChanged)
            store.dispatch(toolbarAction)
        }
    }

    private func updateToolbarPosition(action: GeneralBrowserMiddlewareAction, state: AppState) {
        guard let searchBarPosition = action.toolbarPosition,
              let scrollOffset = action.scrollOffset,
              let toolbarState = state.screenState(ToolbarState.self,
                                                   for: .toolbar,
                                                   window: action.windowUUID)
        else { return }

        let addressToolbarPosition = addressToolbarPositionFromSearchBarPosition(searchBarPosition)
        var addressBorderPosition = getAddressBorderPosition(toolbarPosition: addressToolbarPosition,
                                                             isPrivate: toolbarState.isPrivateMode,
                                                             scrollY: scrollOffset.y)
        var displayNavToolbarBorder = shouldDisplayNavigationToolbarBorder(toolbarPosition: addressToolbarPosition)

        if isMicrosurveyShown(action: action, state: state) {
            displayNavToolbarBorder = false
            let isAddressToolbarOnBottom = addressToolbarPosition == .bottom
            addressBorderPosition = isAddressToolbarOnBottom ? .none : addressBorderPosition
        }

        let toolbarAction = ToolbarAction(toolbarPosition: searchBarPosition,
                                          addressBorderPosition: addressBorderPosition,
                                          displayNavBorder: displayNavToolbarBorder,
                                          windowUUID: action.windowUUID,
                                          actionType: ToolbarActionType.toolbarPositionChanged)
        store.dispatch(toolbarAction)
    }

    // MARK: - Helper

    private func addressToolbarPositionFromSearchBarPosition(_ position: SearchBarPosition) -> AddressToolbarPosition {
        switch position {
        case .top: return .top
        case .bottom: return .bottom
        }
    }

    private func getAddressBorderPosition(toolbarPosition: AddressToolbarPosition,
                                          isPrivate: Bool = false,
                                          scrollY: CGFloat = 0) -> AddressToolbarBorderPosition {
        return manager.getAddressBorderPosition(for: toolbarPosition, isPrivate: isPrivate, scrollY: scrollY)
    }

    private func shouldDisplayNavigationToolbarBorder(toolbarPosition: AddressToolbarPosition) -> Bool {
        return manager.shouldDisplayNavigationBorder(toolbarPosition: toolbarPosition)
    }

    private func canShowDataClearanceAction() -> Bool {
        let isFeltPrivacyUIEnabled = featureFlags.isFeatureEnabled(.feltPrivacySimplifiedUI, checking: .buildOnly)
        let isFeltPrivacyDeletionEnabled = featureFlags.isFeatureEnabled(.feltPrivacyFeltDeletion, checking: .buildOnly)

        return isFeltPrivacyUIEnabled && isFeltPrivacyDeletionEnabled
    }
}
