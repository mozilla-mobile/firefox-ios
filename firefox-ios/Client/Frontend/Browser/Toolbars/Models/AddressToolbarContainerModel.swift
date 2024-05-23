// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ToolbarKit

class AddressToolbarContainerModel {
    let navigationActions: [ToolbarElement]
    let pageActions: [ToolbarElement]
    let browserActions: [ToolbarElement]

    let displayTopBorder: Bool
    let displayBottomBorder: Bool
    let windowUUID: UUID

    var addressToolbarState: AddressToolbarState {
        let locationViewState = LocationViewState(
            clearButtonA11yId: AccessibilityIdentifiers.Browser.AddressToolbar.clear,
            clearButtonA11yLabel: .AddressToolbar.LocationClearButtonA11yLabel,
            searchEngineImageViewA11yId: AccessibilityIdentifiers.Browser.AddressToolbar.searchEngine,
            searchEngineImageViewA11yLabel: .AddressToolbar.SearchEngineA11yLabel,
            urlTextFieldPlaceholder: .AddressToolbar.LocationPlaceholder,
            urlTextFieldA11yId: AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField,
            urlTextFieldA11yLabel: .AddressToolbar.LocationA11yLabel,
            searchEngineImageName: "",
            lockIconImageName: "",
            url: nil)
        return AddressToolbarState(
            locationViewState: locationViewState,
            navigationActions: navigationActions,
            pageActions: pageActions,
            browserActions: browserActions,
            shouldDisplayTopBorder: displayTopBorder,
            shouldDisplayBottomBorder: displayBottomBorder)
    }

    init(state: ToolbarState, windowUUID: UUID) {
        self.displayTopBorder = state.addressToolbar.displayTopBorder
        self.displayBottomBorder = state.addressToolbar.displayBottomBorder

        self.navigationActions = AddressToolbarContainerModel.mapActions(state.addressToolbar.navigationActions,
                                                                         windowUUID: windowUUID)
        self.pageActions = AddressToolbarContainerModel.mapActions(state.addressToolbar.pageActions,
                                                                   windowUUID: windowUUID)
        self.browserActions = AddressToolbarContainerModel.mapActions(state.addressToolbar.browserActions,
                                                                      windowUUID: windowUUID)
        self.windowUUID = windowUUID
    }

    private static func mapActions(_ actions: [ToolbarState.ActionState], windowUUID: UUID) -> [ToolbarElement] {
        return actions.map { action in
            ToolbarElement(
                iconName: action.iconName,
                isEnabled: action.isEnabled,
                a11yLabel: action.a11yLabel,
                a11yId: action.a11yId,
                onSelected: {
                    let action = ToolbarMiddlewareAction(buttonType: action.actionType,
                                                         gestureType: .tap,
                                                         windowUUID: windowUUID,
                                                         actionType: ToolbarMiddlewareActionType.didTapButton)
                    store.dispatch(action)
                }
            )
        }
    }
}
