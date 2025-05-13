// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

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
    case mainMenu = "MainMenu"
    case dataClearance = "DataClearance"
    case navigation = "Navigation"
    case toolbarUpdate = "ToolbarUpdate"
}

class ContextualHintViewProvider: ContextualHintPrefsKeysProvider, SearchBarLocationProvider {
    typealias CFRPrefsKeys = PrefsKeys.ContextualHints
    typealias CFRStrings = String.ContextualHints

    // MARK: - Properties
    var hintType: ContextualHintType
    var timer: Timer?
    var presentFromTimer: (() -> Void)?
    private var profile: Profile
    private var hasSentTelemetryEvent = false
    var arrowDirection = UIPopoverArrowDirection.down
    var overlayState: OverlayStateProtocol?

    // MARK: - Initializers

    init(forHintType hintType: ContextualHintType, with profile: Profile) {
        self.hintType = hintType
        self.profile = profile
    }

    // MARK: - Interface

    func shouldPresentContextualHint() -> Bool {
        let hintEligibilityUtility = ContextualHintEligibilityUtility(
            with: profile,
            overlayState: overlayState,
            isToolbarUpdateCFRFeatureEnabled: featureFlags.isFeatureEnabled(.toolbarUpdateHint, checking: .buildOnly)
        )

        return hintEligibilityUtility.canPresent(hintType)
    }

    func markContextualHintPresented() {
        switch hintType {
        // If JumpBackInSyncedTab CFR was shown, don't present JumpBackIn CFR (both convey similar info)
        case .jumpBackInSyncedTab:
            profile.prefs.setBool(true, forKey: CFRPrefsKeys.jumpBackInSyncedTabKey.rawValue)
            profile.prefs.setBool(true, forKey: CFRPrefsKeys.jumpBackinKey.rawValue)
        default:
            profile.prefs.setBool(true, forKey: prefsKey(for: hintType))
        }
    }

    // Utility for this method explained in ContextualHintEligibilityUtility with hasHintBeenConfigured function
    func markContextualHintConfiguration(configured: Bool) {
        switch hintType {
        case .jumpBackIn:
            profile.prefs.setBool(configured, forKey: CFRPrefsKeys.jumpBackInConfiguredKey.rawValue)
        case .jumpBackInSyncedTab:
            profile.prefs.setBool(configured, forKey: CFRPrefsKeys.jumpBackInSyncedTabConfiguredKey.rawValue)
        default:
            break
        }
    }

    func startTimer() {
        var timeInterval: TimeInterval = 0

        switch hintType {
        case .inactiveTabs: timeInterval = 0.25
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

    func getCopyFor(_ copyType: ContextualHintCopyType) -> String {
        return ContextualHintCopyProvider().getCopyFor(copyType, of: hintType)
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
    @objc
    private func presentHint() {
        guard shouldPresentContextualHint() else { return }

        timer?.invalidate()
        timer = nil
        presentFromTimer?()
        presentFromTimer = nil
    }
}
