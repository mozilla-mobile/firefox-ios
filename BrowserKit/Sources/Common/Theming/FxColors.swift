// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

// This class contains all official Firefox colors
// referenced in https://www.figma.com/file/DyIIHvRgqt2EXfAVn1gV9c/Firefox-Colors?node-id=90%3A0
// You should never call those colors directly, they should only be called from a theme within the theme manager.
final class FXColors {
    // MARK: - Black & White
    static let Black = UIColor(rgb: 0x000000)
    static let White = UIColor(rgb: 0xffffff)

    // MARK: - Light Grey
    static let LightGrey05 = UIColor(rgb: 0xfbfbfe)
    static let LightGrey10 = UIColor(rgb: 0xf9f9fb)
    static let LightGrey20 = UIColor(rgb: 0xf0f0f4)
    static let LightGrey30 = UIColor(rgb: 0xe0e0e6)
    static let LightGrey40 = UIColor(rgb: 0xcfcfd8)
    static let LightGrey50 = UIColor(rgb: 0xbfbfc9)
    static let LightGrey60 = UIColor(rgb: 0xafafba)
    static let LightGrey70 = UIColor(rgb: 0x9f9fad)
    static let LightGrey80 = UIColor(rgb: 0x8f8f9d)
    static let LightGrey90 = UIColor(rgb: 0x80808e)

    // MARK: - Dark Grey
    static let DarkGrey05 = UIColor(rgb: 0x5b5b66)
    static let DarkGrey10 = UIColor(rgb: 0x52525e)
    static let DarkGrey20 = UIColor(rgb: 0x4a4a55)
    static let DarkGrey30 = UIColor(rgb: 0x42414d)
    static let DarkGrey40 = UIColor(rgb: 0x3a3944)
    static let DarkGrey50 = UIColor(rgb: 0x32313c)
    static let DarkGrey60 = UIColor(rgb: 0x2b2a33)
    static let DarkGrey70 = UIColor(rgb: 0x23222b)
    static let DarkGrey80 = UIColor(rgb: 0x1c1b22)
    static let DarkGrey90 = UIColor(rgb: 0x15141a)

    // MARK: - Blue
    static let Blue05 = UIColor(rgb: 0xaaf2ff)
    static let Blue10 = UIColor(rgb: 0x80ebff)
    static let Blue20 = UIColor(rgb: 0x00ddff)
    static let Blue30 = UIColor(rgb: 0x00b3f4)
    static let Blue40 = UIColor(rgb: 0x0090ed)
    static let Blue50 = UIColor(rgb: 0x0060df)
    static let Blue60 = UIColor(rgb: 0x0250bb)
    static let Blue70 = UIColor(rgb: 0x054096)
    static let Blue80 = UIColor(rgb: 0x073072)
    static let Blue90 = UIColor(rgb: 0x09204d)

    // MARK: - Green
    static let Green05 = UIColor(rgb: 0xe3fff3)
    static let Green10 = UIColor(rgb: 0xd1ffee)
    static let Green20 = UIColor(rgb: 0xb3ffe3)
    static let Green30 = UIColor(rgb: 0x87ffd1)
    static let Green40 = UIColor(rgb: 0x54ffbd)
    static let Green50 = UIColor(rgb: 0x3fe1b0)
    static let Green60 = UIColor(rgb: 0x2ac3a2)
    static let Green70 = UIColor(rgb: 0x008787)
    static let Green80 = UIColor(rgb: 0x005e5e)
    static let Green90 = UIColor(rgb: 0x08403f)

    // MARK: - Yellow
    static let Yellow05 = UIColor(rgb: 0xffffcc)
    static let Yellow10 = UIColor(rgb: 0xffff98)
    static let Yellow20 = UIColor(rgb: 0xffea80)
    static let Yellow30 = UIColor(rgb: 0xffd567)
    static let Yellow40 = UIColor(rgb: 0xffbd4f)
    static let Yellow50 = UIColor(rgb: 0xffa436)
    static let Yellow60 = UIColor(rgb: 0xe27f2e)
    static let Yellow70 = UIColor(rgb: 0xc45a27)
    static let Yellow80 = UIColor(rgb: 0xa7341f)
    static let Yellow90 = UIColor(rgb: 0x960e18)

