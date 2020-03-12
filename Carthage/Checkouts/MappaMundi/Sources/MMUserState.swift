/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

open class MMUserState: NSObject {
    public required override init() {}
    public var initialScreenState: String?
    public var isTablet: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
}
