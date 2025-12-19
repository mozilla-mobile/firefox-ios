// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

// This class contains all of Ecosia official primitive color tokens referenced in the link below.
// https://www.figma.com/design/8T2rTBVwynJKSdY6MQo5PQ/%E2%9A%9B%EF%B8%8F--Foundations?node-id=1239-9385&t=UKHtrxcc9UtOihsm-4
// You should never call those colors directly, they should only be called from a theme within the theme manager.
// This is the equivalent to Firefox's `FXColors`.
public struct EcosiaColor {
    // MARK: - Black & White
    public static let Black = UIColor(rgb: 0x000000)
    public static let White = UIColor(rgb: 0xFFFFFF)

    // MARK: - Neutral
    public static let Gray10 = UIColor(rgb: 0xF8F8F6)
    public static let Gray20 = UIColor(rgb: 0xF0F0EB)
    public static let Gray30 = UIColor(rgb: 0xDEDED9)
    public static let Gray40 = UIColor(rgb: 0xBEBEB9)
    public static let Gray50 = UIColor(rgb: 0x6C6C6C)
    public static let Gray60 = UIColor(rgb: 0x4C4C4C)
    public static let Gray70 = UIColor(rgb: 0x333333)
    public static let Gray80 = UIColor(rgb: 0x252525)
    public static let Gray90 = UIColor(rgb: 0x1A1A1A)

    // MARK: - Grellow
    public static let Grellow100 = UIColor(rgb: 0xD7EB80)
    public static let Grellow200 = UIColor(rgb: 0xBBCF65)
    public static let Grellow300 = UIColor(rgb: 0xA1B353)
    public static let Grellow400 = UIColor(rgb: 0x889745)
    public static let Grellow500 = UIColor(rgb: 0x6F7D38)
    public static let Grellow600 = UIColor(rgb: 0x58632B)
    public static let Grellow700 = UIColor(rgb: 0x424A1E)
    public static let Grellow800 = UIColor(rgb: 0x2D3315)
    public static let Grellow900 = UIColor(rgb: 0x1B1D0F)

    // MARK: - Green
    public static let Green10 = UIColor(rgb: 0xCFF2D0)
    public static let Green20 = UIColor(rgb: 0xAFE9B0)
    public static let Green30 = UIColor(rgb: 0x5DD25E)
    public static let Green40 = UIColor(rgb: 0xA4D24F)
    public static let Green50 = UIColor(rgb: 0x008009)
    public static let Green60 = UIColor(rgb: 0x007508)
    public static let Green70 = UIColor(rgb: 0x006600)

    // MARK: - Dark Green
    public static let DarkGreen30 = UIColor(rgb: 0x668A7A)
    public static let DarkGreen50 = UIColor(rgb: 0x275243)
    public static let DarkGreen70 = UIColor(rgb: 0x09281D)
    public static let DarkGreen800 = UIColor(rgb: 0x18362B)

    // MARK: - Light Green
    public static let LightGreen20 = UIColor(rgb: 0xBACC80)
    public static let LightGreen30 = UIColor(rgb: 0xD8FF80)
    public static let LightGreen40 = UIColor(rgb: 0xA4D24F)
    public static let LightGreen50 = UIColor(rgb: 0x72A11A)
    public static let LightGreen60 = UIColor(rgb: 0x40521F)

    // MARK: - Red
    public static let Red20 = UIColor(rgb: 0xFFE8DA)
    public static let Red30 = UIColor(rgb: 0xFF8A8C)
    public static let Red40 = UIColor(rgb: 0xFD4256)
    public static let Red50 = UIColor(rgb: 0xAF1731)

    // MARK: - Yellow
    public static let Yellow40 = UIColor(rgb: 0xF7BC00)
    public static let Yellow50 = UIColor(rgb: 0xD6A300)

    // MARK: - Blue
    public static let Blue30 = UIColor(rgb: 0x96D6F8)
    public static let Blue40 = UIColor(rgb: 0x0094C7)
    public static let Blue50 = UIColor(rgb: 0x007EA8)
    public static let Blue60 = UIColor(rgb: 0x005D87)
    public static let Blue70 = UIColor(rgb: 0x004687)
    public static let Blue80 = UIColor(rgb: 0x002A3D)

    // MARK: - Peach
    public static let Peach30 = UIColor(rgb: 0xFFE6BF)
    public static let Peach40 = UIColor(rgb: 0xFFAF87)
    public static let Peach50 = UIColor(rgb: 0xCA8461)
    public static let Peach100 = UIColor(rgb: 0xFCDBCC)
    public static let Peach700 = UIColor(rgb: 0x77300A)

    // MARK: - Claret
    public static let Claret300 = UIColor(rgb: 0xD89AA6)
    public static let Claret600 = UIColor(rgb: 0x8F4759)
    public static let Claret800 = UIColor(rgb: 0x4C232D)
}
