/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import NotificationCenter

protocol TodayWidgetAppearanceDelegate {
    func updateCopiedLinkInView(clipboardURL: URL?)
}

class TodayWidgetViewModel {

    var widgetModel: TodayModel?
    var AppearanceDelegate: TodayWidgetAppearanceDelegate?

    init() {
        intializeModel()
    }

    func intializeModel() {
        self.widgetModel = TodayModel(copiedURL: nil)
    }

    func setViewDelegate(todayViewDelegate:TodayWidgetAppearanceDelegate?) {
        self.AppearanceDelegate = todayViewDelegate
    }

    func updateCopiedLink() {
            UIPasteboard.general.asyncURL().uponQueue(.main) { res in
                if let URL: URL? = res.successValue,
                    let url = URL {
                    self.widgetModel?.copiedURL = url
                    self.AppearanceDelegate?.updateCopiedLinkInView(clipboardURL: url)
                } else {
                    self.widgetModel?.copiedURL = nil
                    self.AppearanceDelegate?.updateCopiedLinkInView(clipboardURL: nil)
                }
            }
        }
}
