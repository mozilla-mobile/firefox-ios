// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

protocol URLBarDelegate: AnyObject {
    func urlBar(_ urlBar: URLBar, didEnterText text: String)
    func urlBar(_ urlBar: URLBar, didSubmitText text: String, source: Source)
    func urlBar(_ urlBar: URLBar, didAddCustomURL url: URL)
    func urlBarDidActivate(_ urlBar: URLBar)
    func urlBarDidDeactivate(_ urlBar: URLBar)
    func urlBarDidFocus(_ urlBar: URLBar)
    func urlBarDidPressScrollTop(_: URLBar, tap: UITapGestureRecognizer)
    func urlBarDidDismiss(_ urlBar: URLBar)
    func urlBarDidTapShield(_ urlBar: URLBar)
    func urlBarDidLongPress(_ urlBar: URLBar)
    func urlBarDisplayTextForURL(_ url: URL?) -> (String?, Bool)
}
