// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Intents
import IntentsUI
import Shared

class SiriShortcuts {
    enum activityType: String {
        case openURL = "org.mozilla.ios.Firefox.newTab"
    }

    func getActivity(for type: activityType) -> NSUserActivity? {
        switch type {
        case .openURL:
            return openUrlActivity
        }
    }

    private var openUrlActivity: NSUserActivity? = {
        let activity = NSUserActivity(activityType: activityType.openURL.rawValue)
        activity.title = .SettingsSiriOpenURL
        activity.isEligibleForPrediction = true
        activity.suggestedInvocationPhrase = .SettingsSiriOpenURL
        activity.persistentIdentifier = NSUserActivityPersistentIdentifier(activityType.openURL.rawValue)
        return activity
    }()

    static func displayAddToSiri(for activityType: activityType, in viewController: UIViewController) {
        guard let activity = SiriShortcuts().getActivity(for: activityType) else {
            return
        }
        let shortcut = INShortcut(userActivity: activity)
        let addViewController = INUIAddVoiceShortcutViewController(shortcut: shortcut)
        addViewController.modalPresentationStyle = .formSheet
        addViewController.delegate = viewController as? INUIAddVoiceShortcutViewControllerDelegate
        viewController.present(addViewController, animated: true, completion: nil)
    }

    static func displayEditSiri(for shortcut: INVoiceShortcut, in viewController: UIViewController) {
        let editViewController = INUIEditVoiceShortcutViewController(voiceShortcut: shortcut)
        editViewController.modalPresentationStyle = .formSheet
        editViewController.delegate = viewController as? INUIEditVoiceShortcutViewControllerDelegate
        viewController.present(editViewController, animated: true, completion: nil)
    }

    static func manageSiri(for activityType: SiriShortcuts.activityType, in viewController: UIViewController) {
        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { (voiceShortcuts, error) in
            DispatchQueue.main.async {
                guard let voiceShortcuts = voiceShortcuts else { return }
                let foundShortcut = voiceShortcuts.filter { (attempt) in
                    attempt.shortcut.userActivity?.activityType == activityType.rawValue
                    }.first
                if let foundShortcut = foundShortcut {
                    self.displayEditSiri(for: foundShortcut, in: viewController)
                } else {
                    self.displayAddToSiri(for: activityType, in: viewController)
                }
            }
        }
    }
}
