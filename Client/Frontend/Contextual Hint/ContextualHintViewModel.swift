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

enum ContextualHintType: String {
    case jumpBackIn = "JumpBackIn"
    case jumpBackInSyncedTab = "JumpBackInSyncedTab"
    case inactiveTabs = "InactiveTabs"
    case toolbarLocation = "ToolbarLocation"
}

class ContextualHintViewModel: ContextualHintPrefsKeysProvider {
    typealias CFRPrefsKeys = PrefsKeys.ContextualHints
    typealias CFRStrings = String.ContextualHints

    // MARK: - Properties
    var hintType: ContextualHintType
    var timer: Timer?
    var presentFromTimer: (() -> Void)?
    private var profile: Profile
    private var hasSentTelemetryEvent = false
    var arrowDirection = UIPopoverArrowDirection.down

    // MARK: - Initializers

    init(forHintType hintType: ContextualHintType, with profile: Profile) {
        self.hintType = hintType
        self.profile = profile
    }

    // MARK: - Interface

    func shouldPresentContextualHint() -> Bool {
        let hintEligibilityUtility = ContextualHintEligibilityUtility(with: profile)

        return hintEligibilityUtility.canPresent(hintType)
    }

    func markContextualHintPresented() {
        switch hintType {
        // If JumpBackInSyncedTab CFR was shown, don't present JumpBackIn CFR (both convey similar info)
        case .jumpBackInSyncedTab:
            profile.prefs.setBool(true, forKey: CFRPrefsKeys.JumpBackInSyncedTabKey.rawValue)
            profile.prefs.setBool(true, forKey: CFRPrefsKeys.JumpBackinKey.rawValue)
        default:
            profile.prefs.setBool(true, forKey: prefsKey(for: hintType))
        }
    }

    func startTimer() {
        var timeInterval: TimeInterval = 0

        switch hintType {
        case .inactiveTabs: timeInterval = 0.25
        case .toolbarLocation: timeInterval = 0.5
        default: timeInterval = 1.25
        }

        timer?.invalidate()

        timer = Timer.scheduledTimer(
            timeInterval: timeInterval,
            target: self,
            selector: #selector(presentHint),
            userInfo: nil,
            repeats: false)
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: Text

    func descriptionText(arrowDirection: UIPopoverArrowDirection) -> String {
        switch hintType {
        case .inactiveTabs: return CFRStrings.TabsTray.InactiveTabs.Body
        case .jumpBackIn: return CFRStrings.FirefoxHomepage.JumpBackIn.PersonalizedHome
        case .jumpBackInSyncedTab: return CFRStrings.FirefoxHomepage.JumpBackIn.SyncedTab
        case .toolbarLocation: return .localized(.searchBarHint)
        }
    }

    func buttonActionText() -> String {
        switch hintType {
        case .inactiveTabs: return CFRStrings.TabsTray.InactiveTabs.Action
        case .toolbarLocation: return .localized(.openSettings)
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
        let hintTypeExtra = hintType == .toolbarLocation ? getToolbarLocation() : hintType.rawValue
        let extra = [TelemetryWrapper.EventExtraKey.cfrType.rawValue: hintTypeExtra]

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

    private func getToolbarLocation() -> String {
        guard SearchBarSettingsViewModel.isEnabled,
              SearchBarSettingsViewModel(prefs: profile.prefs).searchBarPosition == .bottom
        else { return "ToolbarLocationTop" }

        return "ToolbarLocationBottom"
    }

    // MARK: - Present
    @objc private func presentHint() {
        guard shouldPresentContextualHint() else { return }

        timer?.invalidate()
        timer = nil
        presentFromTimer?()
        presentFromTimer = nil
    }
}
