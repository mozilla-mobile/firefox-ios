// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public struct LocationViewEditingAccessoryConfiguration {
    public let imageName: String
    public let a11yLabel: String
    public let onTap: @MainActor (UIView) -> Void

    public init(
        imageName: String,
        a11yLabel: String,
        onTap: @escaping @MainActor (UIView) -> Void
    ) {
        self.imageName = imageName
        self.a11yLabel = a11yLabel
        self.onTap = onTap
    }
}
