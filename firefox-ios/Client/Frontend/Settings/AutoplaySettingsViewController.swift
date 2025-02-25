// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

class AutoplaySettingsViewController: SettingsTableViewController {
    private let prefs: Prefs
    private var currentChoice: AutoplayAction?

    init(prefs: Prefs, windowUUID: WindowUUID) {
        self.prefs = prefs
        super.init(style: .grouped, windowUUID: windowUUID)

        self.title = .Settings.Autoplay.Autoplay
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func generateSettings() -> [SettingSection] {
        self.currentChoice = prefs.stringForKey(
            AutoplayAccessors.autoplayPrefKey
        ).flatMap({ AutoplayAction(rawValue: $0) }) ?? AutoplayAccessors.defaultSetting

        let onFinished = { [weak self] in
            guard let currentChoice = self?.currentChoice else { return }
            self?.prefs.setString(currentChoice.rawValue, forKey: AutoplayAccessors.autoplayPrefKey)
            NotificationCenter.default.post(name: .AutoPlayChanged, object: nil)
            AutoplaySettingTelemetry().settingChanged(mediaType: currentChoice)
            self?.tableView.reloadData()
        }

        let allowAudioAndVideo = CheckmarkSetting(
            title: NSAttributedString(string: .Settings.Autoplay.AllowAudioAndVideo),
            subtitle: nil,
            accessibilityIdentifier: AccessibilityIdentifiers.Settings.Autoplay.allowAudioAndVideo,
            isChecked: { return self.currentChoice == AutoplayAction.allowAudioAndVideo },
            onChecked: {
                self.currentChoice = AutoplayAction.allowAudioAndVideo
                onFinished()
            }
        )

        let blockAudio = CheckmarkSetting(
            title: NSAttributedString(string: .Settings.Autoplay.BlockAudio),
            subtitle: nil,
            accessibilityIdentifier: AccessibilityIdentifiers.Settings.Autoplay.blockAudio,
            isChecked: { return self.currentChoice == AutoplayAction.blockAudio },
            onChecked: {
                self.currentChoice = AutoplayAction.blockAudio
                onFinished()
            }
        )

        let blockAudioAndVideo = CheckmarkSetting(
            title: NSAttributedString(string: .Settings.Autoplay.BlockAudioAndVideo),
            subtitle: nil,
            accessibilityIdentifier: AccessibilityIdentifiers.Settings.Autoplay.blockAudioAndVideo,
            isChecked: { return self.currentChoice == AutoplayAction.blockAudioAndVideo },
            onChecked: {
                self.currentChoice = AutoplayAction.blockAudioAndVideo
                onFinished()
            }
        )

        let section = SettingSection(
            title: NSAttributedString(string: .Settings.Autoplay.Autoplay),
            footerTitle: NSAttributedString(string: .Settings.Autoplay.Footer),
            children: [allowAudioAndVideo, blockAudio, blockAudioAndVideo])

        return [section]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.keyboardDismissMode = .onDrag
    }
}
