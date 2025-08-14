// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SummarizeKit
import Common
import ComponentLibrary
import UIKit
import Shared
import WebKit

/// Conforming types can show and hide the browser content together with its toolbars.
protocol BrowserContentHiding: AnyObject {
    func showBrowserContent()

    func hideBrowserContent()
}

class SummarizeCoordinator: BaseCoordinator, SummarizerServiceLifecycle {
    private let browserSnapshot: UIImage
    private let browserSnapshotTopOffset: CGFloat
    private weak var browserContentHiding: BrowserContentHiding?
    private weak var parentCoordinatorDelegate: ParentCoordinatorDelegate?
    private let webView: WKWebView
    private let summarizerNimbusUtils: SummarizerNimbusUtils
    private let summarizerServiceFactory: SummarizerServiceFactory
    private let windowUUID: WindowUUID
    private let trigger: SummarizerTrigger
    private let prefs: Prefs
    private let summarizerTelemetry: SummarizerTelemetry
    private let config: SummarizerConfig?
    private let onRequestOpenURL: ((URL?) -> Void)?

    init(
        browserSnapshot: UIImage,
        browserSnapshotTopOffset: CGFloat,
        webView: WKWebView,
        summarizerNimbusUtils: SummarizerNimbusUtils = DefaultSummarizerNimbusUtils(),
        summarizerServiceFactory: SummarizerServiceFactory = DefaultSummarizerServiceFactory(),
        browserContentHiding: BrowserContentHiding,
        parentCoordinatorDelegate: ParentCoordinatorDelegate?,
        trigger: SummarizerTrigger,
        prefs: Prefs,
        windowUUID: WindowUUID,
        config: SummarizerConfig? = nil,
        router: Router,
        gleanWrapper: GleanWrapper = DefaultGleanWrapper(),
        onRequestOpenURL: ((URL?) -> Void)?
    ) {
        self.summarizerNimbusUtils = summarizerNimbusUtils
        self.browserSnapshot = browserSnapshot
        self.browserSnapshotTopOffset = browserSnapshotTopOffset
        self.webView = webView
        self.parentCoordinatorDelegate = parentCoordinatorDelegate
        self.browserContentHiding = browserContentHiding
        self.windowUUID = windowUUID
        self.trigger = trigger
        self.prefs = prefs
        self.onRequestOpenURL = onRequestOpenURL
        self.summarizerServiceFactory = summarizerServiceFactory
        self.summarizerTelemetry = SummarizerTelemetry(gleanWrapper: gleanWrapper)
        self.config = config
        super.init(router: router)
    }

    func start() {
        if prefs.boolForKey(PrefsKeys.Summarizer.didAgreeTermsOfService) ?? false {
            summarizerTelemetry.summarizationRequested(trigger: trigger)
            showSummarizeViewController()
        } else {
            showToSAlert()
        }
    }

    private func showSummarizeViewController() {
        let isAppleSummarizerEnabled = summarizerNimbusUtils.isAppleSummarizerEnabled()
        let isHostedSummarizerEnabled = summarizerNimbusUtils.isHostedSummarizerEnabled()
        guard let service = summarizerServiceFactory.make(
            isAppleSummarizerEnabled: isAppleSummarizerEnabled,
            isHostedSummarizerEnabled: isHostedSummarizerEnabled,
            config: config) else { return }

        service.summarizerLifecycle = self

        let errorModel = LocalizedErrorsViewModel(
            rateLimitedMessage: .Summarizer.RateLimitedErrorMessage,
            unsafeContentMessage: .Summarizer.UnsafeWebsiteErrorMessage,
            summarizationNotAvailableMessage: .Summarizer.UnsupportedContentErrorMessage,
            pageStillLoadingMessage: .Summarizer.MissingPageContentErrorMessage,
            genericErrorMessage: .Summarizer.UnknownErrorMessage,
            errorLabelA11yId: AccessibilityIdentifiers.Summarizer.errorLabel,
            errorButtonA11yId: AccessibilityIdentifiers.Summarizer.errorButton,
            retryButtonLabel: .Summarizer.RetryButtonLabel,
            closeButtonLabel: .Summarizer.CloseButtonLabel
        )
        let brandLabel: String = if summarizerNimbusUtils.isAppleSummarizerEnabled() {
            .Summarizer.AppleBrandLabel
        } else {
            String(format: .Summarizer.HostedBrandLabel, AppName.shortName.rawValue)
        }
        let model = SummarizeViewModel(
            titleLabelA11yId: AccessibilityIdentifiers.Summarizer.titleLabel,
            loadingLabel: .Summarizer.LoadingLabel,
            loadingA11yLabel: .Summarizer.LoadingAccessibilityLabel,
            loadingA11yId: AccessibilityIdentifiers.Summarizer.loadingLabel,
            brandLabel: brandLabel,
            summaryNote: .Summarizer.FootnoteLabel,
            summarizeTextViewA11yLabel: .Summarizer.SummaryTextAccessibilityLabel,
            summarizeTextViewA11yId: AccessibilityIdentifiers.Summarizer.summaryTextView,
            closeButtonModel: CloseButtonViewModel(
                a11yLabel: .Summarizer.CloseButtonAccessibilityLabel,
                a11yIdentifier: AccessibilityIdentifiers.Summarizer.closeSummaryButton
            ),
            tabSnapshot: browserSnapshot,
            tabSnapshotTopOffset: browserSnapshotTopOffset,
            errorMessages: errorModel
        ) { [weak self] in
            self?.summarizerTelemetry.summarizationClosed()
            self?.browserContentHiding?.showBrowserContent()
            self?.dismissCoordinator()
        } onShouldShowTabSnapshot: { [weak self] in
            self?.browserContentHiding?.hideBrowserContent()
        }

        let controller = SummarizeController(
            windowUUID: windowUUID,
            viewModel: model,
            summarizerService: service,
            webView: webView,
            onSummaryDisplayed: { [weak self] in
                self?.summarizerTelemetry.summarizationDisplayed()
            }
        )

        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .overFullScreen
        router.present(controller, animated: true)
    }

