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
    func handleSearchError(_ error: SearchResultError) {
        // TODO: - FXIOS-15573 Handle Search errors
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
}
