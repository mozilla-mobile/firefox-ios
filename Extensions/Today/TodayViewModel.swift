/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import NotificationCenter
protocol TodayWidgetAppearanceDelegate {
    func openContainingApp(_ urlSuffix: String, query: String)
}

class TodayWidgetViewModel {
    var AppearanceDelegate: TodayWidgetAppearanceDelegate?

    func setViewDelegate(todayViewDelegate: TodayWidgetAppearanceDelegate?) {
        self.AppearanceDelegate = todayViewDelegate
    }

    func updateCopiedLink() {
        if !UIPasteboard.general.hasURLs {
            guard let searchText = UIPasteboard.general.string else {
                TodayModel.searchedText = nil
                return
            }
            TodayModel.searchedText = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            self.AppearanceDelegate?.openContainingApp("?text=\(TodayModel.searchedText ?? "")", query: "text")
        } else {
            UIPasteboard.general.asyncURL().uponQueue(.main) { res in
                guard let url: URL? = res.successValue else {
                    TodayModel.copiedURL = nil
                    return
                }
                TodayModel.copiedURL = url
                self.AppearanceDelegate?.openContainingApp("?url=\(TodayModel.copiedURL?.absoluteString.escape() ?? "")", query: "url")
            }
        }
    }
}

