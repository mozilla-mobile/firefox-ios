/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

public struct SheetMetrics {
    public static let `default` = SheetMetrics()

    public let bufferHeight: CGFloat = 400
    public let cornerRadius: CGFloat = 10
    public let shadowRadius: CGFloat = 10
    public let shadowOpacity: CGFloat = 0.12

    public var maximumContainerHeight: CGFloat { UIScreen.main.bounds.height }
}
