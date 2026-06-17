// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

// This class contains Nova design system color primitives.
// These should never be called directly; they should only be used from a Nova theme.
final class NovaColors {
    // MARK: - Black & White
    static let Black = UIColor(rgb: 0x000000)
    static let White = UIColor(rgb: 0xffffff)

    // MARK: - Gray
    static let Gray0 = UIColor(rgb: 0xfcfbff)
    static let Gray5 = UIColor(rgb: 0xf7f6fb)
    static let Gray10 = UIColor(rgb: 0xefedf2)
    static let Gray15 = UIColor(rgb: 0xe3e2e7)
    static let Gray20 = UIColor(rgb: 0xd6d5da)
    static let Gray25 = UIColor(rgb: 0xc7c6cb)
    static let Gray30 = UIColor(rgb: 0xb7b6ba)
    static let Gray35 = UIColor(rgb: 0xa6a4a9)
    static let Gray40 = UIColor(rgb: 0x949297)
    static let Gray45 = UIColor(rgb: 0x817f84)
    static let Gray50 = UIColor(rgb: 0x67666a)
    static let Gray55 = UIColor(rgb: 0x515054)
    static let Gray60 = UIColor(rgb: 0x3f3e42)
    static let Gray65 = UIColor(rgb: 0x312f33)
    static let Gray70 = UIColor(rgb: 0x252428)
    static let Gray75 = UIColor(rgb: 0x1d1b1f)
    static let Gray80 = UIColor(rgb: 0x171519)
    static let Gray85 = UIColor(rgb: 0x131215)
    static let Gray90 = UIColor(rgb: 0x121114)

    // MARK: - Violet Desaturated
    static let VioletDesaturated0 = UIColor(rgb: 0xf2f0f8)
    static let VioletDesaturated10 = UIColor(rgb: 0xe2dcf2)
    static let VioletDesaturated20 = UIColor(rgb: 0xcac1e4)
    static let VioletDesaturated30 = UIColor(rgb: 0xb0a3d2)
    static let VioletDesaturated40 = UIColor(rgb: 0x9484bd)
    static let VioletDesaturated50 = UIColor(rgb: 0x75669f)
    static let VioletDesaturated60 = UIColor(rgb: 0x584a7d)
    static let VioletDesaturated70 = UIColor(rgb: 0x3e315f)
    static let VioletDesaturated80 = UIColor(rgb: 0x281d44)
    static let VioletDesaturated90 = UIColor(rgb: 0x180e30)

    // MARK: - Violet
    static let Violet0 = UIColor(rgb: 0xf5ecff)
    static let Violet10 = UIColor(rgb: 0xe5d6ff)
    static let Violet20 = UIColor(rgb: 0xcdb7ff)
    static let Violet30 = UIColor(rgb: 0xb393ff)
    static let Violet40 = UIColor(rgb: 0x956eff)
    static let Violet50 = UIColor(rgb: 0x764edd)
    static let Violet60 = UIColor(rgb: 0x5939a8)
    static let Violet70 = UIColor(rgb: 0x3e2976)
    static let Violet80 = UIColor(rgb: 0x271c48)
    static let Violet90 = UIColor(rgb: 0x161423)

    // MARK: - Purple
    static let Purple0 = UIColor(rgb: 0xfaebff)
    static let Purple10 = UIColor(rgb: 0xf1d0ff)
    static let Purple20 = UIColor(rgb: 0xe1afff)
    static let Purple30 = UIColor(rgb: 0xcd89fc)
    static let Purple40 = UIColor(rgb: 0xb561eb)
    static let Purple50 = UIColor(rgb: 0x9540c8)
    static let Purple60 = UIColor(rgb: 0x702e98)
    static let Purple70 = UIColor(rgb: 0x4f216b)
    static let Purple80 = UIColor(rgb: 0x311842)
    static let Purple90 = UIColor(rgb: 0x1a1220)

    // MARK: - Pink
    static let Pink0 = UIColor(rgb: 0xffeaf5)
    static let Pink10 = UIColor(rgb: 0xffcbea)
    static let Pink20 = UIColor(rgb: 0xffa5dc)
    static let Pink30 = UIColor(rgb: 0xf07dcd)
    static let Pink40 = UIColor(rgb: 0xd851bc)
    static let Pink50 = UIColor(rgb: 0xb32e9f)
    static let Pink60 = UIColor(rgb: 0x882078)
    static let Pink70 = UIColor(rgb: 0x5f1854)
    static let Pink80 = UIColor(rgb: 0x3c1334)
    static let Pink90 = UIColor(rgb: 0x1e111b)

