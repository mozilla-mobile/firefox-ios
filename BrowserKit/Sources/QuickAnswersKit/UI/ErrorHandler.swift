// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared

@MainActor
final class ErrorHandler {
    private weak var presenter: UIViewController?
    private var onDismiss: (() -> Void)?

    init(
        presenter: UIViewController,
        onDismiss: (() -> Void)?
    ) {
        self.presenter = presenter
        self.onDismiss = onDismiss
    }

    // MARK: - Speech Errors
    func handleSpeechError(_ error: SpeechError) {
        switch error {
        // if it is the first time the permission was viewed it means the OS alert was shown
        // in this case dismiss the view directly and don't show the custom alert.
        case .microphonePermissionDenied(let isFirstTime):
            handlePermissionDenied(
                isFirstTime: isFirstTime,
                title: .QuickAnswers.Errors.PermissionAlertTitle,
                message: String(format: .QuickAnswers.Errors.MicrophonePermissionMessage, AppName.shortName.rawValue)
            )
        case .speechRecognitionPermissionDenied(let isFirstTime):
            handlePermissionDenied(
                isFirstTime: isFirstTime,
                title: .QuickAnswers.Errors.PermissionAlertTitle,
                message: String(format: .QuickAnswers.Errors.SpeechRecognitionPermissionMessage, AppName.shortName.rawValue)
            )
        default:
            showCatchAllErrorAlert()
        }
    }

    private func handlePermissionDenied(isFirstTime: Bool, title: String, message: String) {
        if isFirstTime {
            onDismiss?()
        } else {
            showPermissionAlert(
                title: title,
                message: message
            )
        }
    }

    // MARK: - Search Errors
    func handleSearchError(_ error: ResultsServiceError) {
        switch error {
        case .rateLimited:
            showCatchAllErrorAlert(
                title: .QuickAnswers.Errors.DailyLimitTitle,
                message: .QuickAnswers.Errors.DailyLimitMessage
            )
        default:
            showCatchAllErrorAlert()
        }
    }

    // MARK: - Private

    private func showPermissionAlert(title: String, message: String) {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(
            UIAlertAction(title: .QuickAnswers.Errors.OpenSettings, style: .default) { [weak self] _ in
                self?.onDismiss?()
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        )
        alertController.addAction(
            UIAlertAction(title: .QuickAnswers.Errors.Cancel, style: .cancel) { [weak self] _ in
                self?.onDismiss?()
            }
        )
        presenter?.present(alertController, animated: true)
    }

    private func showCatchAllErrorAlert(
        title: String = .QuickAnswers.Errors.GenericErrorTitle,
        message: String = .QuickAnswers.Errors.GenericErrorMessage
    ) {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(
            UIAlertAction(title: .QuickAnswers.Errors.OK, style: .default) { [weak self] _ in
                self?.onDismiss?()
            }
        )
        presenter?.present(alertController, animated: true)
    }
}
