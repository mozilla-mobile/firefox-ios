/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SafariServices

typealias EnabledCallback = (Bool) -> Void

class BlockerEnabledDetector {
    func detectEnabled(_ parentView: UIView, callback: @escaping EnabledCallback) {
        SFContentBlockerManager.getStateOfContentBlocker(withIdentifier: AppInfo.contentBlockerBundleIdentifier) { state, error in
            DispatchQueue.main.async {
                guard let state = state else {
                    print("Detection error: \(error!.localizedDescription)")
                    callback(false)
                    return
                }

                callback(state.isEnabled)
            }
        }
    }
}
