// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// Represents a shadow configuration with blur radius, offset, opacity, and theme-aware color.
public struct FxShadow {
    /// The blur radius of the shadow
    public let blurRadius: CGFloat

    /// The offset of the shadow
    public let offset: CGSize

    /// The opacity of the shadow (0.0 to 1.0)
    public let opacity: Float

    /// A closure that returns the shadow color based on the theme palette
    public let colorProvider: @Sendable (Theme) -> UIColor

    /// Initializes a new FxShadow
    /// - Parameters:
    ///   - blurRadius: The blur radius of the shadow
    ///   - offset: The offset of the shadow
    ///   - opacity: The opacity of the shadow (0.0 to 1.0)
    ///   - colorProvider: A closure that returns the shadow color based on the theme palette
    public init(
        blurRadius: CGFloat,
        offset: CGSize,
        opacity: Float,
        colorProvider: @Sendable @escaping (Theme) -> UIColor
    ) {
        self.blurRadius = blurRadius
        self.offset = offset
        self.opacity = opacity
        self.colorProvider = colorProvider
    }

    // MARK: - Predefined Shadows

    @MainActor
    public static let shadow200 = FxShadow(
        blurRadius: 14,
        offset: CGSize(width: 0, height: 2),
        opacity: 1.0,
        colorProvider: { $0.colors.shadowStrong }
    )
}
