// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

// This file outline the existence of CustomTheme with no implementation.
// Because this is not a required feature, it's merely intended to sketch
// out a foundation for how things might work, and can, at the moment,
// be largely ignored.

struct CustomTheme: Codable {
    var colours: CustomColourPalette
    var fonts: CustomFontPalette
}

struct CustomColourPalette: Codable {
}

struct CustomFontPalette: Codable {
}
