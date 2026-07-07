// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if DEBUG
import SwiftUI

@available(iOS 17.0, *)
#Preview("Filled") {
    WebCompatFormPreviewController(
        url: "https://houseandhome.com/recipe/croque-monsieur",
        selectedCategoryID: "siteNotUsable",
        selectedSubOptionID: "page_not_loading",
        additionalDetails: "The recipe images never load on this page.",
        includeScreenshot: true,
        includeBlockedList: true
    )
}

@available(iOS 17.0, *)
#Preview("Empty / Send disabled") {
    WebCompatFormPreviewController(url: "https://houseandhome.com/recipe/croque-monsieur")
}
#endif
