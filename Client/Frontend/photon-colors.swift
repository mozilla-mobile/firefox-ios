// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

/* Photon Colors iOS Variables v3.3.1
 From https://github.com/FirefoxUX/photon-colors/#readme */
import UIKit

// Used as backgrounds for favicons
public let DefaultFaviconBackgroundColors = ["2e761a", "399320", "40a624", "57bd35", "70cf5b", "90e07f", "b1eea5", "881606", "aa1b08", "c21f09", "d92215", "ee4b36", "f67964", "ffa792", "025295", "0568ba", "0675d3", "0996f8", "2ea3ff", "61b4ff", "95cdff", "00736f", "01908b", "01a39d", "01bdad", "27d9d2", "58e7e6", "89f4f5", "c84510", "e35b0f", "f77100", "ff9216", "ffad2e", "ffc446", "ffdf81", "911a2e", "b7223b", "cf2743", "ea385e", "fa526e", "ff7a8d", "ffa7b3" ]

extension UIColor {
    struct Photon {
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

        static let DarkGrey05 = UIColor(rgb: 0x5b5b66)
        static let DarkGrey10 = UIColor(rgb: 0x52525e)
        static let DarkGrey20 = UIColor(rgb: 0x4a4a55)
        static let DarkGrey30 = UIColor(rgb: 0x42414d)
        static let DarkGrey40 = UIColor(rgb: 0x3a3944)
        static let DarkGrey50 = UIColor(rgb: 0x32313c)
        static let DarkGrey60 = UIColor(rgb: 0x2b2a33)
        static let DarkGrey65 = UIColor(rgb: 0x2c2c2e)
        static let DarkGrey70 = UIColor(rgb: 0x23222b)
        static let DarkGrey80 = UIColor(rgb: 0x1c1b22)
        static let DarkGrey90 = UIColor(rgb: 0x15141a)

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

        static let Blue05 = UIColor(rgb: 0xaaf2ff)
        static let Blue10 = UIColor(rgb: 0x80ebff)
        static let Blue20 = UIColor(rgb: 0x00ddff)
        static let Blue20A40 = UIColor(rgba: 0x00ddff28)
        static let Blue30 = UIColor(rgb: 0x00b3f4)
        static let Blue40 = UIColor(rgb: 0x0090ed)
        static let Blue40A30 = UIColor(rgba: 0x0090ed4c)
        static let Blue50 = UIColor(rgb: 0x0060df)
        static let Blue50A40 = UIColor(rgba: 0x0060df28)
        static let Blue60 = UIColor(rgb: 0x0250bb)
        static let Blue70 = UIColor(rgb: 0x054096)
        static let Blue80 = UIColor(rgb: 0x073072)
        static let Blue90 = UIColor(rgb: 0x09204d)

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
        static let GreenShamrock = UIColor(rgb: 0x2ac3a2) // identical to Green60

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

        static let Pink05 = UIColor(rgb: 0xffdef0)
        static let Pink10 = UIColor(rgb: 0xffb4db)
        static let Pink20 = UIColor(rgb: 0xff8ac5)
        static let Pink30 = UIColor(rgb: 0xff6bba)
        static let Pink40 = UIColor(rgb: 0xff4aa2)
        static let Pink50 = UIColor(rgb: 0xff298a)
        static let Pink60 = UIColor(rgb: 0xe21587)
        static let Pink70 = UIColor(rgb: 0xc60084)
        static let Pink80 = UIColor(rgb: 0x7f145b)
        static let Pink90 = UIColor(rgb: 0x50134b)

        static let Orange05 = UIColor(rgb: 0xfff4de)
        static let Orange10 = UIColor(rgb: 0xffd5b2)
        static let Orange20 = UIColor(rgb: 0xffb587)
        static let Orange30 = UIColor(rgb: 0xffa266)
        static let Orange40 = UIColor(rgb: 0xff8a50)
        static let Orange50 = UIColor(rgb: 0xff7139)
        static let Orange60 = UIColor(rgb: 0xe25820)
        static let Orange70 = UIColor(rgb: 0xcc3d00)
        static let Orange80 = UIColor(rgb: 0x9e280b)
        static let Orange90 = UIColor(rgb: 0x7c1504)

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

