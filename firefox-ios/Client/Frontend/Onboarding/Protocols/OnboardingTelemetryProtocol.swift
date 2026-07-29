// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum OnboardingReason: String {
    case newUser = "new_user"
    case showTour = "show_tour"
}

protocol OnboardingTelemetryProtocol: AnyObject {
    func sendGoToSettingsButtonTappedTelemetry()
    func sendDismissButtonTappedTelemetry()
    func sendWallpaperSelectorViewTelemetry()
    func sendWallpaperSelectorCloseTelemetry()
    func sendWallpaperSelectorSelectedTelemetry(wallpaperName: String, wallpaperType: String)
}
