// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

public class OnboardingViewModel: ObservableObject {
    public init(config: GetStartedOnboardingViewConfig, defaultBrowserConfig: DefaultBrowserViewConfig, dismissAction: @escaping () -> Void, telemetry: @escaping (OnboardingViewModel.Action) -> Void) {
        self.config = config
        self.defaultBrowserConfig = defaultBrowserConfig
        self.dismissAction = dismissAction
        self.telemetry = telemetry
    }

    public enum Action {
        case getStartedAppeared
        case getStartedCloseTapped
        case getStartedButtonTapped
        case defaultBrowserCloseTapped
        case defaultBrowserSettingsTapped
        case defaultBrowserSkip
        case defaultBrowserAppeared
    }

    public let config: GetStartedOnboardingViewConfig
    public let defaultBrowserConfig: DefaultBrowserViewConfig
    public let dismissAction: () -> Void
    public let telemetry: (Action) -> Void

    public func send(_ action: Action) {
        telemetry(action)
        switch action {
            case .getStartedAppeared:
                break
            case .getStartedCloseTapped:
                dismissAction()
            case .getStartedButtonTapped:
                break
            case .defaultBrowserCloseTapped:
                dismissAction()
            case .defaultBrowserSettingsTapped:
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            case .defaultBrowserSkip:
                dismissAction()
            case .defaultBrowserAppeared:
                break
        }
    }
}
