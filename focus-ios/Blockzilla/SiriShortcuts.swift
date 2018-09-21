/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Intents
import IntentsUI

@available(iOS 12.0, *)
class SiriShortcuts {
    enum activityType: String {
        case erase = "EraseIntent"
        case eraseAndOpen = "org.mozilla.ios.Klar.eraseAndOpen"
        case openURL = "org.mozilla.ios.Klar.openUrl"
    }
    
    func getActivity(for type: activityType) -> NSUserActivity? {
        switch type {
        case .eraseAndOpen:
            return eraseAndOpenActivity
        case .openURL:
            return openUrlActivity
        default:
            return nil
        }
    }
    
    func getIntent(for type: activityType) -> INIntent? {
        switch type {
        case .erase:
            let intent = EraseIntent()
            intent.suggestedInvocationPhrase = "Erase"
            return intent
        default:
            return nil
        }
    }
    
    private var eraseAndOpenActivity: NSUserActivity = {
        let activity = NSUserActivity(activityType: activityType.eraseAndOpen.rawValue)
        activity.title = UIConstants.strings.eraseAndOpenSiri
        activity.userInfo = [:]
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.suggestedInvocationPhrase = UIConstants.strings.eraseAndOpenSiri
        activity.persistentIdentifier = NSUserActivityPersistentIdentifier(activityType.eraseAndOpen.rawValue)
        return activity
    }()
    
    private var openUrlActivity: NSUserActivity? = {
        guard let url = UserDefaults.standard.value(forKey: "favoriteUrl") as? String else { return nil }
        let activity = NSUserActivity(activityType: activityType.openURL.rawValue)
        activity.title = UIConstants.strings.openUrlSiri
        activity.userInfo = ["url": url]
        activity.isEligibleForSearch = false
        activity.isEligibleForPrediction = true
        activity.suggestedInvocationPhrase = UIConstants.strings.openUrlSiri
        activity.persistentIdentifier = NSUserActivityPersistentIdentifier(activityType.openURL.rawValue)
        return activity
    }()
    
    func hasAddedActivity(type: SiriShortcuts.activityType, _ completion: @escaping (_ result: Bool) -> Void) {
        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { (voiceShortcuts, error) in
            DispatchQueue.main.async {
                guard let voiceShortcuts = voiceShortcuts else { return }
                // First, check for userActivity, which is for shortcuts that work in the foreground
                var foundShortcut = voiceShortcuts.filter { (attempt) in
                    attempt.shortcut.userActivity?.activityType == type.rawValue
                    }.first
                // Next, check for intent, which is used for shortcuts that work in the background
                if foundShortcut == nil {
                    foundShortcut = voiceShortcuts.filter { (attempt) in
                        attempt.shortcut.intent as? EraseIntent != nil
                        }.first
                }
                completion(foundShortcut != nil)
            }
        }
    }
    
    func displayAddToSiri(for activityType: activityType, in viewController: UIViewController) {
        var shortcut: INShortcut?
        if let activity = SiriShortcuts().getActivity(for: activityType) {
            shortcut = INShortcut(userActivity: activity)
        } else if let intent = SiriShortcuts().getIntent(for: activityType) {
            shortcut = INShortcut(intent: intent)
        }
        guard let foundShortcut = shortcut else { return }
        
        let addViewController = INUIAddVoiceShortcutViewController(shortcut: foundShortcut)
        addViewController.modalPresentationStyle = .formSheet
        addViewController.delegate = viewController as? INUIAddVoiceShortcutViewControllerDelegate
        viewController.present(addViewController, animated: true, completion: nil)
    }
    
    func displayEditSiri(for shortcut: INVoiceShortcut, in viewController: UIViewController) {
        let editViewController = INUIEditVoiceShortcutViewController(voiceShortcut: shortcut)
        editViewController.modalPresentationStyle = .formSheet
        editViewController.delegate = viewController as? INUIEditVoiceShortcutViewControllerDelegate
        viewController.present(editViewController, animated: true, completion: nil)
    }
    
    func manageSiri(for activityType: SiriShortcuts.activityType, in viewController: UIViewController) {
        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { (voiceShortcuts, error) in
            DispatchQueue.main.async {
                guard let voiceShortcuts = voiceShortcuts else { return }
                var foundShortcut = voiceShortcuts.filter { (attempt) in
                    attempt.shortcut.userActivity?.activityType == activityType.rawValue
                    }.first
                if foundShortcut == nil {
                    foundShortcut = voiceShortcuts.filter { (attempt) in
                        attempt.shortcut.intent as? EraseIntent != nil
                        }.first
                }
                if let foundShortcut = foundShortcut {
                    self.displayEditSiri(for: foundShortcut, in: viewController)
                } else {
                    self.displayAddToSiri(for: activityType, in: viewController)
                }
            }
        }
    }
}
