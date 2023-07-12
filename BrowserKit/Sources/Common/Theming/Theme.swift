// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The `Theme` protocol, which contains the implementation of themes,
/// which comprise of a set of standardized colours (including light and
/// dark mode) and fonts for the application.
public protocol Theme {
    var type: ThemeType { get }
    var colors: ThemeColourPalette { get }
}
