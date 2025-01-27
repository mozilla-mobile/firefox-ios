// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared

enum LaunchCoordinatorType {
    case SceneCoordinator, BrowserCoordinator
}

enum LaunchType {
    /// Showing the terms of service
    case termsOfService(manager: TermsOfServiceManager)

    /// Showing the intro onboarding
    case intro(manager: IntroScreenManager)

    /// Show the update onboarding
    case update(viewModel: UpdateViewModel)

    /// Show the surface survey
    case survey(manager: SurveySurfaceManager)

    /// Show the default browser onboarding, only shown from deeplink
    case defaultBrowser

    /// We show full screen launch types from scene coordinator, other launch type are shown from browser coordinator
    /// - Parameters:
    ///   - type: The coordinator the launch type can happen from
    ///   - isIphone: True when the current device is of type iPhone
    /// - Returns: true if the launch type can be launched from a particular coordinator or not
    func canLaunch(fromType type: LaunchCoordinatorType,
                   isIphone: Bool = UIDevice.current.userInterfaceIdiom == .phone) -> Bool {
        switch type {
        case .BrowserCoordinator:
            return !isFullScreenAvailable(isIphone: isIphone)
        case .SceneCoordinator:
            return isFullScreenAvailable(isIphone: isIphone)
        }
    }

    /// We show full screen launch types from scene coordinator, other launch type are shown from browser coordinator
    /// - Parameter isIphone: True when the current device is of type iPhone
    /// - Returns: if the launch type needs to be full screen or not
    func isFullScreenAvailable(isIphone: Bool = UIDevice.current.userInterfaceIdiom == .phone) -> Bool {
        switch self {
        case .termsOfService:
            return true
        case .intro, .update:
            return isIphone
        case .survey:
            return true
        case .defaultBrowser:
            return false
        }
    }
}
