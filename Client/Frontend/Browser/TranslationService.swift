/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

struct TranslationService {
    let id: String
    let name: String
    let urlTemplate: String
    let destinationURLPrefix: String
}

class TranslationServices {
    let list = [
        TranslationService(id: "googletranslate",
                           name: "Google Translate",
                           urlTemplate: "https://translate.google.com/translate?hl=%2$@&sl=%1$@&tl=%2$@&u=%3$@",
                           destinationURLPrefix: "https://translate.googleusercontent.com/translate_c"),
        TranslationService(id: "bing",
                           name: "Bing",
                           urlTemplate: "https://www.microsofttranslator.com/bv.aspx?from=%1$@&to=%2$@&a=%3$@",
                           destinationURLPrefix: "https://www.microsofttranslator.com/bv.aspx"),
        ]

    private let defaultId = AppInfo.isChinaEdition ? "bing" : "googletranslate"

    private let prefs: Prefs

    init(prefs: Prefs) {
        self.prefs = prefs
    }

    var translateOnOff: Bool {
        get {
            return prefs.boolForKey("show-translation") ?? true
        }
        set {
            prefs.setBool(newValue, forKey: "show-translation")
        }
    }

    var useTranslationService: TranslationService {
        get {
            let id = prefs.stringForKey("translation-with") ?? ""
            return list.find { $0.id == id } ?? list.find { $0.id == defaultId } ?? list[0]
        }
        set {
            prefs.setString(newValue.id, forKey: "translation-with")
        }
    }
}
