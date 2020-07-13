/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import NotificationCenter
protocol TodayWidgetAppearanceDelegate {
    func updateCopiedLinkInView(clipboardURL: URL?)
}

class TodayWidgetViewModel {
    var AppearanceDelegate: TodayWidgetAppearanceDelegate?

    func setViewDelegate(todayViewDelegate: TodayWidgetAppearanceDelegate?) {
        self.AppearanceDelegate = todayViewDelegate
    }

    func updateCopiedLink() {
        UIPasteboard.general.asyncURL().uponQueue(.main) { res in
            guard let url: URL? = res.successValue else {
                TodayModel.copiedURL = nil
                self.AppearanceDelegate?.updateCopiedLinkInView(clipboardURL: nil)
                return
            }
            TodayModel.copiedURL = url
            self.AppearanceDelegate?.updateCopiedLinkInView(clipboardURL: url)
        }
    }
}
