// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

enum Screen: CaseIterable {
    case tos
    case getStarted
    case `default`
}

public class OnboardingViewModel: ObservableObject {
    public enum Action {
        case getStartedAppeared
        case getStartedCloseTapped
        case getStartedButtonTapped
        case defaultBrowserCloseTapped
        case defaultBrowserSettingsTapped
        case defaultBrowserSkip
        case defaultBrowserAppeared
        // Terms Of Service
        case onAcceptAndContinueTapped
        case openTermsOfUse(URL)
        case openPrivacyNotice(URL)
    }

    public let config: GetStartedOnboardingViewConfig
    public let defaultBrowserConfig: DefaultBrowserViewConfig
    public let tosConfig: TermsOfServiceConfig
    public let dismissAction: () -> Void
    public let telemetry: (Action) -> Void
    let isTosEnabled: Bool
    let termsURL: URL
    let privacyURL: URL
    @Published var activeScreen = Screen.getStarted
    @Published var privacyPolicyURL: URL?

    public init(
        config: GetStartedOnboardingViewConfig,
        defaultBrowserConfig: DefaultBrowserViewConfig,
        tosConfig: TermsOfServiceConfig,
        isTosEnabled: Bool,
        termsURL: URL,
        privacyURL: URL,
        dismissAction: @escaping () -> Void,
        telemetry: @escaping (OnboardingViewModel.Action) -> Void
    ) {
        self.config = config
        self.defaultBrowserConfig = defaultBrowserConfig
        self.tosConfig = tosConfig
        self.isTosEnabled = isTosEnabled
        self.dismissAction = dismissAction
        self.telemetry = telemetry
        self.activeScreen = isTosEnabled ? .tos : .getStarted
        self.termsURL = termsURL
        self.privacyURL = privacyURL
    }

    func open(_ screen: Screen) {
        activeScreen = screen
    }

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
        case .onAcceptAndContinueTapped:
            activeScreen = .default
        case let .openTermsOfUse(url):
            privacyPolicyURL = url
        case let .openPrivacyNotice(url):
            privacyPolicyURL = url
        }
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
