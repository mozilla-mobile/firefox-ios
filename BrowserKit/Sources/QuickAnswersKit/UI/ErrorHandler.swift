// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

@MainActor
final class ErrorHandler {
    private weak var presenter: UIViewController?
    private weak var navigationHandler: QuickAnswersNavigationHandler?

    init(
        presenter: UIViewController,
        navigationHandler: QuickAnswersNavigationHandler?
    ) {
        self.presenter = presenter
        self.navigationHandler = navigationHandler
    }

    // MARK: - Speech Errors
    // TODO: - FXIOS-14720 Add Strings and accessibility ids
    func handleSpeechError(_ error: SpeechError) {
        switch error {
        // if it is the first time the permission was viewed it means the OS alert was shown
        // in this case dismiss the view directly and don't show the custom alert.
        case .microphonePermissionDenied(let isFirstTime):
            handlePermissionDenied(
                isFirstTime: isFirstTime,
                title: "Change Settings to Use Quick Answers",
                message: "Allow Firefox to access the Microphone."
            )
        case .speechRecognitionPermissionDenied(let isFirstTime):
            handlePermissionDenied(
                isFirstTime: isFirstTime,
                title: "Change Settings to Use Quick Answers",
                message: "Allow Firefox to access Speech Recognition."
            )
        // TODO: - FXIOS-15572 Handle Speech errors that are not related to permissions
        default:
            break
        }
    }

    private func handlePermissionDenied(isFirstTime: Bool, title: String, message: String) {
        if isFirstTime {
            navigationHandler?.dismissQuickAnswers(with: nil)
        } else {
            showPermissionAlert(
                title: title,
                message: message
            )
        }
    }

    // MARK: - Search Errors
    func handleSearchError(_ error: ResultsServiceError) {
        let message: String
        switch error {
        case .invalidResponse(let statusCode):
            message = "Received an invalid response (status code: \(statusCode)). Please try again."
        case .noMessage:
            message = "No response was received. Please try again."
        case .rateLimited:
            message = "Too many requests. Please wait a moment and try again."
        case .requestCreationFailed:
            message = "Failed to create the request. Please try again."
        case .maxUsers:
            message = "Service is currently at capacity. Please try again later."
        case .payloadTooLarge:
            message = "Your request is too large. Please try a shorter query."
        case .unableToCreateService:
            message = "Unable to initialize the service. Please try again."
        case .unknown(let errorMessage):
            message = "An error occurred: \(errorMessage)"
        }

        showErrorAlert(
            title: "Quick Answers Error",
            message: message
        )
    }

    // MARK: - Other Errors
    func handleInitializationError() {
        showErrorAlert(
            title: "Quick Answers Error",
            message: "Failed to initialize Quick Answers. Please try again."
        )
    }

    // MARK: - Private

    // TODO: - FXIOS-14720 Add Strings and accessibility ids
    private func showPermissionAlert(title: String, message: String) {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(
            UIAlertAction(title: "Open Settings", style: .default) { [weak self] _ in
                self?.navigationHandler?.dismissQuickAnswers(with: nil)
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        )
        alertController.addAction(
            UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
                self?.navigationHandler?.dismissQuickAnswers(with: nil)
            }
        )
        presenter?.present(alertController, animated: true)
    }

    private func showErrorAlert(title: String, message: String) {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(
            UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                self?.navigationHandler?.dismissQuickAnswers(with: nil)
            }
        )
        presenter?.present(alertController, animated: true)
    }
}
