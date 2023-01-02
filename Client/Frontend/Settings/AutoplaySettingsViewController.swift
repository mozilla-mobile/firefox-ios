// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared

class AutoplaySettingsViewController: SettingsTableViewController {
    /* variables for checkmark settings */
    let prefs: Prefs
    var currentChoice: AutoplayAction!
    init(prefs: Prefs) {
        self.prefs = prefs
        super.init(style: .grouped)

        self.title = .Settings.Autoplay.Autoplay
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func generateSettings() -> [SettingSection] {
        self.currentChoice = prefs.stringForKey(AutoplayAccessors.AutoplayPrefKey).flatMap({AutoplayAction(rawValue: $0)}) ?? AutoplayAccessors.Default

        let onFinished = {
            self.prefs.setString(self.currentChoice.rawValue, forKey: AutoplayAccessors.AutoplayPrefKey)
            self.tableView.reloadData()
        }

        let allowAudioAndVideo = CheckmarkSetting(
            title: NSAttributedString(string: .Settings.Autoplay.AllowAudioAndVideo),
            subtitle: nil,
            accessibilityIdentifier: "AllowAudioAndVideo",
            isChecked: {return self.currentChoice == AutoplayAction.allowAudioAndVideo},
            onChecked: {
                self.currentChoice = AutoplayAction.allowAudioAndVideo
                onFinished()
        })
        let blockAudio = CheckmarkSetting(
            title: NSAttributedString(string: .Settings.Autoplay.BlockAudio),
            subtitle: nil,
            accessibilityIdentifier: "BlockAudio",
            isChecked: {return self.currentChoice == AutoplayAction.blockAudio},
            onChecked: {
                self.currentChoice = AutoplayAction.blockAudio
                onFinished()
        })
        let blockAudioAndVideo = CheckmarkSetting(
            title: NSAttributedString(string: .Settings.Autoplay.BlockAudioAndVideo),
            subtitle: nil,
            accessibilityIdentifier: "BlockAudioAndVideo",
            isChecked: {return self.currentChoice == AutoplayAction.blockAudioAndVideo},
            onChecked: {
                self.currentChoice = AutoplayAction.blockAudioAndVideo
                onFinished()
        })

        let section = SettingSection(
            title: NSAttributedString(string: .Settings.Autoplay.Autoplay),
            children: [allowAudioAndVideo, blockAudio, blockAudioAndVideo])

        return [section]
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.post(name: .HomePanelPrefsChanged, object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.keyboardDismissMode = .onDrag
    }
}
