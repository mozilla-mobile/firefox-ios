// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Intents
import IntentsUI

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
        guard let activity = SiriShortcuts().getActivity(for: activityType) else { return }
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

    @MainActor
    static func manageSiri(for activityType: SiriShortcuts.activityType,
                           in viewController: UIViewController,
                           logger: Logger = DefaultLogger.shared) async {
        do {
            let voiceShortcuts = try await INVoiceShortcutCenter.shared.allVoiceShortcuts()
            let foundShortcut = voiceShortcuts.first(where: { (attempt) in
                attempt.shortcut.userActivity?.activityType == activityType.rawValue
            })

            if let foundShortcut = foundShortcut {
                self.displayEditSiri(for: foundShortcut, in: viewController)
            } else {
                self.displayAddToSiri(for: activityType, in: viewController)
            }
        } catch {
            logger.log(
                "Could not get voice shortcurts: \(error.localizedDescription)",
                level: .warning,
                category: .settings,
                extra: nil
            )
        }
    }
}
