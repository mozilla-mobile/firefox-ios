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
                                  SummarizeTermOfServiceAcceptor,
                                  SummarizeNavigationHandler {
    private let browserSnapshot: UIImage
    private let browserSnapshotTopOffset: CGFloat
    private weak var parentCoordinatorDelegate: ParentCoordinatorDelegate?
    private let webView: WKWebView
    private let summarizerNimbusUtils: SummarizerNimbusUtils
    private var summarizerServiceFactory: SummarizerServiceFactory
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
        self.summarizerServiceFactory.lifecycleDelegate = self
    }

    func start() {
        summarizerTelemetry.summarizationRequested(trigger: trigger)
        showSummarizeViewController()
    }

    private func showSummarizeViewController() {
        let isAppleSummarizerEnabled = summarizerNimbusUtils.isAppleSummarizerEnabled()
        let isHostedSummarizerEnabled = summarizerNimbusUtils.isHostedSummarizerEnabled()
        let isAppAttestAuthEnabled = summarizerNimbusUtils.isAppAttestAuthEnabled()
        guard let service = summarizerServiceFactory.make(
            isAppleSummarizerEnabled: isAppleSummarizerEnabled,
            isHostedSummarizerEnabled: isHostedSummarizerEnabled,
            isAppAttestAuthEnabled: isAppAttestAuthEnabled,
            config: config) else { return }

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

        let errorModel = LocalizedErrorsViewConfiguration(
            rateLimitedMessage: .Summarizer.RateLimitedErrorMessage,
            unsafeContentMessage: .Summarizer.UnsafeWebsiteErrorMessage,
            summarizationNotAvailableMessage: .Summarizer.UnsupportedContentErrorMessage,
            pageStillLoadingMessage: .Summarizer.MissingPageContentErrorMessage,
            genericErrorMessage: .Summarizer.UnknownErrorMessage,
            errorContentA11yId: AccessibilityIdentifiers.Summarizer.errorContentView,
            retryButtonLabel: .Summarizer.RetryButtonLabel,
            retryButtonA11yLabel: .Summarizer.RetryButtonAccessibilityLabel,
            retryButtonA11yId: AccessibilityIdentifiers.Summarizer.retryErrorButton,
            closeButtonLabel: .Summarizer.CloseButtonLabel,
            closeButtonA11yLabel: .Summarizer.CloseButtonAccessibilityLabel,
            closeButtonA11yId: AccessibilityIdentifiers.Summarizer.closeSummaryErrorButton
        )

        let tosViewModel = TermOfServiceViewConfiguration(
            titleLabel: .Summarizer.ToSInfoPanelTitleLabel,
            descriptionText: String(
                format: .Summarizer.ToSInfoPanelLabel,
                AppName.shortName.rawValue
            ),
            linkButtonLabel: .Summarizer.ToSInfoPanelLinkButtonLabel,
            linkButtonURL: SupportUtils.URLForTopic("summarize-pages-ios"),
            allowButtonTitle: .Summarizer.ToSInfoPanelContinueButtonLabel,
            allowButtonA11yId: AccessibilityIdentifiers.Summarizer.tosAllowButton,
            allowButtonA11yLabel: .Summarizer.ToSInfoPanelAllowButtonAccessibilityLabel
        )

        let model = SummarizeViewConfiguration(
            titleLabelA11yId: AccessibilityIdentifiers.Summarizer.titleLabel,
            compactTitleLabelA11yId: AccessibilityIdentifiers.Summarizer.compactTitleLabel,
            summaryFootnote: .Summarizer.FootnoteLabel,
            summarizeViewA11yId: AccessibilityIdentifiers.Summarizer.summaryTableView,
            tabSnapshot: TabSnapshotViewConfiguration(
                tabSnapshotA11yLabel: .Summarizer.TabSnapshotAccessibilityLabel,
                tabSnapshotA11yId: AccessibilityIdentifiers.Summarizer.tabSnapshotView,
                tabSnapshot: browserSnapshot,
                tabSnapshotTopOffset: browserSnapshotTopOffset
            ),
            loadingLabel: LoadingLabelViewConfiguration(
                loadingLabel: .Summarizer.LoadingLabel,
                loadingA11yLabel: .Summarizer.LoadingAccessibilityLabel,
                loadingA11yId: AccessibilityIdentifiers.Summarizer.loadingLabel
            ),
            brandView: BrandViewConfiguration(
                brandLabel: brandLabel,
                brandLabelA11yId: AccessibilityIdentifiers.Summarizer.brandLabel,
                brandImage: brandImage,
                brandImageA11yId: AccessibilityIdentifiers.Summarizer.brandImage
            ),
            closeButton: CloseButtonViewModel(
                a11yLabel: .Summarizer.CloseButtonAccessibilityLabel,
                a11yIdentifier: AccessibilityIdentifiers.Summarizer.closeSummaryButton
            ),
            errorMessages: errorModel,
            termOfService: tosViewModel
        )

        let controller = SummarizeController(
            windowUUID: windowUUID,
            configuration: model,
            viewModel: DefaultSummarizeViewModel(
                summarizerService: service,
                summarizerTrigger: trigger,
                tosAcceptor: self,
                isTosAcceppted: prefs.boolForKey(PrefsKeys.Summarizer.didAgreeTermsOfService) ?? false
            ),
            navigationHandler: self,
            webView: webView
        ) { [weak self] in
            self?.summarizerTelemetry.summarizationDisplayed()
        }

        let navController = UINavigationController(rootViewController: controller)

        navController.modalTransitionStyle = .crossDissolve
        navController.modalPresentationStyle = .overFullScreen
        router.present(navController, animated: true)
    }

    private func dismissCoordinator() {
        parentCoordinatorDelegate?.didFinish(from: self)
    }

    // MARK: - SummarizeToSAcceptor

    func acceptConsent() {
        prefs.setBool(true, forKey: PrefsKeys.Summarizer.didAgreeTermsOfService)
        summarizerTelemetry.summarizationConsentDisplayed(true)
    }

    func denyConsent() {
        summarizerTelemetry.summarizationConsentDisplayed(false)
    }

    // MARK: - SummarizeNavigationHandler

    func openURL(url: URL) {
        onRequestOpenURL?(url)
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
