//
//  TodayViewModel.swift
//  Client
//
//  Created by McNoor's  on 6/10/20.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import Foundation
import NotificationCenter


protocol TodayWidgetAppearanceDelegate {
    func updateCopiedLinkInView(clipboardURL: URL?)
}

class TodayWidgetViewModel {

    var widgetModel : TodayModel?
    var AppearanceDelegate : TodayWidgetAppearanceDelegate?

    init() {
        intializeModel()
    }
    
    func intializeModel(){
        widgetModel = TodayModel(copiedURL: nil)
    }
    
    
    func setViewDelegate(todayViewDelegate:TodayWidgetAppearanceDelegate?){
        self.AppearanceDelegate = todayViewDelegate
    }

    
    func updateCopiedLink() {
            UIPasteboard.general.asyncURL().uponQueue(.main) { res in
                if let URL: URL? = res.successValue,
                    let url = URL {
                    self.widgetModel?.copiedURL = url
                    self.AppearanceDelegate?.updateCopiedLinkInView(clipboardURL: self.widgetModel?.copiedURL)
                } else {
                    self.widgetModel?.copiedURL = nil
                    self.AppearanceDelegate?.updateCopiedLinkInView(clipboardURL: self.widgetModel?.copiedURL)
                }
            }
        }
    
    
    
    
}
