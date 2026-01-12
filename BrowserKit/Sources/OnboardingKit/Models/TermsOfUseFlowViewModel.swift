// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

public final class TermsOfUseFlowViewModel<ViewModel: OnboardingCardInfoModelProtocol>: ObservableObject {
    public let configuration: ViewModel
    public let onTermsOfUseTap: () -> Void
    public let onPrivacyNoticeTap: () -> Void
    public let onManageSettingsTap: () -> Void
    public let onComplete: () -> Void

    public init(
        configuration: ViewModel,
        onTermsOfUseTap: @escaping () -> Void,
        onPrivacyNoticeTap: @escaping () -> Void,
        onManageSettingsTap: @escaping () -> Void = {},
        onComplete: @escaping () -> Void
    ) {
        self.configuration = configuration
        self.onTermsOfUseTap = onTermsOfUseTap
        self.onPrivacyNoticeTap = onPrivacyNoticeTap
        self.onManageSettingsTap = onManageSettingsTap
        self.onComplete = onComplete
    }

    public func handleEmbededLinkAction(
        action: TermsOfUseAction
    ) {
        switch action {
        case .accept:
            onComplete()
        case .openTermsOfService:
            onTermsOfUseTap()
        case .openPrivacyNotice:
            onPrivacyNoticeTap()
        case .openManageSettings:
            onManageSettingsTap()
        }
    }
}
