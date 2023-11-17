// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol NTPTooltipDelegate: AnyObject {
    func ntpTooltipTapped(_ tooltip: NTPTooltip?)
    func ntpTooltipCloseTapped(_ tooltip: NTPTooltip?)
    func ntpTooltipLinkTapped(_ tooltip: NTPTooltip?)
    func reloadTooltip()
}

extension NTPTooltipDelegate {
    func reloadTooltip() {}
    func ntpTooltipLinkTapped(_ tooltip: NTPTooltip?) {}
}
