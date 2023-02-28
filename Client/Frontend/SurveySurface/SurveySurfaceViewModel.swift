// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class SurveySurfaceViewModel {
    private let text: String
    private let primaryButtonLabel: String
    private let actionURL: URL

    init(
        withText surfaceText: String,
        andButtonLabel primaryButtonLabel: String,
        andActionURL url: URL
    ) {
        self.text = surfaceText
        self.primaryButtonLabel = primaryButtonLabel
        self.actionURL = url
    }
}
