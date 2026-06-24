// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ToolbarKit
import Shared
import UIKit

@MainActor
struct GoogleLensMenuElementProvider {
    static func menuElements(windowUUID: WindowUUID) -> [ToolbarMenuElement] {
        return [
            ToolbarMenuElement(
                title: .AddressToolbar.GoogleLens.ContextMenu.TakePhotoActionTitle,
                imageName: StandardImageIdentifiers.Large.cameraLarge,
                a11yIdentifier: AccessibilityIdentifiers.Browser.AddressToolbar.googleLensTakePhotoAction,
                onSelected: onSelected(actionType: .googleLensTakePhoto, windowUUID: windowUUID)
            ),
            ToolbarMenuElement(
                title: .AddressToolbar.GoogleLens.ContextMenu.PhotoLibraryActionTitle,
                imageName: StandardImageIdentifiers.Large.image,
                a11yIdentifier: AccessibilityIdentifiers.Browser.AddressToolbar.googleLensPhotoLibraryAction,
                onSelected: onSelected(actionType: .googleLensPhotoLibrary, windowUUID: windowUUID)
            )
        ]
    }

    private static func onSelected(actionType: ToolbarActionConfiguration.ActionType,
                                   windowUUID: WindowUUID) -> ((UIButton) -> Void)? {
        return { button in
            let action = ToolbarMiddlewareAction(buttonType: actionType,
                                                 buttonTapped: button,
                                                 gestureType: .tap,
                                                 windowUUID: windowUUID,
                                                 actionType: ToolbarMiddlewareActionType.didTapButton)
            store.dispatch(action)
        }
    }
}
