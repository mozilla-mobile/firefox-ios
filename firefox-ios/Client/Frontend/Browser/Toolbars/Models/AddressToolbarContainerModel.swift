// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ToolbarKit
import Shared

final class AddressToolbarContainerModel: Equatable {
    let toolbarHelper: ToolbarHelperInterface

    let navigationActions: [ToolbarElement]
    let leadingPageActions: [ToolbarElement]
    let trailingPageActions: [ToolbarElement]
    let browserActions: [ToolbarElement]

    let toolbarLayoutStyle: ToolbarLayoutStyle
    let borderPosition: AddressToolbarBorderPosition?
    let searchEngineName: String
    let searchEngineImage: UIImage
    let searchEnginesManager: SearchEnginesManager
    let lockIconImageName: String?
    let lockIconNeedsTheming: Bool
    let safeListedURLImageName: String?
    let url: URL?
    let searchTerm: String?
    let isEditing: Bool
    let didStartTyping: Bool
    let shouldShowKeyboard: Bool
    let isPrivateMode: Bool
    let shouldSelectSearchTerm: Bool
    let shouldDisplayCompact: Bool
    let canShowNavigationHint: Bool
    let shouldAnimate: Bool

    let windowUUID: UUID

    var addressToolbarConfig: AddressToolbarConfiguration {
        let term = searchTerm ?? searchTermFromURL(url)
        let backgroundAlpha = toolbarHelper.backgroundAlpha()
        let shouldBlur = toolbarHelper.shouldBlur()
        let uxConfiguration: AddressToolbarUXConfiguration = .experiment(backgroundAlpha: backgroundAlpha,
                                                                         shouldBlur: shouldBlur)

        var droppableUrl: URL?
        if let url, !InternalURL.isValid(url: url) {
            droppableUrl = url
        }

        let locationViewConfiguration = LocationViewConfiguration(
            searchEngineImageViewA11yId: AccessibilityIdentifiers.Browser.AddressToolbar.searchEngine,
            searchEngineImageViewA11yLabel: String(
                format: .AddressToolbar.SearchEngineA11yLabel,
                searchEngineName
            ),
            lockIconButtonA11yId: AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon,
            lockIconButtonA11yLabel: .AddressToolbar.PrivacyAndSecuritySettingsA11yLabel,
            urlTextFieldPlaceholder: .AddressToolbar.LocationPlaceholder,
            urlTextFieldA11yId: AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField,
            searchEngineImage: searchEngineImage,
            lockIconImageName: lockIconImageName,
            lockIconNeedsTheming: lockIconNeedsTheming,
            safeListedURLImageName: safeListedURLImageName,
            url: url,
            droppableUrl: droppableUrl,
            searchTerm: term,
            isEditing: isEditing,
            didStartTyping: didStartTyping,
            shouldShowKeyboard: shouldShowKeyboard,
            shouldSelectSearchTerm: shouldSelectSearchTerm,
            onTapLockIcon: { button in
                let action = ToolbarMiddlewareAction(buttonType: .trackingProtection,
                                                     buttonTapped: button,
                                                     gestureType: .tap,
                                                     windowUUID: self.windowUUID,
                                                     actionType: ToolbarMiddlewareActionType.didTapButton)
                store.dispatchLegacy(action)
            },
            onLongPress: {
                let action = ToolbarMiddlewareAction(buttonType: .locationView,
                                                     gestureType: .longPress,
                                                     windowUUID: self.windowUUID,
                                                     actionType: ToolbarMiddlewareActionType.didTapButton)
                store.dispatchLegacy(action)
            })
        return AddressToolbarConfiguration(
            locationViewConfiguration: locationViewConfiguration,
            navigationActions: navigationActions,
            leadingPageActions: leadingPageActions,
            trailingPageActions: trailingPageActions,
            browserActions: browserActions,
            borderPosition: borderPosition,
            uxConfiguration: uxConfiguration,
            shouldAnimate: shouldAnimate)
    }

