// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import ComponentLibrary

public struct SummarizeViewModel {
    let loadingLabel: String
    let loadingA11yLabel: String
    let loadingA11yId: String
    let summarizeTextViewA11yLabel: String
    let summarizeTextViewA11yId: String

    let closeButtonModel: CloseButtonViewModel
    let tabSnapshot: UIImage
    let tabSnapshotTopOffset: CGFloat
    let errorMessages: LocalizedErrorsViewModel

    let onDismiss: @MainActor () -> Void
    let onShouldShowTabSnapshot: @MainActor () -> Void

    public init(
        loadingLabel: String,
        loadingA11yLabel: String,
        loadingA11yId: String,
        summarizeTextViewA11yLabel: String,
        summarizeTextViewA11yId: String,
        closeButtonModel: CloseButtonViewModel,
        tabSnapshot: UIImage,
        tabSnapshotTopOffset: CGFloat,
        errorMessages: LocalizedErrorsViewModel,
        onDismiss: @escaping @MainActor () -> Void,
        onShouldShowTabSnapshot: @escaping @MainActor () -> Void
    ) {
        self.loadingLabel = loadingLabel
        self.loadingA11yLabel = loadingA11yLabel
        self.loadingA11yId = loadingA11yId
        self.summarizeTextViewA11yLabel = summarizeTextViewA11yLabel
        self.summarizeTextViewA11yId = summarizeTextViewA11yId
        self.closeButtonModel = closeButtonModel
        self.tabSnapshot = tabSnapshot
        self.onDismiss = onDismiss
        self.onShouldShowTabSnapshot = onShouldShowTabSnapshot
        self.tabSnapshotTopOffset = tabSnapshotTopOffset
        self.errorMessages = errorMessages
    }
}

public struct LocalizedErrorsViewModel {
    let rateLimitedMessage: String
    let unsafeContentMessage: String
    let summarizationNotAvailableMessage: String
    let pageStillLoadingMessage: String
    let genericErrorMessage: String

    let errorLabelA11yId: String
    let errorButtonA11yId: String
    let retryButtonLabel: String
    let closeButtonLabel: String

    public init(
        rateLimitedMessage: String,
        unsafeContentMessage: String,
        summarizationNotAvailableMessage: String,
        pageStillLoadingMessage: String,
        genericErrorMessage: String,
        errorLabelA11yId: String,
        errorButtonA11yId: String,
        retryButtonLabel: String,
        closeButtonLabel: String
    ) {
        self.rateLimitedMessage = rateLimitedMessage
        self.unsafeContentMessage = unsafeContentMessage
        self.summarizationNotAvailableMessage = summarizationNotAvailableMessage
        self.pageStillLoadingMessage = pageStillLoadingMessage
        self.genericErrorMessage = genericErrorMessage
        self.errorLabelA11yId = errorLabelA11yId
        self.errorButtonA11yId = errorButtonA11yId
        self.retryButtonLabel = retryButtonLabel
        self.closeButtonLabel = closeButtonLabel
    }
}
