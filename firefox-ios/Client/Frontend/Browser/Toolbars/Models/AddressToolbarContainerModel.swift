// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ToolbarKit
import Shared

class AddressToolbarContainerModel: Equatable {
    let navigationActions: [ToolbarElement]
    let pageActions: [ToolbarElement]
    let browserActions: [ToolbarElement]

    let borderPosition: AddressToolbarBorderPosition?
    let searchEngineImage: UIImage?
    let searchEngines: SearchEngines
    let lockIconImageName: String?
    let url: URL?
    let searchTerm: String?
    let isEditing: Bool
    let isScrollingDuringEdit: Bool
    let isPrivateMode: Bool
    let shouldSelectSearchTerm: Bool
    let shouldDisplayCompact: Bool

    let windowUUID: UUID

    var addressToolbarState: AddressToolbarState {
        let term = searchTerm ?? searchTermFromURL(url, searchEngines: searchEngines)

        let locationViewState = LocationViewState(
            searchEngineImageViewA11yId: AccessibilityIdentifiers.Browser.AddressToolbar.searchEngine,
            searchEngineImageViewA11yLabel: .AddressToolbar.PrivacyAndSecuritySettingsA11yLabel,
            lockIconButtonA11yId: AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon,
            lockIconButtonA11yLabel: .AddressToolbar.SearchEngineA11yLabel,
            urlTextFieldPlaceholder: .AddressToolbar.LocationPlaceholder,
            urlTextFieldA11yId: AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField,
            urlTextFieldA11yLabel: .AddressToolbar.LocationA11yLabel,
            searchEngineImage: searchEngineImage,
            lockIconImageName: lockIconImageName,
            url: url,
            searchTerm: term,
            isEditing: isEditing,
            isScrollingDuringEdit: isScrollingDuringEdit,
            shouldSelectSearchTerm: shouldSelectSearchTerm,
            onTapLockIcon: { button in
                let action = ToolbarMiddlewareAction(buttonType: .trackingProtection,
                                                     buttonTapped: button,
                                                     gestureType: .tap,
                                                     windowUUID: self.windowUUID,
                                                     actionType: ToolbarMiddlewareActionType.didTapButton)
                store.dispatch(action)
            },
            onLongPress: {
                let action = ToolbarMiddlewareAction(buttonType: .locationView,
                                                     gestureType: .longPress,
                                                     windowUUID: self.windowUUID,
                                                     actionType: ToolbarMiddlewareActionType.didTapButton)
                store.dispatch(action)
            })
        return AddressToolbarState(
            locationViewState: locationViewState,
            navigationActions: navigationActions,
            pageActions: pageActions,
            browserActions: browserActions,
            borderPosition: borderPosition)
    }

    init(state: ToolbarState, profile: Profile, windowUUID: UUID) {
        self.borderPosition = state.addressToolbar.borderPosition
        self.navigationActions = AddressToolbarContainerModel.mapActions(state.addressToolbar.navigationActions,
                                                                         isShowingTopTabs: state.isShowingTopTabs,
                                                                         windowUUID: windowUUID)
        self.pageActions = AddressToolbarContainerModel.mapActions(state.addressToolbar.pageActions,
                                                                   isShowingTopTabs: state.isShowingTopTabs,
                                                                   windowUUID: windowUUID)
        self.browserActions = AddressToolbarContainerModel.mapActions(state.addressToolbar.browserActions,
                                                                      isShowingTopTabs: state.isShowingTopTabs,
                                                                      windowUUID: windowUUID)
        self.windowUUID = windowUUID
        self.searchEngineImage = profile.searchEngines.defaultEngine?.image
        self.searchEngines = profile.searchEngines
        self.lockIconImageName = state.addressToolbar.lockIconImageName
        self.url = state.addressToolbar.url
        self.searchTerm = state.addressToolbar.searchTerm
        self.isEditing = state.addressToolbar.isEditing
        self.isScrollingDuringEdit = state.addressToolbar.isScrollingDuringEdit
        self.isPrivateMode = state.isPrivateMode
        self.shouldSelectSearchTerm = state.addressToolbar.shouldSelectSearchTerm
        self.shouldDisplayCompact = state.isShowingNavigationToolbar
    }

    func searchTermFromURL(_ url: URL?, searchEngines: SearchEngines) -> String? {
        var searchURL: URL? = url

        if let url = searchURL, InternalURL.isValid(url: url) {
            searchURL = url
        }

        guard let query = searchEngines.queryForSearchURL(searchURL) else { return nil }
        return query
    }

    private static func mapActions(_ actions: [ToolbarActionState],
                                   isShowingTopTabs: Bool,
                                   windowUUID: UUID) -> [ToolbarElement] {
        return actions.map { action in
            ToolbarElement(
                iconName: action.iconName,
                badgeImageName: action.badgeImageName,
                maskImageName: action.maskImageName,
                numberOfTabs: action.numberOfTabs,
                isEnabled: action.isEnabled,
                isFlippedForRTL: action.isFlippedForRTL,
                shouldDisplayAsHighlighted: action.shouldDisplayAsHighlighted,
                hasContextualHint: action.hasContextualHint,
                a11yLabel: action.a11yLabel,
                a11yHint: action.a11yHint,
                a11yId: action.a11yId,
                a11yCustomActionName: action.a11yCustomActionName,
                a11yCustomAction: action.a11yCustomActionName != nil ? {
                    let action = ToolbarMiddlewareAction(buttonType: action.actionType,
                                                         windowUUID: windowUUID,
                                                         actionType: ToolbarMiddlewareActionType.customA11yAction)
                    store.dispatch(action)
                } : nil,
                hasLongPressAction: action.canPerformLongPressAction(isShowingTopTabs: isShowingTopTabs),
                onSelected: { button in
                    let action = ToolbarMiddlewareAction(buttonType: action.actionType,
                                                         buttonTapped: button,
                                                         gestureType: .tap,
                                                         windowUUID: windowUUID,
                                                         actionType: ToolbarMiddlewareActionType.didTapButton)
                    store.dispatch(action)
                }, onLongPress: action.canPerformLongPressAction(isShowingTopTabs: isShowingTopTabs) ? { button in
                    let action = ToolbarMiddlewareAction(buttonType: action.actionType,
                                                         buttonTapped: button,
                                                         gestureType: .longPress,
                                                         windowUUID: windowUUID,
                                                         actionType: ToolbarMiddlewareActionType.didTapButton)
                    store.dispatch(action)
                } : nil
            )
        }
    }

    static func == (lhs: AddressToolbarContainerModel, rhs: AddressToolbarContainerModel) -> Bool {
        lhs.navigationActions == rhs.navigationActions &&
        lhs.pageActions == rhs.pageActions &&
        lhs.browserActions == rhs.browserActions &&

        lhs.borderPosition == rhs.borderPosition &&
        lhs.searchEngineImage == rhs.searchEngineImage &&
        lhs.lockIconImageName == rhs.lockIconImageName &&
        lhs.url == rhs.url &&
        lhs.searchTerm == rhs.searchTerm &&
        lhs.isEditing == rhs.isEditing &&
        lhs.shouldSelectSearchTerm == rhs.shouldSelectSearchTerm &&
        lhs.shouldDisplayCompact == rhs.shouldDisplayCompact &&

        lhs.windowUUID == rhs.windowUUID
    }
}
