// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

extension Color {

    /// Returns a `Color` from the Ecosia bundle for a given name.
    ///
    /// This method retrieves a color from the Ecosia resources within the app bundle using the specified name.
    ///
    /// - Parameter name: The name of the color to retrieve.
    /// - Returns: A `Color` object corresponding to the specified color name from the Ecosia bundle.
    public static func ecosiaBundledColorWithName(_ name: String) -> Color {
        Color(name, bundle: Bundle.ecosia)
    }
}
