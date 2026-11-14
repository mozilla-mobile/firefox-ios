// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// Stores sRGB RGBA values for light and dark appearances.
struct CodableColor: Codable, Equatable, Sendable {
    private struct Components: Codable, Equatable, Sendable {
        let red: Double
        let green: Double
        let blue: Double
        let alpha: Double

        var uiColor: UIColor {
            UIColor(cgColor: CGColor(srgbRed: red, green: green, blue: blue, alpha: alpha))
        }
    }

    private let light: Components
    private let dark: Components?

    init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        light = Components(red: red, green: green, blue: blue, alpha: alpha)
        dark = nil
    }

    init?(uiColor: UIColor) {
        guard let light = Self.components(of: uiColor.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))),
              let dark = Self.components(of: uiColor.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)))
        else { return nil }

        self.light = light
        self.dark = dark == light ? nil : dark
    }

    var uiColor: UIColor {
        guard let dark else { return light.uiColor }
        return UIColor { [light] traits in
            (traits.userInterfaceStyle == .dark ? dark : light).uiColor
        }
    }

    private static func components(of color: UIColor) -> Components? {
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let converted = color.cgColor.converted(to: colorSpace, intent: .defaultIntent, options: nil),
              let components = converted.components,
              components.count == 4 else { return nil }

        return Components(red: Double(components[0]),
                          green: Double(components[1]),
                          blue: Double(components[2]),
                          alpha: Double(components[3]))
    }
}
