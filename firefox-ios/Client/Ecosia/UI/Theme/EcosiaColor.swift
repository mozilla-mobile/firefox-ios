// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

// This class contains all of Ecosia official primitive color tokens referenced in the link below.
// https://www.figma.com/design/8T2rTBVwynJKSdY6MQo5PQ/%E2%9A%9B%EF%B8%8F--Foundations?node-id=1239-9385&t=UKHtrxcc9UtOihsm-4
// You should never call those colors directly, they should only be called from a theme within the theme manager.
// This is the equivalent to Firefox's `FXColors`.
struct EcosiaColor {
    // MARK: - Black & White
    static let Black = UIColor(rgb: 0x000000)
    static let White = UIColor(rgb: 0xFFFFFF)

    // MARK: - Neutral
    static let Gray10 = UIColor(rgb: 0xF8F8F6)
    static let Gray20 = UIColor(rgb: 0xF0F0EB)
    static let Gray30 = UIColor(rgb: 0xDEDED9)
    static let Gray40 = UIColor(rgb: 0xBEBEB9)
    static let Gray50 = UIColor(rgb: 0x6C6C6C)
    static let Gray60 = UIColor(rgb: 0x4C4C4C)
    static let Gray70 = UIColor(rgb: 0x333333)
    static let Gray80 = UIColor(rgb: 0x252525)
    static let Gray90 = UIColor(rgb: 0x1A1A1A)

    // MARK: - Grellow
    static let Grellow100 = UIColor(rgb: 0xD7EB80)
    static let Grellow200 = UIColor(rgb: 0xBBCF65)
    static let Grellow300 = UIColor(rgb: 0xA1B353)
    static let Grellow400 = UIColor(rgb: 0x889745)
    static let Grellow500 = UIColor(rgb: 0x6F7D38)
    static let Grellow600 = UIColor(rgb: 0x58632B)
    static let Grellow700 = UIColor(rgb: 0x424A1E)
    static let Grellow800 = UIColor(rgb: 0x2D3315)
    static let Grellow900 = UIColor(rgb: 0x1B1D0F)

    // MARK: - Green
    static let Green10 = UIColor(rgb: 0xCFF2D0)
    static let Green20 = UIColor(rgb: 0xAFE9B0)
    static let Green30 = UIColor(rgb: 0x5DD25E)
    static let Green40 = UIColor(rgb: 0xA4D24F)
    static let Green50 = UIColor(rgb: 0x008009)
    static let Green60 = UIColor(rgb: 0x007508)
    static let Green70 = UIColor(rgb: 0x006600)

    // MARK: - Dark Green
    static let DarkGreen30 = UIColor(rgb: 0x668A7A)
    static let DarkGreen50 = UIColor(rgb: 0x275243)
    static let DarkGreen70 = UIColor(rgb: 0x09281D)
    static let DarkGreen800 = UIColor(rgb: 0x18362B)

    // MARK: - Light Green
    static let LightGreen20 = UIColor(rgb: 0xBACC80)
    static let LightGreen30 = UIColor(rgb: 0xD8FF80)
    static let LightGreen40 = UIColor(rgb: 0xA4D24F)
    static let LightGreen50 = UIColor(rgb: 0x72A11A)
    static let LightGreen60 = UIColor(rgb: 0x40521F)

    // MARK: - Red
    static let Red20 = UIColor(rgb: 0xFFE8DA)
    static let Red30 = UIColor(rgb: 0xFF8A8C)
    static let Red40 = UIColor(rgb: 0xFD4256)
    static let Red50 = UIColor(rgb: 0xAF1731)

    // MARK: - Yellow
    static let Yellow40 = UIColor(rgb: 0xF7BC00)
    static let Yellow50 = UIColor(rgb: 0xD6A300)

    // MARK: - Blue
    static let Blue30 = UIColor(rgb: 0x96D6F8)
    static let Blue40 = UIColor(rgb: 0x0094C7)
    static let Blue50 = UIColor(rgb: 0x007EA8)
    static let Blue60 = UIColor(rgb: 0x005D87)
    static let Blue70 = UIColor(rgb: 0x004687)
    static let Blue80 = UIColor(rgb: 0x002A3D)

    // MARK: - Peach
    static let Peach30 = UIColor(rgb: 0xFFE6BF)
    static let Peach40 = UIColor(rgb: 0xFFAF87)
    static let Peach50 = UIColor(rgb: 0xCA8461)
}
