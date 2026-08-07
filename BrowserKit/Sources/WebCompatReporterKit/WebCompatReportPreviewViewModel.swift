// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// What the Report Preview screen renders. The Client supplies the copy, so the package stays
/// free of Redux and Strings. The raw payload rendering lives on `WebCompatTechnicalDataViewModel`.
public struct WebCompatReportPreviewViewModel: Equatable, Sendable {
    public struct Bullet: Hashable, Sendable {
        public let id: String
        public let text: String

        public init(id: String, text: String) {
            self.id = id
            self.text = text
        }
    }

    public let title: String
    public let closeAccessibilityLabel: String
    public let closeA11yIdentifier: String
    public let screenshotAccessibilityLabel: String
    public let screenshotA11yIdentifier: String
    public let bullets: [Bullet]
    public let bulletsA11yIdentifier: String
    public let technicalDataTitle: String
    public let technicalDataA11yIdentifier: String

    public init(
        title: String,
        closeAccessibilityLabel: String,
        closeA11yIdentifier: String,
        screenshotAccessibilityLabel: String,
        screenshotA11yIdentifier: String,
        bullets: [Bullet] = [],
        bulletsA11yIdentifier: String,
        technicalDataTitle: String,
        technicalDataA11yIdentifier: String
    ) {
        self.title = title
        self.closeAccessibilityLabel = closeAccessibilityLabel
        self.closeA11yIdentifier = closeA11yIdentifier
        self.screenshotAccessibilityLabel = screenshotAccessibilityLabel
        self.screenshotA11yIdentifier = screenshotA11yIdentifier
        self.bullets = bullets
        self.bulletsA11yIdentifier = bulletsA11yIdentifier
        self.technicalDataTitle = technicalDataTitle
        self.technicalDataA11yIdentifier = technicalDataA11yIdentifier
    }
}
