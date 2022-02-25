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
    case jumpBackIn = "JumpBackIn"
    case inactiveTabs = "InactiveTabs"
    case toolbarLocation = "ToolbarLocation"
}

class ContextualHintViewModel {
    typealias CFRStrings = String.ContextualHints
    typealias CFRPrefsKeys = PrefsKeys.ContextualHints

    // MARK: - Properties
    var hintType: ContextualHintViewType
    var timer: Timer?
    var presentFromTimer: (() -> Void)? = nil
    private var profile: Profile
    private var hasSentTelemetryEvent = false

    var arrowDirection = UIPopoverArrowDirection.down

    private var hasAlreadyBeenPresented: Bool {
        guard let contextualHintData = profile.prefs.boolForKey(prefsKey) else {
            return false
        }

        return contextualHintData
    }

    // Prevent JumpBackIn CFR from being presented if the onboarding
    // CFR has not yet been presented. On iPad we don't present the onboarding CFR
    private var canJumpBackInBePresented: Bool {
        guard UIDevice.current.userInterfaceIdiom != .pad else { return true }
        
        if let hasShownOnboardingCFR = profile.prefs.boolForKey(CFRPrefsKeys.ToolbarOnboardingKey.rawValue),
           hasShownOnboardingCFR {
            return true
        }

        return false
    }

    // Do not present contextual hint in landscape on iPhone
    private var isDeviceHintReady: Bool {
        !UIWindow.isLandscape || UIDevice.current.userInterfaceIdiom == .pad
    }

    private var prefsKey: String {
        switch hintType {
        case .inactiveTabs: return CFRPrefsKeys.InactiveTabsKey.rawValue
        case .jumpBackIn: return CFRPrefsKeys.JumpBackinKey.rawValue
        case .toolbarLocation: return CFRPrefsKeys.ToolbarOnboardingKey.rawValue
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

        switch hintType {
        case .jumpBackIn:
            return canJumpBackInBePresented && !hasAlreadyBeenPresented

        case .toolbarLocation:
            return SearchBarSettingsViewModel.isEnabled && !hasAlreadyBeenPresented

        default:
            return !hasAlreadyBeenPresented
        }
    }

    func markContextualHintPresented() {
        profile.prefs.setBool(true, forKey: prefsKey)
    }

    func startTimer() {
        var timeInterval: TimeInterval = 0

        switch hintType {
        case .toolbarLocation: timeInterval = 0.5
        default: timeInterval = 1.25
        }

        timer?.invalidate()

        timer = Timer.scheduledTimer(timeInterval: timeInterval,
                                     target: self,
                                     selector: #selector(presentHint),
                                     userInfo: nil,
                                     repeats: false)
    }

    func stopTimer() {
        timer?.invalidate()
    }

    // MARK: Text

    func descriptionText(arrowDirection: UIPopoverArrowDirection) -> String {
        switch hintType {
        case .inactiveTabs: return CFRStrings.TabsTray.InactiveTabs.Body
        case .jumpBackIn: return CFRStrings.FirefoxHomepage.JumpBackIn.PersonalizedHome

        case .toolbarLocation:
            switch arrowDirection {
            case .up:
                return CFRStrings.Toolbar.SearchBarPlacementForExistingUsers
            default:
                return CFRStrings.Toolbar.SearchBarPlacementForNewUsers
            }
        }
    }

    func buttonActionText() -> String {
        switch hintType {
        case .inactiveTabs: return CFRStrings.TabsTray.InactiveTabs.Action
        case .toolbarLocation: return CFRStrings.Toolbar.SearchBarPlacementButtonText
        default: return ""
        }
    }

    func isActionType() -> Bool {
        switch hintType {
        case .inactiveTabs,
                .toolbarLocation:
            return true

        default: return false
        }
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
            hasSentTelemetryEvent = true

        case .tapToDismiss:
            if hasSentTelemetryEvent { return }
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
            hasSentTelemetryEvent = true
        }
    }

    // MARK: - Present
    @objc private func presentHint() {
        timer?.invalidate()
        timer = nil
        presentFromTimer?()
        presentFromTimer = nil
    }
}
