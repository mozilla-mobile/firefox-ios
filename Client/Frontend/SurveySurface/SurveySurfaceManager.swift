// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

class SurveySurfaceManager {
    private var message: GleanPlumbMessage?
    private var messagingManager: GleanPlumbMessageManagerProtocol
    private var themeManager: ThemeManager
    private var notificationCenter: NotificationProtocol

    private var viewModel: SurveySurfaceViewModel?
    private var viewController: SurveySurfaceViewController?

    var shouldShowSurveySurface: Bool {
        updateMessage()
        if message != nil { return true }
        return false
    }

    init(with themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         and messagingManager: GleanPlumbMessageManagerProtocol = GleanPlumbMessageManager.shared
    ) {
        self.messagingManager = messagingManager
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
    }

    func surveySurface() -> SurveySurfaceViewController? {
        guard let message = message,
              !message.isExpired,
              let image = UIImage(named: ImageIdentifiers.logo)
        else { return nil }

        let info = SurveySurfaceInfoModel(text: message.data.text,
                                          takeSurveyButtonLabel: message.data.buttonLabel ?? .ResearchSurface.TakeSurveyButtonLabel,
                                          dismissActionLabel: .ResearchSurface.DismissButtonLabel,
                                          image: image)

        let viewModel = SurveySurfaceViewModel(with: info)

        let viewController = SurveySurfaceViewController(viewModel: viewModel,
                                                         themeManager: themeManager,
                                                         notificationCenter: notificationCenter)

        return viewController
    }

    /// Call messagingManager to retrieve the message for research surface.
    private func updateMessage(for surface: MessageSurfaceId = .survey) {
        // Set the message to nil just to make sure we're not accidentally showing an
        // old message.
        message = nil
        guard let validMessage = messagingManager.getNextMessage(for: surface) else { return }

        if !validMessage.isExpired {
            message = validMessage
        }
    }
}