    // MARK: - Orange
    static let Orange05 = UIColor(rgb: 0xfff4de)
    static let Orange10 = UIColor(rgb: 0xffd5b2)
    static let Orange20 = UIColor(rgb: 0xffb587)
    static let Orange30 = UIColor(rgb: 0xffa266)
    static let Orange40 = UIColor(rgb: 0xff8a50)
    static let Orange50 = UIColor(rgb: 0xff7139)
    static let Orange60 = UIColor(rgb: 0xe25920)
    static let Orange70 = UIColor(rgb: 0xcc3d00)
    static let Orange80 = UIColor(rgb: 0x9e280b)
    static let Orange90 = UIColor(rgb: 0x7c1504)

    // MARK: - Red
    static let Red05 = UIColor(rgb: 0xffdfe7)
    static let Red10 = UIColor(rgb: 0xffbdc5)
    static let Red20 = UIColor(rgb: 0xff9aa2)
    static let Red30 = UIColor(rgb: 0xff848b)
    static let Red40 = UIColor(rgb: 0xff6a75)
    static let Red50 = UIColor(rgb: 0xff4f5e)
    static let Red60 = UIColor(rgb: 0xe22850)
    static let Red70 = UIColor(rgb: 0xc50042)
    static let Red80 = UIColor(rgb: 0x810220)
    static let Red90 = UIColor(rgb: 0x440306)

    // MARK: - Violet
    static let Violet05 = UIColor(rgb: 0xe7dfff)
    static let Violet10 = UIColor(rgb: 0xd9bfff)
    static let Violet20 = UIColor(rgb: 0xcb9eff)
    static let Violet30 = UIColor(rgb: 0xc689ff)
    static let Violet40 = UIColor(rgb: 0xab71ff)
    static let Violet50 = UIColor(rgb: 0x9059ff)
    static let Violet60 = UIColor(rgb: 0x7542e5)
    static let Violet70 = UIColor(rgb: 0x592acb)
    static let Violet80 = UIColor(rgb: 0x45278d)
    static let Violet90 = UIColor(rgb: 0x321c64)

    // MARK: - Pink
    static let Pink05 = UIColor(rgb: 0xffdef0)
    static let Pink10 = UIColor(rgb: 0xffb4db)
    static let Pink20 = UIColor(rgb: 0xff8ac5)
    static let Pink30 = UIColor(rgb: 0xff6bba)
    static let Pink40 = UIColor(rgb: 0xff4aa2)
    static let Pink50 = UIColor(rgb: 0xff298a)
    static let Pink60 = UIColor(rgb: 0xe31587)
    static let Pink70 = UIColor(rgb: 0xc60084)
    static let Pink80 = UIColor(rgb: 0x7f145b)
    static let Pink90 = UIColor(rgb: 0x50134b)

    // MARK: - Purple
    static let Purple05 = UIColor(rgb: 0xf7e2ff)
    static let Purple10 = UIColor(rgb: 0xf6b8ff)
    static let Purple20 = UIColor(rgb: 0xf68fff)
    static let Purple30 = UIColor(rgb: 0xf770ff)
    static let Purple40 = UIColor(rgb: 0xd74cf0)
    static let Purple50 = UIColor(rgb: 0xb833e1)
    static let Purple60 = UIColor(rgb: 0x952bb9)
    static let Purple70 = UIColor(rgb: 0x722291)
    static let Purple80 = UIColor(rgb: 0x4e1a69)
    static let Purple90 = UIColor(rgb: 0x2b1141)

