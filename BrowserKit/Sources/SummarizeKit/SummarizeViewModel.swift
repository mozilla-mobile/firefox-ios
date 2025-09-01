// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import ComponentLibrary

public struct BrandViewModel {
    let brandLabel: String
    let brandLabelA11yId: String
    let brandImage: UIImage?
    let brandImageA11yId: String

    public init(
        brandLabel: String,
        brandLabelA11yId: String,
        brandImage: UIImage?,
        brandImageA11yId: String
    ) {
        self.brandLabel = brandLabel
        self.brandLabelA11yId = brandLabelA11yId
        self.brandImage = brandImage
        self.brandImageA11yId = brandImageA11yId
    }
}

public struct LoadingLabelViewModel {
    let loadingLabel: String
    let loadingA11yLabel: String
    let loadingA11yId: String

    public init(
        loadingLabel: String,
        loadingA11yLabel: String,
        loadingA11yId: String
    ) {
        self.loadingLabel = loadingLabel
        self.loadingA11yLabel = loadingA11yLabel
        self.loadingA11yId = loadingA11yId
    }
}

public struct TabSnapshotViewModel {
    let tabSnapshotA11yLabel: String
    let tabSnapshotA11yId: String
    let tabSnapshot: UIImage
    let tabSnapshotTopOffset: CGFloat

    public init(
        tabSnapshotA11yLabel: String,
        tabSnapshotA11yId: String,
        tabSnapshot: UIImage,
        tabSnapshotTopOffset: CGFloat
    ) {
        self.tabSnapshotA11yLabel = tabSnapshotA11yLabel
        self.tabSnapshotA11yId = tabSnapshotA11yId
        self.tabSnapshot = tabSnapshot
        self.tabSnapshotTopOffset = tabSnapshotTopOffset
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

public struct SummarizeViewModel {
    let titleLabelA11yId: String
    let compactTitleLabelA11yId: String
    let summarizeViewA11yId: String
    let summaryFootnote: String
    let tabSnapshotViewModel: TabSnapshotViewModel
    let loadingLabelViewModel: LoadingLabelViewModel
    let brandViewModel: BrandViewModel
    let closeButtonModel: CloseButtonViewModel
    let errorMessages: LocalizedErrorsViewModel

    let onDismiss: @MainActor () -> Void

    public init(
        titleLabelA11yId: String,
        compactTitleLabelA11yId: String,
        summaryFootnote: String,
        summarizeViewA11yId: String,
        tabSnapshotViewModel: TabSnapshotViewModel,
        loadingLabelViewModel: LoadingLabelViewModel,
        brandViewModel: BrandViewModel,
        closeButtonModel: CloseButtonViewModel,
        errorMessages: LocalizedErrorsViewModel,
        onDismiss: @escaping @MainActor () -> Void
    ) {
        self.titleLabelA11yId = titleLabelA11yId
        self.compactTitleLabelA11yId = compactTitleLabelA11yId
        self.summarizeViewA11yId = summarizeViewA11yId
        self.loadingLabelViewModel = loadingLabelViewModel
        self.tabSnapshotViewModel = tabSnapshotViewModel
        self.brandViewModel = brandViewModel
        self.summaryFootnote = summaryFootnote
        self.closeButtonModel = closeButtonModel
        self.onDismiss = onDismiss
        self.errorMessages = errorMessages
    }
}
