/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* Photon Colors iOS Variables v3.3.1
 From https://github.com/FirefoxUX/photon-colors/#readme */
import UIKit

// Used as backgrounds for favicons
public let DefaultFaviconBackgroundColors = ["2e761a", "399320", "40a624", "57bd35", "70cf5b", "90e07f", "b1eea5", "881606", "aa1b08", "c21f09", "d92215", "ee4b36", "f67964", "ffa792", "025295", "0568ba", "0675d3", "0996f8", "2ea3ff", "61b4ff", "95cdff", "00736f", "01908b", "01a39d", "01bdad", "27d9d2", "58e7e6", "89f4f5", "c84510", "e35b0f", "f77100", "ff9216", "ffad2e", "ffc446", "ffdf81", "911a2e", "b7223b", "cf2743", "ea385e", "fa526e", "ff7a8d", "ffa7b3" ]

extension UIColor {
    struct Photon {
        static let Magenta50 = UIColor(rgb: 0xff1ad9)
        static let Magenta60 = UIColor(rgb: 0xed00b5)
        static let Magenta60A30 = UIColor(rgba: 0xed00b54c)
        static let Magenta70 = UIColor(rgb: 0xb5007f)
        static let Magenta80 = UIColor(rgb: 0x7d004f)
        static let Magenta90 = UIColor(rgb: 0x440027)

        static let Purple30 = UIColor(rgb: 0xc069ff)
        static let Purple40 = UIColor(rgb: 0xad3bff)
        static let Purple50 = UIColor(rgb: 0x9400ff)
        static let Purple60 = UIColor(rgb: 0x8000d7)
        static let Purple70 = UIColor(rgb: 0x6200a4)
        static let Purple80 = UIColor(rgb: 0x440071)
        static let Purple90 = UIColor(rgb: 0x25003e)

        static let Blue40 = UIColor(rgb: 0x45a1ff)
        static let Blue40A30 = UIColor(rgba: 0x45a1ff4c)
        static let Blue50 = UIColor(rgb: 0x0a84ff)
        static let Blue60 = UIColor(rgb: 0x0060df)
        static let Blue70 = UIColor(rgb: 0x003eaa)
        static let Blue80 = UIColor(rgb: 0x002275)
        static let Blue90 = UIColor(rgb: 0x000f40)

        static let Teal50 = UIColor(rgb: 0x00feff)
        static let Teal60 = UIColor(rgb: 0x00c8d7)
        static let Teal70 = UIColor(rgb: 0x008ea4)
        static let Teal80 = UIColor(rgb: 0x005a71)
        static let Teal90 = UIColor(rgb: 0x002d3e)

        static let Green50 = UIColor(rgb: 0x30e60b)
        static let Green60 = UIColor(rgb: 0x12bc00)
        static let Green70 = UIColor(rgb: 0x058b00)
        static let Green80 = UIColor(rgb: 0x006504)
        static let Green90 = UIColor(rgb: 0x003706)

        static let Yellow50 = UIColor(rgb: 0xffe900)
        static let Yellow60 = UIColor(rgb: 0xd7b600)
        static let Yellow70 = UIColor(rgb: 0xa47f00)
        static let Yellow80 = UIColor(rgb: 0x715100)
        static let Yellow90 = UIColor(rgb: 0x3e2800)

        static let Red50 = UIColor(rgb: 0xff0039)
        static let Red60 = UIColor(rgb: 0xd70022)
        static let Red70 = UIColor(rgb: 0xa4000f)
        static let Red80 = UIColor(rgb: 0x5a0002)
        static let Red90 = UIColor(rgb: 0x3e0200)

        static let Orange50 = UIColor(rgb: 0xff9400)
        static let Orange60 = UIColor(rgb: 0xd76e00)
        static let Orange70 = UIColor(rgb: 0xa44900)
        static let Orange80 = UIColor(rgb: 0x712b00)
        static let Orange90 = UIColor(rgb: 0x3e1300)

        static let Grey10 = UIColor(rgb: 0xf9f9fa)
        static let Grey10A10 = UIColor(rgba: 0xf9f9fa19)
        static let Grey10A20 = UIColor(rgba: 0xf9f9fa33)
        static let Grey10A40 = UIColor(rgba: 0xf9f9fa66)
        static let Grey10A60 = UIColor(rgba: 0xf9f9fa99)
        static let Grey10A80 = UIColor(rgba: 0xf9f9facc)
        static let Grey20 = UIColor(rgb: 0xededf0)
        static let Grey25 = UIColor(rgb: 0xe3e3e6)
        static let Grey30 = UIColor(rgb: 0xd7d7db)
        static let Grey40 = UIColor(rgb: 0xb1b1b3)
        static let Grey50 = UIColor(rgb: 0x737373)
        static let Grey60 = UIColor(rgb: 0x4a4a4f)
        static let Grey70 = UIColor(rgb: 0x38383d)
        static let Grey80 = UIColor(rgb: 0x2a2a2e)
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

        static let Ink40 = UIColor(rgb: 0x7175A8)
        static let Ink50 = UIColor(rgb: 0x595E91)
        static let Ink60 = UIColor(rgb: 0x464B76)
        static let Ink70 = UIColor(rgb: 0x363959)
        static let Ink80 = UIColor(rgb: 0x202340)
        static let Ink90 = UIColor(rgb: 0x1D1133)

        static let White100 = UIColor(rgb: 0xffffff)

    }

    struct Pocket {
        static let red = UIColor(rgb: 0xEF4156)
    }
    
    struct Custom {
        static let selectedHighlightDark = UIColor(rgb: 0x2D2D2D)
        static let selectedHighlightLight = UIColor(rgb: 0xd1d1d6)
    }
}
