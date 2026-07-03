// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared

/// Debug toggle that forces Quick Answers to use the legacy speech recognition model
/// (`SFSpeechRecognizerEngine`) instead of the iOS 26+ `SpeechAnalyzerEngine`.
/// Only meaningful on iOS 26+, where both engines are available.
class QuickAnswersSpeechModelSetting: HiddenSetting {
    private var useOldModel: Bool {
        return settings.profile?.prefs.boolForKey(PrefsKeys.QuickAnswers.useOldSpeechModel) ?? false
    }

    override var title: NSAttributedString? {
        guard let theme else { return nil }
        return NSAttributedString(
            string: "Quick Answers: use old model: \(useOldModel)",
            attributes: [.foregroundColor: theme.colors.textPrimary]
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        settings.profile?.prefs.setBool(!useOldModel, forKey: PrefsKeys.QuickAnswers.useOldSpeechModel)
        settings.tableView.reloadData()
    }
}
