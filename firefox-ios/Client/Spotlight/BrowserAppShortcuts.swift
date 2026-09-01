// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppIntents
import Foundation

/// The app shortcuts offered to Siri, Spotlight and the Shortcuts app without the user having to set anything up.
///
/// An app can only declare one provider, so any new shortcut belongs in `appShortcuts` below. The tabs and bookmarks
/// offered as the spoken parameter come from `BrowserEntityQuery.allEntities()`.
@available(iOS 27.0, *)
struct BrowserAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenBrowserEntityIntent(),
            phrases: ["Open \(\.$target) in \(.applicationName)"],
            shortTitle: "Open Page",
            systemImageName: "globe",
            parameterPresentation: ParameterPresentation(
                for: \.$target,
                summary: Summary("Open \(\.$target)"),
                optionsCollections: {
                    OptionsCollection(BrowserEntityQuery(), title: "Pages", systemImageName: "globe")
                }
            )
        )
        AppShortcut(
            intent: OpenQuickAnswersIntent(),
            phrases: [
                "Quick Answers in \(.applicationName)",
                "Ask \(.applicationName) a question"
            ],
            shortTitle: "Quick Answers",
            systemImageName: "sparkles"
        )
    }
}
