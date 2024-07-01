// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

protocol SurveySurfaceDelegate: AnyObject {
    func didDisplayMessage()
    func didTapTakeSurvey()
    func didTapDismissSurvey()
}

class SurveySurfaceManager: SurveySurfaceDelegate {
    // MARK: - Properties
    private let windowUUID: WindowUUID
    private let surveySurfaceID: MessageSurfaceId = .survey
    private var message: GleanPlumbMessage?
    private var messagingManager: GleanPlumbMessageManagerProtocol
    private var themeManager: ThemeManager
    private var notificationCenter: NotificationProtocol
    private var viewModel: SurveySurfaceViewModel?
    private var viewController: SurveySurfaceViewController?

    var shouldShowSurveySurface: Bool {
        // TODO: Remove hack (temporary fix to avoid showing SurveySurface in UITest for release branch)
        if AppConstants.isRunningUITests { return false }
        updateMessage()
        return message != nil
    }

    // MARK: - Initialization
    init(windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         and messagingManager: GleanPlumbMessageManagerProtocol = Experiments.messaging
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.messagingManager = messagingManager
    }

    // MARK: - Functionality
    /// Checks whether a message exists, and is not expired, and attempts to
    /// build a `SurveySurfaceViewController` to be presented.
    ///
    /// - Returns: An optional `SurveySurfaceViewController`
    func getSurveySurface() -> SurveySurfaceViewController? {
        guard let message = message,
              let image = UIImage(named: ImageIdentifiers.logo)
        else { return nil }

        let info = SurveySurfaceInfoModel(
            text: message.text,
            takeSurveyButtonLabel: message.buttonLabel ?? .ResearchSurface.TakeSurveyButtonLabel,
            dismissActionLabel: .ResearchSurface.DismissButtonLabel,
            image: image
        )

        let viewModel = SurveySurfaceViewModel(with: info, delegate: self)

        return SurveySurfaceViewController(windowUUID: windowUUID,
                                           viewModel: viewModel,
                                           themeManager: themeManager,
                                           notificationCenter: notificationCenter)
    }

    /// Call messagingManager to retrieve the message for research surface.
    private func updateMessage() {
        message = messagingManager.getNextMessage(for: surveySurfaceID)
    }

    // MARK: - MessageSurfaceProtocol
    func didDisplayMessage() {
        message.map(messagingManager.onMessageDisplayed)
    }

    func didTapTakeSurvey() {
        guard let message else { return }
        messagingManager.onMessagePressed(message, window: nil, shouldExpire: true)
    }

    func didTapDismissSurvey() {
        message.map(messagingManager.onMessageDismissed)
    }
}
