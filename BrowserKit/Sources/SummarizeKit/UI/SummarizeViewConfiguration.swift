// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import ComponentLibrary

public struct BrandViewConfiguration {
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

public struct LoadingLabelViewConfiguration {
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

public struct TabSnapshotViewConfiguration {
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

public struct LocalizedErrorsViewConfiguration {
    let rateLimitedMessage: String
    let unsafeContentMessage: String
    let summarizationNotAvailableMessage: String
    let pageStillLoadingMessage: String
    let genericErrorMessage: String

    let errorLabelA11yId: String
    let errorButtonA11yId: String
    let retryButtonLabel: String
    let closeButtonLabel: String
    let acceptToSButtonLabel: String

    public init(
        rateLimitedMessage: String,
        unsafeContentMessage: String,
        summarizationNotAvailableMessage: String,
        pageStillLoadingMessage: String,
        genericErrorMessage: String,
        errorLabelA11yId: String,
        errorButtonA11yId: String,
        retryButtonLabel: String,
        closeButtonLabel: String,
        acceptToSButtonLabel: String
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
        self.acceptToSButtonLabel = acceptToSButtonLabel
    }
}

public struct TermOfServiceViewConfiguration {
    let titleLabel: String
    let titleLabelA11yId: String
    let descriptionText: String
    let descriptionTextA11yId: String
    let linkButtonLabel: String
    let linkButtonURL: URL?
    let allowButtonTitle: String
    let allowButtonA11yId: String
    let allowButtonA11yLabel: String
    let cancelButtonTitle: String
    let cancelButtonA11yId: String
    let cancelButtonA11yLabel: String

    public init(
        titleLabel: String,
        titleLabelA11yId: String,
        descriptionText: String,
        descriptionTextA11yId: String,
        linkButtonLabel: String,
        linkButtonURL: URL?,
        allowButtonTitle: String,
        allowButtonA11yId: String,
        allowButtonA11yLabel: String,
        cancelButtonTitle: String,
        cancelButtonA11yId: String,
        cancelButtonA11yLabel: String
    ) {
        self.titleLabel = titleLabel
        self.titleLabelA11yId = titleLabelA11yId
        self.descriptionText = descriptionText
        self.descriptionTextA11yId = descriptionTextA11yId
        self.linkButtonLabel = linkButtonLabel
        self.linkButtonURL = linkButtonURL
        self.allowButtonTitle = allowButtonTitle
        self.allowButtonA11yId = allowButtonA11yId
        self.allowButtonA11yLabel = allowButtonA11yLabel
        self.cancelButtonTitle = cancelButtonTitle
        self.cancelButtonA11yId = cancelButtonA11yId
        self.cancelButtonA11yLabel = cancelButtonA11yLabel
    }
}

public struct SummarizeViewConfiguration {
    let titleLabelA11yId: String
    let compactTitleLabelA11yId: String
    let summarizeViewA11yId: String
    let summaryFootnote: String
    let tabSnapshot: TabSnapshotViewConfiguration
    let loadingLabel: LoadingLabelViewConfiguration
    let brandView: BrandViewConfiguration
    let closeButton: CloseButtonViewModel
    let errorMessages: LocalizedErrorsViewConfiguration
    let termOfService: TermOfServiceViewConfiguration

    public init(
        titleLabelA11yId: String,
        compactTitleLabelA11yId: String,
        summaryFootnote: String,
        summarizeViewA11yId: String,
        tabSnapshot: TabSnapshotViewConfiguration,
        loadingLabel: LoadingLabelViewConfiguration,
        brandView: BrandViewConfiguration,
        closeButton: CloseButtonViewModel,
        errorMessages: LocalizedErrorsViewConfiguration,
        termOfService: TermOfServiceViewConfiguration
    ) {
        self.titleLabelA11yId = titleLabelA11yId
        self.compactTitleLabelA11yId = compactTitleLabelA11yId
        self.summarizeViewA11yId = summarizeViewA11yId
        self.summaryFootnote = summaryFootnote
        self.tabSnapshot = tabSnapshot
        self.loadingLabel = loadingLabel
        self.brandView = brandView
        self.closeButton = closeButton
        self.errorMessages = errorMessages
        self.termOfService = termOfService
    }
}
