// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol SettingsDelegate: AnyObject {
    func scrollToTop()
    func showFindInPage()
    func switchToStrictTrackingProtection()
    func switchToStandardTrackingProtection()
    func disableTrackingProtection()
    func toggleNoImageMode()
    func increaseZoom()
    func decreaseZoom()
    func resetZoom()
    func setZoom(_ value: CGFloat)
}
