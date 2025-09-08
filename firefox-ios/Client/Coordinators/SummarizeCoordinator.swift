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

final class SummarizeCoordinator: BaseCoordinator,
                                  SummarizerServiceLifecycle,
                                  SummarizeNavigationHandler {
    private let browserSnapshot: UIImage
    private let browserSnapshotTopOffset: CGFloat
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
        summarizerTelemetry.summarizationRequested(trigger: trigger)
        showSummarizeViewController()
    }

    private func showSummarizeViewController() {
        let isAppleSummarizerEnabled = summarizerNimbusUtils.isAppleSummarizerEnabled()
        let isHostedSummarizerEnabled = summarizerNimbusUtils.isHostedSummarizerEnabled()
        guard let service = summarizerServiceFactory.make(
            isAppleSummarizerEnabled: isAppleSummarizerEnabled,
            isHostedSummarizerEnabled: isHostedSummarizerEnabled,
            config: config) else { return }

        service.summarizerLifecycle = self

        let brandLabel: String = if summarizerNimbusUtils.isAppleSummarizerEnabled() {
            .Summarizer.AppleBrandLabel
        } else {
            String(format: .Summarizer.HostedBrandLabel, AppName.shortName.rawValue)
        }
        let brandImage: UIImage? = if summarizerNimbusUtils.isAppleSummarizerEnabled() {
            UIImage(named: "appleIntelligence")
        } else {
            UIImage(named: "faviconFox")
        }

        let errorModel = LocalizedErrorsViewModel(
            rateLimitedMessage: .Summarizer.RateLimitedErrorMessage,
            unsafeContentMessage: .Summarizer.UnsafeWebsiteErrorMessage,
            summarizationNotAvailableMessage: .Summarizer.UnsupportedContentErrorMessage,
            pageStillLoadingMessage: .Summarizer.MissingPageContentErrorMessage,
            genericErrorMessage: .Summarizer.UnknownErrorMessage,
            errorLabelA11yId: AccessibilityIdentifiers.Summarizer.errorLabel,
            errorButtonA11yId: AccessibilityIdentifiers.Summarizer.errorButton,
            retryButtonLabel: .Summarizer.RetryButtonLabel,
            closeButtonLabel: .Summarizer.CloseButtonLabel,
            acceptToSButtonLabel: .Summarizer.ToSAlertContinueButtonLabel
        )

        let tosViewModel = ToSBottomSheetViewModel(
            titleLabel: .Summarizer.ToSInfoPanelTitleLabel,
            titleLabelA11yId: AccessibilityIdentifiers.Summarizer.tosTitleLabel,
            descriptionText: String(format: .Summarizer.ToSInfoPanelLabel, AppName.shortName.rawValue),
            descriptionTextA11yId: AccessibilityIdentifiers.Summarizer.tosDescriptionText,
            linkButtonLabel: .Summarizer.ToSInfoLabelLinkButtonLabel,
            linkButtonURL: SupportUtils.URLForTopic("summarize-pages-ios"),
            allowButtonTitle: .Summarizer.ToSInfoPanelContinueButtonLabel,
            allowButtonA11yId: AccessibilityIdentifiers.Summarizer.tosAllowButton,
            allowButtonA11yLabel: .Summarizer.ToSAlertAllowButtonAccessibilityLabel,
            cancelButtonTitle: .Summarizer.ToSAlertCancelButtonLabel,
            cancelButtonA11yId: AccessibilityIdentifiers.Summarizer.tosCancelButton,
            cancelButtonA11yLabel: .Summarizer.ToSAlertCancelButtonAccessibilityLabel
        )

        let model = SummarizeViewModel(
            titleLabelA11yId: AccessibilityIdentifiers.Summarizer.titleLabel,
            compactTitleLabelA11yId: AccessibilityIdentifiers.Summarizer.compactTitleLabel,
            summaryFootnote: .Summarizer.FootnoteLabel,
            summarizeViewA11yId: AccessibilityIdentifiers.Summarizer.summaryTableView,
            tabSnapshotViewModel: TabSnapshotViewModel(
                tabSnapshotA11yLabel: .Summarizer.TabSnapshotAccessibilityLabel,
                tabSnapshotA11yId: AccessibilityIdentifiers.Summarizer.tabSnapshotView,
                tabSnapshot: browserSnapshot,
                tabSnapshotTopOffset: browserSnapshotTopOffset
            ),
            loadingLabelViewModel: LoadingLabelViewModel(
                loadingLabel: .Summarizer.LoadingLabel,
                loadingA11yLabel: .Summarizer.LoadingAccessibilityLabel,
                loadingA11yId: AccessibilityIdentifiers.Summarizer.loadingLabel
            ),
            brandViewModel: BrandViewModel(
                brandLabel: brandLabel,
                brandLabelA11yId: AccessibilityIdentifiers.Summarizer.brandLabel,
                brandImage: brandImage,
                brandImageA11yId: AccessibilityIdentifiers.Summarizer.brandImage
            ),
            closeButtonModel: CloseButtonViewModel(
                a11yLabel: .Summarizer.CloseButtonAccessibilityLabel,
                a11yIdentifier: AccessibilityIdentifiers.Summarizer.closeSummaryButton
            ),
            errorMessages: errorModel,
            tosViewModel: tosViewModel
        )

        let controller = SummarizeController(
            windowUUID: windowUUID,
            viewModel: model,
            summarizerService: service,
            navigationHandler: self,
            webView: webView,
            isTosAccepted: prefs.boolForKey(PrefsKeys.Summarizer.didAgreeTermsOfService) ?? false,
            onSummaryDisplayed: { [weak self] in
                self?.summarizerTelemetry.summarizationDisplayed()
            }
        )
        let navController = UINavigationController(rootViewController: controller)

        navController.modalTransitionStyle = .crossDissolve
        navController.modalPresentationStyle = .overFullScreen
        router.present(navController, animated: true)
    }

    private func dismissCoordinator() {
        parentCoordinatorDelegate?.didFinish(from: self)
    }

    // MARK: - SummarizeNavigationHandler

    func openURL(url: URL) {
        onRequestOpenURL?(url)
    }

    func acceptToSConsent() {
        prefs.setBool(true, forKey: PrefsKeys.Summarizer.didAgreeTermsOfService)
        summarizerTelemetry.summarizationConsentDisplayed(true)
    }

    func denyToSConsent() {
        summarizerTelemetry.summarizationConsentDisplayed(false)
    }

    func dismissSummary() {
        summarizerTelemetry.summarizationClosed()
        dismissCoordinator()
    }

    // MARK: – SummarizerServiceLifecycle callbacks

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
