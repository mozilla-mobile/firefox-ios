/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import NotificationCenter

protocol TodayWidgetAppearanceDelegate {
    func updateCopiedLinkInView(clipboardURL: URL?)
}

class TodayWidgetViewModel {

<<<<<<< HEAD
    var AppearanceDelegate: TodayWidgetAppearanceDelegate?

    
=======
    var widgetModel: TodayModel?
    var AppearanceDelegate: TodayWidgetAppearanceDelegate?

    init() {
        intializeModel()
    }

    func intializeModel() {
        self.widgetModel = TodayModel(copiedURL: nil)
    }

>>>>>>> 3c460f1a9... added ViewModel and Model files to widget extension and re-architect the widget
    func setViewDelegate(todayViewDelegate:TodayWidgetAppearanceDelegate?) {
        self.AppearanceDelegate = todayViewDelegate
    }

    func updateCopiedLink() {
            UIPasteboard.general.asyncURL().uponQueue(.main) { res in
                if let URL: URL? = res.successValue,
                    let url = URL {
<<<<<<< HEAD
                    TodayModel.copiedURL = url
                    self.AppearanceDelegate?.updateCopiedLinkInView(clipboardURL: url)
                } else {
                    TodayModel.copiedURL = nil
=======
                    self.widgetModel?.copiedURL = url
                    self.AppearanceDelegate?.updateCopiedLinkInView(clipboardURL: url)
                } else {
                    self.widgetModel?.copiedURL = nil
>>>>>>> 3c460f1a9... added ViewModel and Model files to widget extension and re-architect the widget
                    self.AppearanceDelegate?.updateCopiedLinkInView(clipboardURL: nil)
                }
            }
        }
}