    // MARK: - Red
    static let Red0 = UIColor(rgb: 0xffebe6)
    static let Red10 = UIColor(rgb: 0xffd0d7)
    static let Red20 = UIColor(rgb: 0xffa9b5)
    static let Red30 = UIColor(rgb: 0xff8090)
    static let Red40 = UIColor(rgb: 0xeb526b)
    static let Red50 = UIColor(rgb: 0xc52d4f)
    static let Red60 = UIColor(rgb: 0x961e3d)
    static let Red70 = UIColor(rgb: 0x69172d)
    static let Red80 = UIColor(rgb: 0x42121f)
    static let Red90 = UIColor(rgb: 0x211014)

    // MARK: - Orange
    static let Orange0 = UIColor(rgb: 0xffede0)
    static let Orange10 = UIColor(rgb: 0xffd4b7)
    static let Orange20 = UIColor(rgb: 0xfeb48c)
    static let Orange30 = UIColor(rgb: 0xff8f5d)
    static let Orange40 = UIColor(rgb: 0xf5672b)
    static let Orange50 = UIColor(rgb: 0xd24300)
    static let Orange60 = UIColor(rgb: 0xa02d02)
    static let Orange70 = UIColor(rgb: 0x711d08)
    static let Orange80 = UIColor(rgb: 0x47130a)
    static let Orange90 = UIColor(rgb: 0x250e0b)

    // MARK: - Yellow
    static let Yellow0 = UIColor(rgb: 0xfff9e2)
    static let Yellow10 = UIColor(rgb: 0xfae2a7)
    static let Yellow20 = UIColor(rgb: 0xf6c465)
    static let Yellow30 = UIColor(rgb: 0xf0a000)
    static let Yellow40 = UIColor(rgb: 0xd7800e)
    static let Yellow50 = UIColor(rgb: 0xb26100)
    static let Yellow60 = UIColor(rgb: 0x854800)
    static let Yellow70 = UIColor(rgb: 0x5f3100)
    static let Yellow80 = UIColor(rgb: 0x3e1d00)
    static let Yellow90 = UIColor(rgb: 0x270f00)

    // MARK: - Green
    static let Green0 = UIColor(rgb: 0xe8f7e5)
    static let Green10 = UIColor(rgb: 0xb8eed9)
    static let Green20 = UIColor(rgb: 0x7fddbd)
    static let Green30 = UIColor(rgb: 0x2dc79e)
    static let Green40 = UIColor(rgb: 0x00ab81)
    static let Green50 = UIColor(rgb: 0x008865)
    static let Green60 = UIColor(rgb: 0x06674b)
    static let Green70 = UIColor(rgb: 0x004933)
    static let Green80 = UIColor(rgb: 0x003020)
    static let Green90 = UIColor(rgb: 0x001e12)

    // MARK: - Cyan
    static let Cyan0 = UIColor(rgb: 0xe7f5f7)
    static let Cyan10 = UIColor(rgb: 0xbae9f3)
    static let Cyan20 = UIColor(rgb: 0x85d6e9)
    static let Cyan30 = UIColor(rgb: 0x41bdda)
    static let Cyan40 = UIColor(rgb: 0x00a1c7)
    static let Cyan50 = UIColor(rgb: 0x0a809f)
    static let Cyan60 = UIColor(rgb: 0x066077)
    static let Cyan70 = UIColor(rgb: 0x034554)
    static let Cyan80 = UIColor(rgb: 0x002d38)
    static let Cyan90 = UIColor(rgb: 0x011c23)

    // MARK: - Blue
    static let Blue0 = UIColor(rgb: 0xe1f5ff)
    static let Blue10 = UIColor(rgb: 0xbae5ff)
    static let Blue20 = UIColor(rgb: 0x95cbfe)
    static let Blue30 = UIColor(rgb: 0x70abff)
    static let Blue40 = UIColor(rgb: 0x5583ff)
    static let Blue50 = UIColor(rgb: 0x455fe7)
    static let Blue60 = UIColor(rgb: 0x3246b0)
    static let Blue70 = UIColor(rgb: 0x23327b)
    static let Blue80 = UIColor(rgb: 0x17214c)
    static let Blue90 = UIColor(rgb: 0x111524)
}
