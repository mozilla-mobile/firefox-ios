// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum AddressToolbarBorderPosition {
    case bottom
    case top
    case none
}

public protocol ToolbarManager {
    /// Determines which border should be displayed for the address toolbar
    func getAddressBorderPosition(for toolbarPosition: AddressToolbarPosition,
                                  isPrivate: Bool,
                                  scrollY: CGFloat) -> AddressToolbarBorderPosition

    /// Determines whether a border on top of the navigation toolbar should be displayed
    func shouldDisplayNavigationBorder(toolbarPosition: AddressToolbarPosition) -> Bool
}

public class DefaultToolbarManager: ToolbarManager {
    public init() {}

    public func getAddressBorderPosition(for toolbarPosition: AddressToolbarPosition,
                                         isPrivate: Bool,
                                         scrollY: CGFloat) -> AddressToolbarBorderPosition {
        // display the top border if
        // - the toolbar is displayed at the bottom
        // display the bottom border if
        // - the toolbar is displayed at the top and page is scrolled
        // - the toolbar is displayed at the top and we are in private mode
        if toolbarPosition == .bottom {
            return .top
        } else if toolbarPosition == .top && (scrollY > 0 || isPrivate) {
            return .bottom
        } else {
            return .none
        }
    }

    public func shouldDisplayNavigationBorder(toolbarPosition: AddressToolbarPosition) -> Bool {
        return toolbarPosition == .top
    }
}
