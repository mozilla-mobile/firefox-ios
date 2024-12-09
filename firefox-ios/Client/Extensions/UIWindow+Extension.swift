// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// swiftlint:disable first_where
extension UIWindow {
    static var keyWindow: UIWindow? {
        return UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .first(where: { $0 is UIWindowScene })
            .flatMap({ $0 as? UIWindowScene })?.windows
            .first(where: \.isKeyWindow)
    }

    /// Filter for any scenes that are attached, regardless of state (i.e. active, inactive and background)
    static var attachedKeyWindow: UIWindow? {
        return UIApplication.shared.connectedScenes
            .filter { $0.activationState != .unattached }
            .first(where: { $0 is UIWindowScene })
            .flatMap({ $0 as? UIWindowScene })?.windows
            .first(where: \.isKeyWindow)
    }

    static var isLandscape: Bool {
        interfaceOrientation?
            .isLandscape ?? false
    }

    static var isPortrait: Bool {
        interfaceOrientation?
            .isPortrait ?? false
    }

    static var interfaceOrientation: UIInterfaceOrientation? {
        keyWindow?.windowScene?.interfaceOrientation
    }
}
// swiftlint:enable first_where
