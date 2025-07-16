// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import Localizations
import ComponentLibrary

struct ToUBottomSheetViewModel {
    let titleText: String
    let descriptionText: String
    let acceptButtonTitle: String
    let remindMeLaterButtonTitle: String

    let termsOfUseURL: URL
    let privacyNoticeURL: URL
    let learnMoreURL: URL

    var onAccept: (() -> Void)?
    var onNotNow: (() -> Void)?

    init() {
        self.titleText = TermsOfUse.Title
        self.descriptionText = TermsOfUse.Description
        self.acceptButtonTitle = TermsOfUse.AcceptButton
        self.remindMeLaterButtonTitle = TermsOfUse.RemindMeLaterButton

        self.termsOfUseURL = URL(string: "https://www.mozilla.org/about/legal/terms/firefox/") ??
            URL(string: "https://support.mozilla.org")!

        self.privacyNoticeURL = URL(string: "https://www.mozilla.org/privacy/firefox/") ??
            URL(string: "https://support.mozilla.org")!

        self.learnMoreURL = SupportUtils.URLForTopic("mobile-firefox-terms-of-use-faq") ??
            URL(string: "https://support.mozilla.org")!
    }

    func linkURL(for term: String) -> URL? {
        switch term {
        case TermsOfUse.LinkTermsOfUse:
            return termsOfUseURL
        case TermsOfUse.LinkPrivacyNotice:
            return privacyNoticeURL
        case TermsOfUse.LinkLearnMore:
            return learnMoreURL
        default:
            return nil
        }
    }
}
