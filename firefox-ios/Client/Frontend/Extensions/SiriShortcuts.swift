// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppIntents
import Common
import Foundation
import Intents
import IntentsUI
import Shared
import UIKit

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

    @MainActor
    static func displayAddToSiri(for activityType: activityType, in viewController: UIViewController) {
        guard let activity = SiriShortcuts().getActivity(for: activityType) else { return }
        let shortcut = INShortcut(userActivity: activity)
        let addViewController = INUIAddVoiceShortcutViewController(shortcut: shortcut)
        addViewController.modalPresentationStyle = .formSheet
        addViewController.delegate = viewController as? INUIAddVoiceShortcutViewControllerDelegate
        viewController.present(addViewController, animated: true, completion: nil)
    }

    @MainActor
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
                "Could not get voice shortcuts: \(error.localizedDescription)",
                level: .warning,
                category: .settings
            )
        }
    }
}

// MARK: - App Intents

/// Resolving the term inside `perform()` re-runs the intent without filling the parameter in, which
/// loops forever, so it is left to the framework to resolve before `perform()` is called.
@available(iOS 16.0, *)
struct SearchInFirefoxIntent: AppIntent {
    static let title: LocalizedStringResource = "Search in Firefox"
    static var openAppWhenRun: Bool { true }

    @Parameter(title: "Search term", requestValueDialog: "What would you like to search for?")
    var query: String

    @MainActor
    func perform() async throws -> some IntentResult {
        // The internal scheme is unique to this build. The public `firefox` scheme is claimed by every
        // Firefox variant, so on a device with more than one installed iOS picks an arbitrary winner.
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
              let url = URL(string: "\(URL.mozInternalScheme)://open-text?text=\(encodedQuery)")
        else {
            return .result()
        }

        await UIApplication.shared.open(url)
        return .result()
    }
}

@available(iOS 18.0, *)
struct MakeFirefoxDefaultBrowserIntent: AppIntent {
    static let title: LocalizedStringResource = "Make Firefox Default Browser"
    static var openAppWhenRun: Bool { true }

    /// Siri speaks and waits for the user here, because opening Settings tears down the Siri session
    /// and would otherwise cut the instructions off mid sentence.
    @MainActor
    func perform() async throws -> some IntentResult {
        try await requestConfirmation(
            actionName: .open,
            dialog: "In Settings, tap Default Browser App, then choose Firefox."
        )

        DefaultApplicationHelper().openSettings()
        return .result()
    }
}

@available(iOS 18.0, *)
struct FirefoxAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SearchInFirefoxIntent(),
            phrases: [
                "Search \(.applicationName)",
                "Search in \(.applicationName)",
                "Search the web with \(.applicationName)",
                "Open a new tab in \(.applicationName) and search"
            ],
            shortTitle: "Search",
            systemImageName: "magnifyingglass"
        )
        AppShortcut(
            intent: MakeFirefoxDefaultBrowserIntent(),
            phrases: [
                "Make \(.applicationName) my default browser",
                "Set \(.applicationName) as my default browser"
            ],
            shortTitle: "Set as Default",
            systemImageName: "star"
        )
    }
}
