/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Storage
import XCGLogger

private let log = Logger.browserLogger

class TranslationToastHandler: TabEventHandler {
    private var tabObservers: TabObservers!
    private let prefs: Prefs

    init(_ prefs: Prefs) {
        self.prefs = prefs

        tabObservers = registerFor(.didDeriveMetadata) // XXX this should be on queue: .main, but this causes deadlock.
    }

    deinit {
        unregister(tabObservers)
    }

    func tab(_ tab: Tab, didDeriveMetadata metadata: DerivedMetadata) {
        guard let myLanguage = Locale.current.languageCode,
            let pageLanguage = metadata.language else {
                return
        }

        if myLanguage != pageLanguage {
            DispatchQueue.main.async { // XXX this should be on already be on .main
                self.promptTranslation(tab, from: pageLanguage, to: myLanguage)
            }
        }
    }

    func promptTranslation(_ tab: Tab, from pageLanguage: String, to myLanguage: String) {
        let locale = Locale.current
        let localizedMyLanguage = locale.localizedString(forLanguageCode: myLanguage) ?? myLanguage
        let localizedPageLanguage = locale.localizedString(forLanguageCode: pageLanguage) ?? pageLanguage

        let promptMessage = String(format: Strings.TranslateSnackBarPrompt, localizedPageLanguage, localizedMyLanguage)
        let snackBar = SnackBar(text: promptMessage, img: UIImage(named: "search"))
        let cancel = SnackButton(title: Strings.TranslateSnackBarNo, accessibilityIdentifier: "TranslationPrompt.dontTranslate", bold: false) { bar in
            tab.removeSnackbar(bar)
            return
        }
        let ok = SnackButton(title: Strings.TranslateSnackBarYes, accessibilityIdentifier: "TranslationPrompt.doTranslate", bold: true) { bar in
            tab.removeSnackbar(bar)
        }
        snackBar.addButton(cancel)
        snackBar.addButton(ok)
        tab.addSnackbar(snackBar)
    }
}
