// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import UIKit

enum CFRTelemetryEvent {
    case closeButton
    case tapToDismiss
    case performAction
}

enum ContextualHintViewType: String {
    typealias ContextualHints = String.ContextualHints.FirefoxHomepage
    
    case jumpBackIn = "JumpBackIn"
//    case inactiveTabs
    
    func descriptionForHint() -> String {
        switch self {
        case .jumpBackIn:
            return ContextualHints.JumpBackIn.PersonalizedHome
//        case .inactiveTabs:
//            return ContextualHints.TabsTray.InactiveTabs.Body
        }
    }
}

class ContextualHintViewModel {

    // MARK: - Properties
    var hintType: ContextualHintViewType
    private var profile: Profile
    private var hasSentDismissEvent = false
    
    var hasAlreadyBeenPresented: Bool {
        guard let contextualHintData = profile.prefs.boolForKey(prefsKey) else {
            return false
        }
        
        return contextualHintData
    }
    
    // Do not present contextual hint in landscape on iPhone
    private var isDeviceHintReady: Bool {
        !UIWindow.isLandscape || UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private var prefsKey: String {
        switch hintType {
        case .jumpBackIn:
            return PrefsKeys.ContextualHints.JumpBackinKey
        }
    }
    
    // MARK: - Initializers
    init(forHintType hintType: ContextualHintViewType, with profile: Profile) {
        self.hintType = hintType
        self.profile = profile
    }
    
    // MARK: - Interface
    func shouldPresentContextualHint() -> Bool {
        guard isDeviceHintReady else { return false }
        return !hasAlreadyBeenPresented
    }
    
    func markContextualHintPresented() {
        profile.prefs.setBool(true, forKey: prefsKey)
    }
    
    // MARK: - Telemetry
    func sendTelemetryEvent(for eventType: CFRTelemetryEvent) {
        let extra = [TelemetryWrapper.EventExtraKey.cfrType.rawValue: hintType.rawValue]
        
        switch eventType {
        case .closeButton:
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .contextualHint,
                                         value: .dismissCFRFromButton,
                                         extras: extra)
            hasSentDismissEvent = true
        case .tapToDismiss:
            if hasSentDismissEvent { return }
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .contextualHint,
                                         value: .dismissCFRFromOutsideTap,
                                         extras: extra)
        case .performAction:
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .contextualHint,
                                         value: .pressCFRActionButton,
                                         extras: extra)
        }
    }
}