        static let White100 = UIColor(rgb: 0xffffff)

        static let Grey10 = UIColor(rgb: 0xf9f9fb) // change to LightGrey10 - in the future, grey should be redefined into LightGrey and DarkGrey wherever possible
        static let Grey11 = UIColor(rgb: 0xf2f2f7) // system background / light / secondary
        static let Grey10A10 = UIColor(rgba: 0xf9f9fa19)
        static let Grey10A20 = UIColor(rgba: 0xf9f9fa33)
        static let Grey10A40 = UIColor(rgba: 0xf9f9fa66)
        static let Grey10A60 = UIColor(rgba: 0xf9f9fa99)
        static let Grey10A80 = UIColor(rgba: 0xf9f9facc)
        static let Grey12 = UIColor(rgb: 0xf7f7f8)
        static let Grey20 = UIColor(rgb: 0xededf0)
        static let Grey25 = UIColor(rgb: 0xe3e3e6)
        static let Grey30 = UIColor(rgb: 0xd7d7db)
        static let Grey40 = UIColor(rgb: 0xb1b1b3)
        static let Grey50 = UIColor(rgb: 0x737373)
        static let Grey60 = UIColor(rgb: 0x4a4a4f)
        static let Grey70 = UIColor(rgb: 0x38383d)
        static let Grey75 = UIColor(rgb: 0x3C3C43)
        static let Grey75A60 = UIColor(rgba: 0x3C3C4399)
        static let Grey75A39 = UIColor(rgba: 0x3C3C4363)
        static let Grey80 = UIColor(rgb: 0x2a2a2e)
        static let Grey85 = UIColor(rgb: 0x1C1C1e) // system background / dark / secondary
        static let Grey90 = UIColor(rgb: 0x0c0c0d)
        static let Grey90A05 = UIColor(rgba: 0x0c0c0d0c)
        static let Grey90A10 = UIColor(rgba: 0x0c0c0d19)
        static let Grey90A20 = UIColor(rgba: 0x0c0c0d33)
        static let Grey90A30 = UIColor(rgba: 0x0c0c0d4c)
        static let Grey90A40 = UIColor(rgba: 0x0c0c0d66)
        static let Grey90A50 = UIColor(rgba: 0x0c0c0d7f)
        static let Grey90A60 = UIColor(rgba: 0x0c0c0d99)
        static let Grey90A70 = UIColor(rgba: 0x0c0c0db2)
        static let Grey90A80 = UIColor(rgba: 0x0c0c0dcc)
        static let Grey90A90 = UIColor(rgba: 0x0c0c0de5)

        static let Magenta50 = UIColor(rgb: 0xff1ad9) // wherever possible, change magenta into pink and deprecate it
        static let Magenta60 = UIColor(rgb: 0xed00b5)
        static let Magenta60A30 = UIColor(rgba: 0xed00b54c)
        static let Magenta70 = UIColor(rgb: 0xb5007f)
        static let Magenta80 = UIColor(rgb: 0x7d004f)
        static let Magenta90 = UIColor(rgb: 0x440027)

        static let Teal50 = UIColor(rgb: 0x00feff) // wherever possible, change teal into violet and deprecate it
        static let Teal60 = UIColor(rgb: 0x00c8d7)
        static let Teal70 = UIColor(rgb: 0x008ea4)
        static let Teal80 = UIColor(rgb: 0x005a71)
        static let Teal90 = UIColor(rgb: 0x002d3e)
    }

    struct Pocket {
        static let red = UIColor(rgb: 0xEF4156)
    }

    struct Custom {
        static let selectedHighlightDark = UIColor.Photon.Grey60
        static let selectedHighlightLight = UIColor.Photon.LightGrey20
    }
}
