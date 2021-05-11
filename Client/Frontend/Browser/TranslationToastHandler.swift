/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Storage
import XCGLogger

private let log = Logger.browserLogger

class TranslationToastHandler: TabEventHandler {
    private let snackBarClassIdentifier = "translationPrompt"

    private let setting: TranslationServices

    init(_ prefs: Prefs) {
        self.setting = TranslationServices(prefs: prefs)
        register(self, forTabEvents: .didDeriveMetadata)
    }

    func tab(_ tab: Tab, didDeriveMetadata metadata: DerivedMetadata) {
        // dismiss the previous translation snackbars.
        tab.expireSnackbars(withClass: self.snackBarClassIdentifier)

        guard setting.translateOnOff else {
            return
        }

        guard let myLanguage = Locale.autoupdatingCurrent.languageCode, let pageLanguage = metadata.language else {
                return
        }

        guard let url = tab.url, !url.absoluteString.starts(with: setting.useTranslationService.destinationURLPrefix) else {
            return
        }
        let pageLocale = Locale(identifier: pageLanguage)

        if pageLocale.languageCode != Locale(identifier: myLanguage).languageCode, pageLocale.languageCode != "mul" {
            self.promptTranslation(tab, from: pageLanguage, to: myLanguage)
        }
    }

    func promptTranslation(_ tab: Tab, from pageLanguage: String, to myLanguage: String) {
        let locale = Locale.current
        let localizedMyLanguage = locale.localizedString(forLanguageCode: myLanguage) ?? myLanguage
        let localizedPageLanguage = locale.localizedString(forLanguageCode: pageLanguage) ?? pageLanguage

        let service = setting.useTranslationService
        let promptMessage = String(format: Strings.TranslateSnackBarPrompt, localizedPageLanguage, localizedMyLanguage, service.name)
        let snackBar = SnackBar(text: promptMessage, img: UIImage(named: "search"), snackbarClassIdentifier: snackBarClassIdentifier)
        let cancel = SnackButton(title: Strings.TranslateSnackBarNo, accessibilityIdentifier: "TranslationPrompt.dontTranslate", bold: false) { bar in
            tab.removeSnackbar(bar)

            TelemetryWrapper.recordEvent(category: .action, method: .translate, object: .tab, extras: ["action": "decline", "from": pageLanguage, "to": myLanguage])
        }
        let ok = SnackButton(title: Strings.TranslateSnackBarYes, accessibilityIdentifier: "TranslationPrompt.doTranslate", bold: true) { bar in
            tab.removeSnackbar(bar)
            self.translate(tab, from: pageLanguage, to: myLanguage)

            TelemetryWrapper.recordEvent(category: .action, method: .translate, object: .tab, extras: ["action": "accept", "from": pageLanguage, "to": myLanguage])
        }
        snackBar.addButton(cancel)
        snackBar.addButton(ok)
        tab.addSnackbar(snackBar)

        TelemetryWrapper.recordEvent(category: .prompt, method: .translate, object: .tab, extras: ["from": pageLanguage, "to": myLanguage])
    }

    func translate(_ tab: Tab, from pageLanguage: String, to myLanguage: String) {
        guard let urlString = tab.pageMetadata?.siteURL,
            let url = URL(string: urlString),
            let urlQueryParam = url.absoluteString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed) else {
                return
        }

        let service = setting.useTranslationService
        let translationURL = String(format: service.urlTemplate,
                             pageLanguage,
                             myLanguage,
                             urlQueryParam)

        if let newURL = URL(string: translationURL) {
            tab.loadRequest(URLRequest(url: newURL))
        }
    }
}
