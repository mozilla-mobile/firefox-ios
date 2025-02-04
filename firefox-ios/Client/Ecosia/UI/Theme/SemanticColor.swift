// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

// TODO: Remove this file once migrated to `EcosiaSemanticColors` inside `EcosiaThemeColourPalette`

// This file contains all of Ecosia official semantic color tokens referenced in the link below.
// https://www.figma.com/design/8T2rTBVwynJKSdY6MQo5PQ/%E2%9A%9B%EF%B8%8F--Foundations?node-id=2237-3418&t=UKHtrxcc9UtOihsm-0
// They should use `EcosiaColorPrimitives` and should be called from a theme within the theme manager.
extension UIColor {
    struct Light {
        struct Background {
            static let primary = EcosiaColor.White
            static let secondary = EcosiaColor.Gray10
            static let tertiary = EcosiaColor.Gray20
            static let quarternary = EcosiaColor.DarkGreen50
            static let highlighted = EcosiaColor.Green10 // ⚠️ No match
        }

        struct Brand {
            static let primary = EcosiaColor.Green50
        }

        struct Border {
            static let decorative = EcosiaColor.Gray30
        }

        struct Button {
            static let backgroundPrimary = EcosiaColor.Green50
            static let backgroundPrimaryActive = EcosiaColor.Green70 // ⚠️ Mismatch
            static let backgroundSecondary = EcosiaColor.White
            static let backgroundSecondaryHover = EcosiaColor.Gray10 // ⚠️ Mismatch
            static let contentSecondary = EcosiaColor.Gray70
            static let secondaryBackground = EcosiaColor.Gray10 // ⚠️ Mismatch & duplicate
            static let backgroundTransparentActive = EcosiaColor.Green70.withAlphaComponent(0.24)
        }

        struct Icon {
            static let primary = EcosiaColor.Black // ⚠️ Mobile snowflake & mismatch
            static let secondary = EcosiaColor.Green60 // ⚠️ Mobile snowflake & mismatch
            static let decorative = EcosiaColor.Gray50 // ⚠️ Mobile snowflake
        }

        struct State {
            static let error = EcosiaColor.Red40 // ⚠️ Mobile snowflake
            static let information = EcosiaColor.Blue50 // ⚠️ No match
            static let disabled = EcosiaColor.Gray30
        }

        struct Text {
            static let primary = EcosiaColor.Black // ⚠️ Mismatch
            static let secondary = EcosiaColor.Gray50
            static let tertiary = EcosiaColor.White
        }
    }

    struct Dark {
        struct Background {
            static let primary = EcosiaColor.Gray90
            static let secondary = EcosiaColor.Gray80
            static let tertiary = EcosiaColor.Gray70
            static let quarternary = EcosiaColor.Green20
            static let highlighted = EcosiaColor.DarkGreen30 // ⚠️ No match
        }

        struct Brand {
            static let primary = EcosiaColor.Green30
        }

        struct Border {
            static let decorative = EcosiaColor.Gray60
        }

        struct Button {
            static let backgroundPrimary = EcosiaColor.Green30
            static let backgroundPrimaryActive = EcosiaColor.Green50 // ⚠️ Mismatch
            static let backgroundSecondary = EcosiaColor.Gray70 // ⚠️ Mismatch
            static let backgroundSecondaryHover = EcosiaColor.Gray70
            static let contentSecondary = EcosiaColor.White
            static let secondaryBackground = EcosiaColor.Gray80 // ⚠️ Mismatch & duplicate
            static let backgroundTransparentActive = EcosiaColor.Gray30.withAlphaComponent(0.32)
        }

        struct Icon {
            static let primary = EcosiaColor.White // ⚠️ Mobile snowflake
            static let secondary = EcosiaColor.Green30 // ⚠️ Mobile snowflake
            static let decorative = EcosiaColor.Gray40 // ⚠️ Mobile snowflake & mismatch
        }

        struct State {
            static let error = EcosiaColor.Red30 // ⚠️ Mobile snowflake
            static let information = EcosiaColor.Blue30 // ⚠️ No match
            static let disabled = EcosiaColor.Gray50
        }

        struct Text {
            static let primary = EcosiaColor.White
            static let secondary = EcosiaColor.Gray30
            static let tertiary = EcosiaColor.Gray70 // ⚠️ Mismatch
        }
    }

    struct Grey {
        static let fifty = EcosiaColor.Gray50
    }
}
