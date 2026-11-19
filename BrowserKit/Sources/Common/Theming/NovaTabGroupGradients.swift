// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

enum NovaTabGroupGradients {
    private static var lightNeutralStop: UIColor { UIColor(rgb: 0x14092b).withAlphaComponent(0.7) }
    private static var darkNeutralStop: UIColor { NovaColors.VioletDesaturated0.withAlphaComponent(0.7) }

    static var yellow: Gradient {
        Gradient(colors: [NovaColors.Yellow40, NovaColors.Yellow50])
    }

    static var orange: Gradient {
        Gradient(colors: [NovaColors.Orange40, NovaColors.Orange50])
    }

    static var red: Gradient {
        Gradient(colors: [NovaColors.Red40, NovaColors.Red50])
    }

    static var pink: Gradient {
        Gradient(colors: [NovaColors.Pink40, NovaColors.Pink50])
    }

    static var purple: Gradient {
        Gradient(colors: [NovaColors.Violet40, NovaColors.Violet50])
    }

    static var blue: Gradient {
        Gradient(colors: [NovaColors.Blue40, NovaColors.Blue50])
    }

    static var cyan: Gradient {
        Gradient(colors: [NovaColors.Cyan40, NovaColors.Cyan50])
    }

    static var green: Gradient {
        Gradient(colors: [NovaColors.Green40, NovaColors.Green50])
    }

    static var lightGrey: Gradient {
        Gradient(colors: [lightNeutralStop, NovaColors.Gray50])
    }

    static var darkGrey: Gradient {
        Gradient(colors: [darkNeutralStop, NovaColors.Gray40])
    }

    static var lightNoColor: Gradient {
        Gradient(colors: [lightNeutralStop, NovaColors.VioletDesaturated90])
    }

    static var darkNoColor: Gradient {
        Gradient(colors: [darkNeutralStop, NovaColors.VioletDesaturated0])
    }
}
