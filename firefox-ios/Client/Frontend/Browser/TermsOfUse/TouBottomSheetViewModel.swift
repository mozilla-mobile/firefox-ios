// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import Localizations

struct ToUBottomSheetViewModel {
    let titleText: String
    let descriptionText: String
    let acceptButtonTitle: String
    let remindMeLaterButtonTitle: String

    var onAccept: (() -> Void)?
    var onNotNow: (() -> Void)?

    init() {
        self.titleText = TermsOfUse.Title
        self.descriptionText = TermsOfUse.Description
        self.acceptButtonTitle = TermsOfUse.AcceptButton
        self.remindMeLaterButtonTitle = TermsOfUse.RemindMeLaterButton
    }

    func linkURL(for term: String) -> URL? {
        switch term {
        case TermsOfUse.LinkTermsOfUse:
            return URL(string: "https://www.mozilla.org/about/legal/terms/firefox/")
        case TermsOfUse.LinkPrivacyNotice:
            return URL(string: "https://www.mozilla.org/privacy/firefox/")
        case TermsOfUse.LinkLearnMore:
            return URLForTopic("firefox-terms-of-use-faq")
        default:
            return nil
        }
    }
    
    func URLForTopic(_ topic: String) -> URL? {
        guard let escapedTopic = topic.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let languageIdentifier = Locale.preferredLanguages.first
        else {
            return nil
        }
        return URL(string: "https://support.mozilla.org/1/firefox/\(AppInfo.appVersion)/iOS/\(languageIdentifier)/\(escapedTopic)")
    }
}
