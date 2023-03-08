// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

class SurveySurfaceManager {
    private var message: GleanPlumbMessage?
    private let messagingManager: GleanPlumbMessageManagerProtocol
    private let themeManager: ThemeManager

    private var viewModel: SurveySurfaceViewModel?
    private var viewController: SurveySurfaceViewController?

    var shouldShowSurveySurface: Bool {
        updateMessage()
        if message != nil { return true }
        return false
    }

    init(with themeManager: ThemeManager,
         and messagingManager: GleanPlumbMessageManagerProtocol = GleanPlumbMessageManager.shared
    ) {
        self.messagingManager = messagingManager
        self.themeManager = themeManager
    }

    func surveySurface() -> SurveySurfaceViewController? {
        guard let message = message else { return nil }
        
        let viewModel = SurveySurfaceViewModel(with: message,
                                               theme: theme,
                                               and: messagingManager)

        let viewController = SurveySurfaceViewController(viewModel: viewModel)

        return viewController
    }

    /// Call messagingManager to retrieve the message for research surface
    private func updateMessage(for surface: MessageSurfaceId = .survey) {
        guard let validMessage = messagingManager.getNextMessage(for: surface) else { return }

        if !validMessage.isExpired {
            message = validMessage
        }
    }
}
