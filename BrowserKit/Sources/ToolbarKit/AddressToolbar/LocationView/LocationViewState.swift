// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public struct LocationViewState {
    public let searchEngineImageViewA11yId: String
    public let searchEngineImageViewA11yLabel: String

    public let lockIconButtonA11yId: String
    public let lockIconButtonA11yLabel: String

    public let urlTextFieldPlaceholder: String
    public let urlTextFieldA11yId: String

    public let searchEngineImage: UIImage?
    public let lockIconImageName: String?
    public let lockIconNeedsTheming: Bool
    public let safeListedURLImageName: String?
    public let url: URL?
    public let droppableUrl: URL?
    public let searchTerm: String?
    public let isEditing: Bool
    public let didStartTyping: Bool
    public let shouldShowKeyboard: Bool
    public let shouldSelectSearchTerm: Bool
    public var onTapLockIcon: ((UIButton) -> Void)?
    public var onLongPress: (() -> Void)?

    public init(
        searchEngineImageViewA11yId: String,
        searchEngineImageViewA11yLabel: String,
        lockIconButtonA11yId: String,
        lockIconButtonA11yLabel: String,
        urlTextFieldPlaceholder: String,
        urlTextFieldA11yId: String,
        searchEngineImage: UIImage?,
        lockIconImageName: String?,
        lockIconNeedsTheming: Bool,
        safeListedURLImageName: String?,
        url: URL?,
        droppableUrl: URL?,
        searchTerm: String?,
        isEditing: Bool,
        didStartTyping: Bool,
        shouldShowKeyboard: Bool,
        shouldSelectSearchTerm: Bool,
        onTapLockIcon: ((UIButton) -> Void)? = nil,
        onLongPress: (() -> Void)? = nil
    ) {
        self.searchEngineImageViewA11yId = searchEngineImageViewA11yId
        self.searchEngineImageViewA11yLabel = searchEngineImageViewA11yLabel
        self.lockIconButtonA11yId = lockIconButtonA11yId
        self.lockIconButtonA11yLabel = lockIconButtonA11yLabel
        self.urlTextFieldPlaceholder = urlTextFieldPlaceholder
        self.urlTextFieldA11yId = urlTextFieldA11yId
        self.searchEngineImage = searchEngineImage
        self.lockIconImageName = lockIconImageName
        self.lockIconNeedsTheming = lockIconNeedsTheming
        self.safeListedURLImageName = safeListedURLImageName
        self.url = url
        self.droppableUrl = droppableUrl
        self.searchTerm = searchTerm
        self.isEditing = isEditing
        self.didStartTyping = didStartTyping
        self.shouldShowKeyboard = shouldShowKeyboard
        self.shouldSelectSearchTerm = shouldSelectSearchTerm
        self.onTapLockIcon = onTapLockIcon
        self.onLongPress = onLongPress
    }
}
