// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import QuickAnswersKit
import Common
import Shared
import UIKit

final class QuickAnswersCoordinator: BaseCoordinator, QuickAnswersNavigationHandler {
    private weak var parentCoordinatorDelegate: ParentCoordinatorDelegate?
    private let prefs: Prefs
    private let windowUUID: WindowUUID
    private let themeManager: ThemeManager
    private let transitionType: QuickAnswersTransitionType
    private let featureFlagsProvider: FeatureFlagProviding
    private let onNavigate: (QuickAnswersNavigationType) -> Void
    private var shouldAnimateTransition: Bool {
        return !UIAccessibility.isReduceMotionEnabled
    }
    /// The SUMO link for quick answer.
    static let learnMoreURL = SupportUtils.URLForTopic("quick-answers-mobile")

    init(
        parentCoordinatorDelegate: ParentCoordinatorDelegate?,
        prefs: Prefs,
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        router: Router,
        transitionType: QuickAnswersTransitionType,
        featureFlagsProvider: FeatureFlagProviding = AppContainer.shared.resolve(),
        onNavigate: @escaping (QuickAnswersNavigationType) -> Void,
    ) {
        self.parentCoordinatorDelegate = parentCoordinatorDelegate
        self.prefs = prefs
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.transitionType = transitionType
        self.featureFlagsProvider = featureFlagsProvider
        self.onNavigate = onNavigate
        super.init(router: router)
    }

    func start() {
        let controller = QuickAnswersViewController(
            navigationHandler: self,
            transitionType: transitionType,
            prefs: prefs,
            windowUUID: windowUUID,
            themeManager: themeManager,
            telemetry: DefaultQuickAnswersTelemetry(),
            configFetcher: RemoteQuickAnswersConfigFetcher(feature: resolvedFeature()),
            learnMoreURL: Self.learnMoreURL,
            stringsConfiguration: makeStringsConfiguration()
        )
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = controller.modalPresentationStyle
        navigationController.transitioningDelegate = controller.transitioningDelegate
        router.present(navigationController, animated: shouldAnimateTransition)
    }

    private func makeStringsConfiguration() -> QuickAnswersViewConfiguration {
        let appName = AppName.shortName.rawValue
        return QuickAnswersViewConfiguration(
            optIn: .init(
                title: .QuickAnswers.OptIn.Title,
                description: .QuickAnswers.OptIn.Description,
                learnMore: .QuickAnswers.OptIn.LearnMore,
                continueButton: .QuickAnswers.OptIn.ContinueButton
            ),
            optInRedesign: .init(
                title: .QuickAnswers.OptInRedesign.Title,
                description: .QuickAnswers.OptInRedesign.Description,
                nothingGetsSavedTitle: .QuickAnswers.OptInRedesign.NothingGetsSavedTitle,
                nothingGetsSavedDescription: .QuickAnswers.OptInRedesign.NothingGetsSavedDescription,
                privateByDesignTitle: .QuickAnswers.OptInRedesign.PrivateByDesignTitle,
                privateByDesignDescription: .QuickAnswers.OptInRedesign.PrivateByDesignDescription,
                noTrainingTitle: .QuickAnswers.OptInRedesign.NoTrainingTitle,
                noTrainingDescription: .QuickAnswers.OptInRedesign.NoTrainingDescription,
                learnMore: .QuickAnswers.LearnMore,
                continueButton: .QuickAnswers.OptIn.ContinueButton
            ),
            contentView: .init(
                placeholder: .QuickAnswers.ContentView.Placeholder,
                answering: .QuickAnswers.ContentView.Answering,
                footerFormat: .QuickAnswers.ContentView.FooterFormat,
                sources: .QuickAnswers.ContentView.Sources,
                aboutYourPrivacy: .QuickAnswers.ContentView.AboutYourPrivacy,
                answerHeader: .QuickAnswers.ContentView.ResultHeader
            ),
            privacyBanner: .init(
                title: .QuickAnswers.PrivacyBanner.Title,
                description: String(format: .QuickAnswers.PrivacyBanner.DescriptionFormat, appName)
            ),
            errors: .init(
                permissionAlertTitle: .QuickAnswers.Errors.PermissionAlertTitle,
                microphonePermissionMessage: String(format: .QuickAnswers.Errors.MicrophonePermissionMessage, appName),
                speechRecognitionPermissionMessage: String(
                    format: .QuickAnswers.Errors.SpeechRecognitionPermissionMessage,
                    appName
                ),
                openSettings: .QuickAnswers.Errors.OpenSettings,
                cancel: .QuickAnswers.Errors.Cancel,
                dailyLimitTitle: .QuickAnswers.Errors.DailyLimitTitle,
                dailyLimitMessage: .QuickAnswers.Errors.DailyLimitMessage,
                genericErrorTitle: .QuickAnswers.Errors.GenericErrorTitle,
                genericErrorMessage: .QuickAnswers.Errors.GenericErrorMessage,
                ok: .QuickAnswers.Errors.OK
            ),
            closeAccessibilityLabel: .QuickAnswers.AccessibilityLabels.Close,
            appName: appName
        )
    }

    func resolvedFeature() -> QuickAnswersKit.QuickAnswersFeature {
        return QuickAnswersKit.QuickAnswersFeature(
            model: resolvedModel(),
            isOptInRedesignEnabled: featureFlagsProvider.isEnabled(.quickAnswersOptInRedesign)
        )
    }

    /// The model backing Quick Answers: the debug override set from the hidden settings when
    /// present, the Nimbus configured one otherwise.
    func resolvedModel() -> QuickAnswersKit.QuickAnswersModel {
        guard let rawValue = prefs.stringForKey(PrefsKeys.QuickAnswers.modelOverride),
              let overriddenModel = QuickAnswersKit.QuickAnswersModel(rawValue: rawValue) else {
            return nimbusModel()
        }
        return overriddenModel
    }

    /// Reads the Nimbus-configured Quick Answers model and maps it to the `QuickAnswersKit` enum,
    /// falling back to `.exa` if the value is unrecognized.
    private func nimbusModel() -> QuickAnswersKit.QuickAnswersModel {
        let rawValue = FxNimbus.shared.features.quickAnswersFeature.value().model.rawValue
        return QuickAnswersKit.QuickAnswersModel(rawValue: rawValue) ?? .exa
    }

    // MARK: - QuickAnswersNavigationHandler
    func dismissQuickAnswers(with navigationType: QuickAnswersNavigationType?) {
        if let navigationType {
            onNavigate(navigationType)
        }
        router.dismiss(animated: shouldAnimateTransition)
        parentCoordinatorDelegate?.didFinish(from: self)
    }
}