    /// Returns a skeleton (placeholder) `AddressToolbarConfiguration` for the address bar.
    /// This method is intended to provide a minimal configuration for loading or placeholder states,
    /// with only essential actions and UI elements set up. Most properties are left empty or set to default values.
    /// - Parameters:
    ///   - url: The URL to display in the address bar, if any.
    ///   - isReaderModeAvailableOrActive: Indicates if reader mode is available or active,
    ///   used to determine trailing actions.
    /// - Returns: A skeleton `AddressToolbarConfiguration` suitable for placeholder or loading UI.
    func configureSkeletonAddressBar(
        with url: URL?,
        isReaderModeAvailableOrActive: Bool?
    ) -> AddressToolbarConfiguration {
        let backgroundAlpha = toolbarHelper.backgroundAlpha()
        let shouldBlur = toolbarHelper.shouldBlur()
        let uxConfiguration: AddressToolbarUXConfiguration = .experiment(backgroundAlpha: backgroundAlpha,
                                                                         shouldBlur: shouldBlur)
        // Leading Page Actions
        let shareAction: ToolbarActionConfiguration = .init(
            actionType: .share,
            iconName: StandardImageIdentifiers.Medium.share,
            isEnabled: true,
            hasCustomColor: true,
            a11yLabel: "",
            a11yId: AccessibilityIdentifiers.Toolbar.shareButton
        )

        // Trailing Page Actions
        let readerModeAction: ToolbarActionConfiguration = .init(
            actionType: .readerMode,
            iconName: StandardImageIdentifiers.Medium.readerView,
            isEnabled: true,
            hasCustomColor: true,
            a11yLabel: "",
            a11yId: AccessibilityIdentifiers.Toolbar.readerModeButton
        )

        let reloadAction: ToolbarActionConfiguration = .init(
            actionType: .reload,
            iconName: StandardImageIdentifiers.Medium.arrowClockwise,
            isEnabled: true,
            hasCustomColor: true,
            a11yLabel: "",
            a11yId: AccessibilityIdentifiers.Toolbar.reloadButton
        )

        var leadingPageElements = [ToolbarElement]()
        var trailingPageElements = [ToolbarElement]()

        if url != nil {
            leadingPageElements = Self.mapActions([shareAction], isShowingTopTabs: false, windowUUID: windowUUID)
            trailingPageElements = isReaderModeAvailableOrActive == true
            ? Self.mapActions([readerModeAction, reloadAction], isShowingTopTabs: false, windowUUID: windowUUID)
            : Self.mapActions([reloadAction], isShowingTopTabs: false, windowUUID: windowUUID)
        }

        let locationViewConfiguration = LocationViewConfiguration(
            searchEngineImageViewA11yId: "",
            searchEngineImageViewA11yLabel: "",
            lockIconButtonA11yId: "",
            lockIconButtonA11yLabel: "",
            urlTextFieldPlaceholder: .AddressToolbar.LocationPlaceholder,
            urlTextFieldA11yId: "",
            searchEngineImage: nil,
            lockIconImageName: "",
            lockIconNeedsTheming: false,
            safeListedURLImageName: safeListedURLImageName,
            url: url,
            droppableUrl: nil,
            searchTerm: nil,
            isEditing: false,
            didStartTyping: false,
            shouldShowKeyboard: false,
            shouldSelectSearchTerm: false,
            onTapLockIcon: { _ in },
            onLongPress: {})

        return AddressToolbarConfiguration(
            locationViewConfiguration: locationViewConfiguration,
            navigationActions: [],
            leadingPageActions: leadingPageElements,
            trailingPageActions: trailingPageElements,
            browserActions: [],
            borderPosition: borderPosition,
            uxConfiguration: uxConfiguration,
            shouldAnimate: shouldAnimate
        )
    }

    init(
        state: ToolbarState,
        profile: Profile,
        searchEnginesManager: SearchEnginesManager = AppContainer.shared.resolve(),
        toolbarHelper: ToolbarHelperInterface = ToolbarHelper(),
        windowUUID: UUID
    ) {
        self.borderPosition = state.addressToolbar.borderPosition
        self.navigationActions = AddressToolbarContainerModel.mapActions(state.addressToolbar.navigationActions,
                                                                         isShowingTopTabs: state.isShowingTopTabs,
                                                                         windowUUID: windowUUID)
        self.leadingPageActions = AddressToolbarContainerModel.mapActions(state.addressToolbar.leadingPageActions,
                                                                          isShowingTopTabs: state.isShowingTopTabs,
                                                                          windowUUID: windowUUID)
        self.trailingPageActions = AddressToolbarContainerModel.mapActions(state.addressToolbar.trailingPageActions,
                                                                           isShowingTopTabs: state.isShowingTopTabs,
                                                                           windowUUID: windowUUID)
        self.browserActions = AddressToolbarContainerModel.mapActions(state.addressToolbar.browserActions,
                                                                      isShowingTopTabs: state.isShowingTopTabs,
                                                                      windowUUID: windowUUID)

        // If the user has selected an alternative search engine, use that. Otherwise, use the default engine.
        let searchEngineModel = state.addressToolbar.alternativeSearchEngine
                                ?? searchEnginesManager.defaultEngine?.generateModel()

        self.windowUUID = windowUUID
        self.searchEngineName = searchEngineModel?.name ?? ""
        self.searchEngineImage = searchEngineModel?.image ?? UIImage()
        self.searchEnginesManager = searchEnginesManager
        self.lockIconImageName = state.addressToolbar.lockIconImageName
        self.lockIconNeedsTheming = state.addressToolbar.lockIconNeedsTheming
        self.safeListedURLImageName = state.addressToolbar.safeListedURLImageName
        self.url = state.addressToolbar.url
        self.searchTerm = state.addressToolbar.searchTerm
        self.isEditing = state.addressToolbar.isEditing
        self.didStartTyping = state.addressToolbar.didStartTyping
        self.shouldShowKeyboard = state.addressToolbar.shouldShowKeyboard
        self.isPrivateMode = state.isPrivateMode
        self.shouldSelectSearchTerm = state.addressToolbar.shouldSelectSearchTerm
        self.shouldDisplayCompact = state.isShowingNavigationToolbar
        self.canShowNavigationHint = state.canShowNavigationHint
        self.shouldAnimate = state.shouldAnimate
        self.toolbarLayoutStyle = state.toolbarLayout
        self.toolbarHelper = toolbarHelper
    }

