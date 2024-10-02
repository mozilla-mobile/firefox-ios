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
            guard let scrollOffset = action.scrollOffset else { return }
            updateTopAddressBorderPosition(scrollOffset: scrollOffset, windowUUID: action.windowUUID, state: state)

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

        case ToolbarMiddlewareActionType.urlDidChange:
            guard let scrollOffset = action.scrollOffset else { return }
            updateTopAddressBorderPosition(scrollOffset: scrollOffset, windowUUID: action.windowUUID, state: state)

        case ToolbarMiddlewareActionType.didClearSearch:
            recordTelemetry(event: .toolbarClearSearchTap, state: state, windowUUID: action.windowUUID)

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
            handleToolbarButtonLongPressActions(action: action, state: state)
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
            recordTelemetry(event: .toolbarHomeButtonTap, state: state, windowUUID: action.windowUUID)
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.goToHomepage)
            store.dispatch(action)
        case .newTab:
            recordTelemetry(event: .toolbarOneTapNewTab, state: state, windowUUID: action.windowUUID)
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.addNewTab)
            store.dispatch(action)
        case .qrCode:
            recordTelemetry(event: .toolbarQrCodeTap, state: state, windowUUID: action.windowUUID)
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.showQRcodeReader)
            store.dispatch(action)

        case .back:
            recordTelemetry(event: .toolbarBackButtonTap, state: state, windowUUID: action.windowUUID)
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.navigateBack)
            store.dispatch(action)

        case .forward:
            recordTelemetry(event: .toolbarForwardButtonTap, state: state, windowUUID: action.windowUUID)
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.navigateForward)
            store.dispatch(action)

        case .tabs:
            cancelEditMode(windowUUID: action.windowUUID)

            recordTelemetry(event: .toolbarTabTrayButtonTap, state: state, windowUUID: action.windowUUID)
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.showTabTray)
            store.dispatch(action)

        case .trackingProtection:
            recordTelemetry(event: .toolbarSiteInfoTap, state: state, windowUUID: action.windowUUID)
            let action = GeneralBrowserAction(buttonTapped: action.buttonTapped,
                                              windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.showTrackingProtectionDetails)
            store.dispatch(action)

        case .menu:
            cancelEditMode(windowUUID: action.windowUUID)

            let action = GeneralBrowserAction(buttonTapped: action.buttonTapped,
                                              windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.showMenu)
            store.dispatch(action)

        case .cancelEdit:
            cancelEditMode(windowUUID: action.windowUUID)

        case .readerMode:
            recordReaderModeTelemetry(state: state, windowUUID: action.windowUUID)
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.showReaderMode)
            store.dispatch(action)

        case .reload:
            recordTelemetry(event: .toolbarRefreshButtonTap, state: state, windowUUID: action.windowUUID)
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.reloadWebsite)
            store.dispatch(action)

        case .stopLoading:
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.stopLoadingWebsite)
            store.dispatch(action)

        case .share:
            recordTelemetry(event: .toolbarShareButtonTap, state: state, windowUUID: action.windowUUID)
            let action = GeneralBrowserAction(buttonTapped: action.buttonTapped,
                                              windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.showShare)
            store.dispatch(action)

        case .search:
            recordTelemetry(event: .toolbarSearchButtonTap, state: state, windowUUID: action.windowUUID)
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

    private func handleToolbarButtonLongPressActions(action: ToolbarMiddlewareAction, state: AppState) {
        switch action.buttonType {
        case .back:
            recordTelemetry(event: .toolbarBackLongPress, state: state, windowUUID: action.windowUUID)
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.showBackForwardList)
            store.dispatch(action)
        case .forward:
            recordTelemetry(event: .toolbarForwardLongPress, state: state, windowUUID: action.windowUUID)
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
            recordTelemetry(event: .toolbarOneTapNewTabLongPress, state: state, windowUUID: action.windowUUID)
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
    // For the top placement of the address bar, the border is only visible on scroll. This is due to a design choice.
    private func updateTopAddressBorderPosition(scrollOffset: CGPoint, windowUUID: WindowUUID, state: AppState) {
        guard let toolbarState = state.screenState(ToolbarState.self,
                                                   for: .toolbar,
                                                   window: windowUUID),
              toolbarState.toolbarPosition == .top
        else { return }

        let addressBorderPosition = getAddressBorderPosition(
            toolbarPosition: toolbarState.toolbarPosition,
            isPrivate: toolbarState.isPrivateMode,
            scrollY: scrollOffset.y
        )

        let toolbarAction = ToolbarAction(
            addressBorderPosition: addressBorderPosition,
            windowUUID: windowUUID,
            actionType: ToolbarActionType.borderPositionChanged
        )
        store.dispatch(toolbarAction)
    }

    private func isMicrosurveyShown(action: GeneralBrowserMiddlewareAction, state: AppState) -> Bool {
        let bvcState = state.screenState(
            BrowserViewControllerState.self,
            for: .browserViewController,
            window: action.windowUUID
        )
        return bvcState?.microsurveyState.showPrompt ?? false
    }

    // Update border to hide for bottom toolbars when microsurvey is shown,
    // so that it appears to belong to the app and harder to spoof
    // 
    // Border Requirement:
    //  - When survey is shown and address bar is at top, hide border in between survey and nav toolbar
    //  - When survey is shown and address bar is at bottom, hide borders for address and nav toolbar
    //  - When survey is dismissed, show border as expected based on the toolbar requirements
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

        // If a microsurvey is shown, then we only want to show the top border for the microsurvey
        // and the toolbars should have no borders if they are stacked underneath the microsurvey.
        // This is to avoid spoofing. In the case where the address bar is on top, then the microsurvey
        // should not affect its address border position.
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
    private func cancelEditMode(windowUUID: WindowUUID) {
        let action = ToolbarAction(windowUUID: windowUUID, actionType: ToolbarActionType.cancelEdit)
        store.dispatch(action)

        let browserAction = GeneralBrowserAction(showOverlay: false,
                                                 windowUUID: windowUUID,
                                                 actionType: GeneralBrowserActionType.leaveOverlay)
        store.dispatch(browserAction)
    }

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

    private func recordTelemetry(event: TelemetryWrapper.EventValue,
                                 additionalExtras: [String: Any]? = nil,
                                 state: AppState,
                                 windowUUID: WindowUUID) {
        guard let toolbarState = state.screenState(ToolbarState.self, for: .toolbar, window: windowUUID)
        else { return }

        var extras: [String: Any] = [
            TelemetryWrapper.EventExtraKey.Toolbar.isPrivate.rawValue: toolbarState.isPrivateMode
        ]

        if let additionalExtras {
            extras = extras.merge(with: additionalExtras)
        }

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .toolbar,
                                     value: event,
                                     extras: extras)
    }

    private func recordReaderModeTelemetry(state: AppState, windowUUID: WindowUUID) {
        guard let toolbarState = state.screenState(ToolbarState.self, for: .toolbar, window: windowUUID) else { return }

        let isReaderModeEnabled = switch toolbarState.addressToolbar.readerModeState {
        case .available: true // will be enabled after action gets executed
        default: false
        }

        recordTelemetry(
            event: .toolbarReaderModeTap,
            additionalExtras: [TelemetryWrapper.EventExtraKey.Toolbar.isEnabled.rawValue: isReaderModeEnabled],
            state: state,
            windowUUID: windowUUID)
    }
}