    // MARK: - Ink
    static let Ink05 = UIColor(rgb: 0x393473)
    static let Ink10 = UIColor(rgb: 0x342f6d)
    static let Ink20 = UIColor(rgb: 0x312a64)
    static let Ink30 = UIColor(rgb: 0x2e255d)
    static let Ink40 = UIColor(rgb: 0x2b2156)
    static let Ink50 = UIColor(rgb: 0x291d4f)
    static let Ink60 = UIColor(rgb: 0x271948)
    static let Ink70 = UIColor(rgb: 0x241541)
    static let Ink80 = UIColor(rgb: 0x20123a)
    static let Ink90 = UIColor(rgb: 0x1d1133)
}

// Accent ramp used only for legacy placeholder ("letter") favicons.
extension FXColors {
    static let FaviconGreen1 = UIColor(rgb: 0x2e761a)
    static let FaviconGreen2 = UIColor(rgb: 0x399320)
    static let FaviconGreen3 = UIColor(rgb: 0x40a624)
    static let FaviconGreen4 = UIColor(rgb: 0x57bd35)
    static let FaviconGreen5 = UIColor(rgb: 0x70cf5b)
    static let FaviconGreen6 = UIColor(rgb: 0x90e07f)
    static let FaviconGreen7 = UIColor(rgb: 0xb1eea5)

    static let FaviconRed1 = UIColor(rgb: 0x881606)
    static let FaviconRed2 = UIColor(rgb: 0xaa1b08)
    static let FaviconRed3 = UIColor(rgb: 0xc21f09)
    static let FaviconRed4 = UIColor(rgb: 0xd92215)
    static let FaviconRed5 = UIColor(rgb: 0xee4b36)
    static let FaviconRed6 = UIColor(rgb: 0xf67964)
    static let FaviconRed7 = UIColor(rgb: 0xffa792)

    static let FaviconBlue1 = UIColor(rgb: 0x025295)
    static let FaviconBlue2 = UIColor(rgb: 0x0568ba)
    static let FaviconBlue3 = UIColor(rgb: 0x0675d3)
    static let FaviconBlue4 = UIColor(rgb: 0x0996f8)
    static let FaviconBlue5 = UIColor(rgb: 0x2ea3ff)
    static let FaviconBlue6 = UIColor(rgb: 0x61b4ff)
    static let FaviconBlue7 = UIColor(rgb: 0x95cdff)

    static let FaviconCyan1 = UIColor(rgb: 0x00736f)
    static let FaviconCyan2 = UIColor(rgb: 0x01908b)
    static let FaviconCyan3 = UIColor(rgb: 0x01a39d)
    static let FaviconCyan4 = UIColor(rgb: 0x01bdad)
    static let FaviconCyan5 = UIColor(rgb: 0x27d9d2)
    static let FaviconCyan6 = UIColor(rgb: 0x58e7e6)
    static let FaviconCyan7 = UIColor(rgb: 0x89f4f5)

    static let FaviconOrange1 = UIColor(rgb: 0xc84510)
    static let FaviconOrange2 = UIColor(rgb: 0xe35b0f)
    static let FaviconOrange3 = UIColor(rgb: 0xf77100)
    static let FaviconOrange4 = UIColor(rgb: 0xff9216)
    static let FaviconOrange5 = UIColor(rgb: 0xffad2e)
    static let FaviconOrange6 = UIColor(rgb: 0xffc446)
    static let FaviconOrange7 = UIColor(rgb: 0xffdf81)

    static let FaviconPink1 = UIColor(rgb: 0x911a2e)
    static let FaviconPink2 = UIColor(rgb: 0xb7223b)
    static let FaviconPink3 = UIColor(rgb: 0xcf2743)
    static let FaviconPink4 = UIColor(rgb: 0xea385e)
    static let FaviconPink5 = UIColor(rgb: 0xfa526e)
    static let FaviconPink6 = UIColor(rgb: 0xff7a8d)
    static let FaviconPink7 = UIColor(rgb: 0xffa7b3)
}
