// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum AddressToolbarBorderPosition {
    case bottom
    case top
}

public protocol ToolbarManager {
    /// Determines whether a border on top/bottom of the address toolbar should be displayed
    func shouldDisplayAddressBorder(borderPosition: AddressToolbarBorderPosition,
                                    toolbarPosition: AddressToolbarPosition,
                                    isPrivate: Bool,
                                    scrollY: CGFloat) -> Bool

    /// Determines whether a border on top of the navigation toolbar should be displayed
    func shouldDisplayNavigationBorder(toolbarPosition: AddressToolbarPosition) -> Bool
}

public class DefaultToolbarManager: ToolbarManager {
    public init() {}

    public func shouldDisplayAddressBorder(borderPosition: AddressToolbarBorderPosition,
                                           toolbarPosition: AddressToolbarPosition,
                                           isPrivate: Bool,
                                           scrollY: CGFloat) -> Bool {
        // display the top border if
        // - the toolbar is displayed at the bottom
        // display the bottom border if
        // - the toolbar is displayed at the top and the website was scrolled
        // - we are in private mode
        if borderPosition == .top {
            return toolbarPosition == .bottom
        } else {
            return (toolbarPosition == .top && scrollY > 0) || isPrivate
        }
    }

    public func shouldDisplayNavigationBorder(toolbarPosition: AddressToolbarPosition) -> Bool {
        return toolbarPosition == .top
    }
}
