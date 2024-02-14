// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class NTPNewsletterCardViewModel: NTPConfigurableNudgeCardCellViewModel {
    override var title: String {
        .localized(.newsletterNTPCardExperimentTitle)
    }

    override var description: String {
        .localized(.newsletterNTPCardExperimentDescription)
    }

    override var buttonText: String {
        .localized(.newsletterNTPCardExperimentButton)
    }

    override var cardSectionType: HomepageSectionType {
        .newsletterCard
    }

    override var image: UIImage? {
        .init(named: "newsletterCardImage")
    }

    override var isEnabled: Bool {
        NewsletterCardExperiment.shouldShowCard
    }

    override func screenWasShown() {
        NewsletterCardExperiment.trackExperimentImpression()
    }
}
