// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import ComponentLibrary
@testable import SummarizeKit

final class SummarizeErrorExtensionTests: XCTestCase {
    private let configuration = SummarizeViewConfiguration(
        titleLabelA11yId: "",
        compactTitleLabelA11yId: "",
        summaryFootnote: "",
        summarizeViewA11yId: "",
        tabSnapshot: TabSnapshotViewConfiguration(
            tabSnapshotA11yLabel: "",
            tabSnapshotA11yId: "",
            tabSnapshot: .actions,
            tabSnapshotTopOffset: 0.0
        ),
        loadingLabel: LoadingLabelViewConfiguration(
            loadingLabel: "",
            loadingA11yLabel: "",
            loadingA11yId: ""
        ),
        brandView: BrandViewConfiguration(
            brandLabel: "",
            brandLabelA11yId: "",
            brandImage: nil,
            brandImageA11yId: ""
        ),
        closeButton: CloseButtonViewModel(a11yLabel: "", a11yIdentifier: ""),
        errorMessages: LocalizedErrorsViewConfiguration(
            rateLimitedMessage: "",
            unsafeContentMessage: "",
            summarizationNotAvailableMessage: "",
            pageStillLoadingMessage: "",
            genericErrorMessage: "",
            errorContentA11yId: "",
            retryButtonLabel: "retryButtonLabel",
            retryButtonA11yLabel: "retryButtonA11yLabel",
            retryButtonA11yId: "retroButtonA11yId",
            closeButtonLabel: "closeButtonLabel",
            closeButtonA11yLabel: "closeButtonA11yLabel",
            closeButtonA11yId: "closeButtonA11yId"
        ),
        termOfService: TermOfServiceViewConfiguration(
            titleLabel: "",
            descriptionText: "",
            linkButtonLabel: "",
            linkButtonURL: nil,
            allowButtonTitle: "allowButtonTitle",
            allowButtonA11yId: "allowButtonA11yId",
            allowButtonA11yLabel: "allowButtonA11yLabel"
        )
    )

    func test_shouldRetrySummarizing_forRetryableError() {
        let subject = SummarizerError.busy

        XCTAssertEqual(subject.shouldRetrySummarizing, .retry)
    }

    func test_shouldRetrySummarizing_forNotRetryableError() {
        let subject = SummarizerError.cancelled

        XCTAssertEqual(subject.shouldRetrySummarizing, .close)
    }

    func test_shouldRetrySummarizing_forTosNotAcceptedError() {
        let subject: SummarizerError = .tosConsentMissing

        XCTAssertEqual(subject.shouldRetrySummarizing, .acceptToS)
    }

    func test_errorButtonLabel_forRetryableError() {
        let subject = SummarizerError.busy

        XCTAssertEqual(
            subject.errorButtonLabel(for: configuration),
            configuration.errorMessages.retryButtonLabel
        )
    }

    func test_errorButtonLabel_forNotRetryableError() {
        let subject = SummarizerError.cancelled

        XCTAssertEqual(
            subject.errorButtonLabel(for: configuration),
            configuration.errorMessages.closeButtonLabel
        )
    }

    func test_errorButtonLabel_forTosNotAcceptedError() {
        let subject = SummarizerError.tosConsentMissing

        XCTAssertEqual(
            subject.errorButtonLabel(for: configuration),
            configuration.termOfService.allowButtonTitle
        )
    }

    func test_errorButtonA11yLabel_forRetryableError() {
        let subject = SummarizerError.busy

        XCTAssertEqual(
            subject.errorButtonA11yLabel(for: configuration),
            configuration.errorMessages.retryButtonA11yLabel
        )
    }

    func test_errorButtonA11yLabel_forNotRetryableError() {
        let subject = SummarizerError.cancelled

        XCTAssertEqual(
            subject.errorButtonA11yLabel(for: configuration),
            configuration.errorMessages.closeButtonA11yLabel
        )
    }

    func test_errorButtonA11yLabel_forTosNotAcceptedError() {
        let subject = SummarizerError.tosConsentMissing

        XCTAssertEqual(
            subject.errorButtonA11yLabel(for: configuration),
            configuration.termOfService.allowButtonA11yLabel
        )
    }

    func test_errorButtonA11yId_forRetryableError() {
        let subject = SummarizerError.busy

        XCTAssertEqual(
            subject.errorButtonA11yId(for: configuration),
            configuration.errorMessages.retryButtonA11yId
        )
    }

    func test_errorButtonA11yId_forNotRetryableError() {
        let subject = SummarizerError.cancelled

        XCTAssertEqual(
            subject.errorButtonA11yId(for: configuration),
            configuration.errorMessages.closeButtonA11yId
        )
    }

    func test_errorButtonA11yId_forTosNotAcceptedError() {
        let subject = SummarizerError.tosConsentMissing

        XCTAssertEqual(
            subject.errorButtonA11yId(for: configuration),
            configuration.termOfService.allowButtonA11yId
        )
    }
}
