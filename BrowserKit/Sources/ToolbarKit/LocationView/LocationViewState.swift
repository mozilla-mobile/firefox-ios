// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public struct LocationViewState {
    public let searchEngineImageViewA11yId: String
    public let searchEngineImageViewA11yLabel: String

    public let urlTextFieldPlaceholder: String
    public let urlTextFieldA11yId: String
    public let urlTextFieldA11yLabel: String

    public let searchEngineImage: UIImage?
    public let lockIconImageName: String
    public let showSearchEngineIcon: Bool
    public let showTrackingProtectionButton: Bool

    public let url: String?

    public init(
        searchEngineImageViewA11yId: String,
        searchEngineImageViewA11yLabel: String,
        urlTextFieldPlaceholder: String,
        urlTextFieldA11yId: String,
        urlTextFieldA11yLabel: String,
        searchEngineImage: UIImage?,
        lockIconImageName: String,
        showSearchEngineIcon: Bool,
        showTrackingProtectionButton: Bool,
        url: String?
    ) {
        self.searchEngineImageViewA11yId = searchEngineImageViewA11yId
        self.searchEngineImageViewA11yLabel = searchEngineImageViewA11yLabel
        self.urlTextFieldPlaceholder = urlTextFieldPlaceholder
        self.urlTextFieldA11yId = urlTextFieldA11yId
        self.urlTextFieldA11yLabel = urlTextFieldA11yLabel
        self.searchEngineImage = searchEngineImage
        self.lockIconImageName = lockIconImageName
        self.showSearchEngineIcon = showSearchEngineIcon
        self.showTrackingProtectionButton = showTrackingProtectionButton
        self.url = url
    }
}
