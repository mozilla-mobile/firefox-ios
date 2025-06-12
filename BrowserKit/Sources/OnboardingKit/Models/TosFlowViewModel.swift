// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

public class TosFlowViewModel<VM: OnboardingKit.OnboardingCardInfoModelProtocol>: ObservableObject {
    public let configuration: VM
    public let onTermsOfServiceTap: () -> Void
    public let onPrivacyNoticeTap: () -> Void
    public let onManageSettingsTap: () -> Void
    public let onComplete: () -> Void

    public init(
        configuration: VM,
        onTermsOfServiceTap: @escaping () -> Void,
        onPrivacyNoticeTap: @escaping () -> Void,
        onManageSettingsTap: @escaping () -> Void = {},
        onComplete: @escaping () -> Void
    ) {
        self.configuration = configuration
        self.onTermsOfServiceTap = onTermsOfServiceTap
        self.onPrivacyNoticeTap = onPrivacyNoticeTap
        self.onManageSettingsTap = onManageSettingsTap
        self.onComplete = onComplete
    }

    public func handleEmbededLinkAction(
        action: TosAction
    ) {
        switch action {
        case .accept:
            onComplete()
        case .openTermsOfService:
            onTermsOfServiceTap()
        case .openPrivacyNotice:
            onPrivacyNoticeTap()
        case .openManageSettings:
            onManageSettingsTap()
        }
    }
}
