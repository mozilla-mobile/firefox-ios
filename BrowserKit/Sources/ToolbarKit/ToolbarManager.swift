// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct AddressToolbarBorderConfiguration {
    var a11yIdentifier: String
    var borderPosition: AddressToolbarBorderPosition?

    public init(a11yIdentifier: String, borderPosition: AddressToolbarBorderPosition?) {
        self.a11yIdentifier = a11yIdentifier
        self.borderPosition = borderPosition
    }
}

public enum AddressToolbarBorderPosition: Sendable {
    case bottom
    case top
    case none
}

public protocol ToolbarManager {
    /// Determines which border should be displayed for the address toolbar.
    /// `isScrolled` means the page content is scrolled past the top.
    func getAddressBorderPosition(for toolbarPosition: AddressToolbarPosition,
                                  isPrivate: Bool,
                                  isScrolled: Bool,
                                  isMicrosurveyShown: Bool) -> AddressToolbarBorderPosition

    /// Determines whether a border on top of the navigation toolbar should be displayed
    func shouldDisplayNavigationBorder(toolbarPosition: AddressToolbarPosition,
                                       isMicrosurveyShown: Bool) -> Bool
}

public final class DefaultToolbarManager: ToolbarManager {
    public init() {}

    public func getAddressBorderPosition(for toolbarPosition: AddressToolbarPosition,
                                         isPrivate: Bool,
                                         isScrolled: Bool,
                                         isMicrosurveyShown: Bool) -> AddressToolbarBorderPosition {
        // display the top border if
        // - the toolbar is displayed at the bottom (hidden while a microsurvey is shown)
        // display the bottom border if
        // - the toolbar is displayed at the top and page is scrolled
        // - the toolbar is displayed at the top and we are in private mode
        // A microsurvey never affects the border of an address bar at the top.
        switch toolbarPosition {
        case .bottom:
            return isMicrosurveyShown ? .none : .top
        case .top:
            return (isScrolled || isPrivate) ? .bottom : .none
        }
    }

    public func shouldDisplayNavigationBorder(toolbarPosition: AddressToolbarPosition,
                                              isMicrosurveyShown: Bool) -> Bool {
        // Hidden while a microsurvey is shown so the survey looks like part of the app and can't be spoofed
        return toolbarPosition == .top && !isMicrosurveyShown
    }
}