    private func showToSAlert() {
        let descriptionText: String  = if summarizerNimbusUtils.isAppleSummarizerEnabled() {
            String(format: String.Summarizer.ToSAlertMessageAppleLabel, AppName.shortName.rawValue)
        } else {
            String(format: String.Summarizer.ToSAlertMessageFirefoxLabel, AppName.shortName.rawValue)
        }

        let tosViewModel = ToSBottomSheetViewModel(
            titleLabel: .Summarizer.ToSAlertTitleLabel,
            titleLabelA11yId: AccessibilityIdentifiers.Summarizer.tosTitleLabel,
            descriptionText: descriptionText,
            descriptionTextA11yId: AccessibilityIdentifiers.Summarizer.tosDescriptionText,
            linkButtonLabel: .Summarizer.ToSAlertLinkButtonLabel,
            linkButtonURL: SupportUtils.URLForTopic("summarize-pages-ios"),
            allowButtonTitle: .Summarizer.ToSAlertAllowButtonLabel,
            allowButtonA11yId: AccessibilityIdentifiers.Summarizer.tosAllowButton,
            allowButtonA11yLabel: .Summarizer.ToSAlertAllowButtonAccessibilityLabel,
            cancelButtonTitle: .Summarizer.ToSAlertCancelButtonLabel,
            cancelButtonA11yId: AccessibilityIdentifiers.Summarizer.tosCancelButton,
            cancelButtonA11yLabel: .Summarizer.ToSAlertCancelButtonAccessibilityLabel) { [weak self] url in
            self?.onRequestOpenURL?(url)
        } onAllowButtonPressed: { [weak self] in
            self?.prefs.setBool(true, forKey: PrefsKeys.Summarizer.didAgreeTermsOfService)
            self?.summarizerTelemetry.summarizationConsentDisplayed(true)
            self?.router.dismiss(animated: true) {
                self?.showSummarizeViewController()
            }
        } onDismiss: { [weak self] in
            self?.summarizerTelemetry.summarizationConsentDisplayed(false)
            self?.dismissCoordinator()
        }
        let tosController = ToSBottomSheetViewController(viewModel: tosViewModel, windowUUID: windowUUID)
        let bottomSheetViewController = BottomSheetViewController(
            viewModel: BottomSheetViewModel(
                closeButtonA11yLabel: .Summarizer.ToSAlertCloseButtonAccessibilityLabel,
                closeButtonA11yIdentifier: AccessibilityIdentifiers.Summarizer.tosCloseButton
            ),
            childViewController: tosController,
            usingDimmedBackground: true,
            windowUUID: windowUUID
        )
        tosController.delegate = bottomSheetViewController
        router.present(bottomSheetViewController, animated: false)
    }

    private func dismissCoordinator() {
        parentCoordinatorDelegate?.didFinish(from: self)
    }

    // MARK: –– SummarizerServiceLifecycle callbacks

    func summarizerServiceDidStart(_ text: String) {
        summarizerTelemetry.summarizationStarted(
            lengthWords: text.numberOfWords,
            lengthChars: Int32(clamping: text.count)
        )
    }

    func summarizerServiceDidComplete(_ summary: String, modelName: SummarizerModel) {
        summarizerTelemetry.summarizationCompleted(
            lengthChars: Int32(clamping: summary.count),
            lengthWords: summary.numberOfWords,
            modelName: modelName.rawValue,
            outcome: true
        )
    }

    func summarizerServiceDidFail(_ error: SummarizerError, modelName: SummarizerModel) {
        summarizerTelemetry.summarizationCompleted(
            lengthChars: 0,
            lengthWords: 0,
            modelName: modelName.rawValue,
            outcome: false,
            errorType: error.telemetryDescription
        )
    }
}