    func searchTermFromURL(_ url: URL?) -> String? {
        var searchURL: URL? = url

        if let url = searchURL, InternalURL.isValid(url: url) {
            searchURL = url
        }

        return searchEnginesManager.queryForSearchURL(searchURL)
    }

    private static func mapActions(_ actions: [ToolbarActionConfiguration],
                                   isShowingTopTabs: Bool,
                                   windowUUID: UUID) -> [ToolbarElement] {
        return actions.map { action in
            ToolbarElement(
                iconName: action.iconName,
                title: action.actionLabel,
                badgeImageName: action.badgeImageName,
                maskImageName: action.maskImageName,
                numberOfTabs: action.numberOfTabs,
                isEnabled: action.isEnabled,
                isFlippedForRTL: action.isFlippedForRTL,
                isSelected: action.isSelected,
                hasCustomColor: action.hasCustomColor,
                largeContentTitle: action.largeContentTitle,
                contextualHintType: action.contextualHintType,
                a11yLabel: action.a11yLabel,
                a11yHint: action.a11yHint,
                a11yId: action.a11yId,
                a11yCustomActionName: action.a11yCustomActionName,
                a11yCustomAction: getA11yCustomAction(action: action, windowUUID: windowUUID),
                hasLongPressAction: action.canPerformLongPressAction(isShowingTopTabs: isShowingTopTabs),
                onSelected: getOnSelected(action: action, windowUUID: windowUUID),
                onLongPress: getOnLongPress(action: action, windowUUID: windowUUID, isShowingTopTabs: isShowingTopTabs)
            )
        }
    }

    private static func getA11yCustomAction(action: ToolbarActionConfiguration, windowUUID: UUID) -> (() -> Void)? {
        return action.a11yCustomActionName != nil ? {
            let action = ToolbarMiddlewareAction(buttonType: action.actionType,
                                                 windowUUID: windowUUID,
                                                 actionType: ToolbarMiddlewareActionType.customA11yAction)
            store.dispatchLegacy(action)
        } : nil
    }

    private static func getOnSelected(action: ToolbarActionConfiguration, windowUUID: UUID) -> ((UIButton) -> Void)? {
        return { button in
            let action = ToolbarMiddlewareAction(buttonType: action.actionType,
                                                 buttonTapped: button,
                                                 gestureType: .tap,
                                                 windowUUID: windowUUID,
                                                 actionType: ToolbarMiddlewareActionType.didTapButton)
            store.dispatchLegacy(action)
        }
    }

    private static func getOnLongPress(action: ToolbarActionConfiguration,
                                       windowUUID: UUID,
                                       isShowingTopTabs: Bool) -> ((UIButton) -> Void)? {
        return action.canPerformLongPressAction(isShowingTopTabs: isShowingTopTabs) ? { button in
            let action = ToolbarMiddlewareAction(buttonType: action.actionType,
                                                 buttonTapped: button,
                                                 gestureType: .longPress,
                                                 windowUUID: windowUUID,
                                                 actionType: ToolbarMiddlewareActionType.didTapButton)
            store.dispatchLegacy(action)
        } : nil
    }

    static func == (lhs: AddressToolbarContainerModel, rhs: AddressToolbarContainerModel) -> Bool {
        lhs.navigationActions == rhs.navigationActions &&
        lhs.trailingPageActions == rhs.trailingPageActions &&
        lhs.browserActions == rhs.browserActions &&

        lhs.toolbarLayoutStyle == rhs.toolbarLayoutStyle &&
        lhs.borderPosition == rhs.borderPosition &&
        lhs.searchEngineName == rhs.searchEngineName &&
        lhs.searchEngineImage == rhs.searchEngineImage &&
        lhs.lockIconImageName == rhs.lockIconImageName &&
        lhs.lockIconNeedsTheming == rhs.lockIconNeedsTheming &&
        lhs.safeListedURLImageName == rhs.safeListedURLImageName &&
        lhs.url == rhs.url &&
        lhs.searchTerm == rhs.searchTerm &&
        lhs.isEditing == rhs.isEditing &&
        lhs.didStartTyping == rhs.didStartTyping &&
        lhs.shouldShowKeyboard == rhs.shouldShowKeyboard &&
        lhs.isPrivateMode == rhs.isPrivateMode &&
        lhs.shouldSelectSearchTerm == rhs.shouldSelectSearchTerm &&
        lhs.shouldDisplayCompact == rhs.shouldDisplayCompact &&
        lhs.canShowNavigationHint == rhs.canShowNavigationHint &&
        lhs.shouldAnimate == rhs.shouldAnimate &&

        lhs.windowUUID == rhs.windowUUID
    }
}
