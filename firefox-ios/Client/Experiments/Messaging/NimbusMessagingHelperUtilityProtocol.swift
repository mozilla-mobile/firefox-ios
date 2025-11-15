// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

import protocol MozillaAppServices.NimbusMessagingHelperProtocol

protocol NimbusMessagingHelperUtilityProtocol: Sendable {
    @MainActor
    func createNimbusMessagingHelper() -> NimbusMessagingHelperProtocol?
}

final class NimbusMessagingHelperUtility: NimbusMessagingHelperUtilityProtocol {
    private let createMessageHelper: @MainActor @Sendable () -> NimbusMessagingHelperProtocol?

    init(
        createMessageHelper: @MainActor @escaping @Sendable () -> NimbusMessagingHelperProtocol?
                             = Experiments.createJexlHelper
    ) {
        self.createMessageHelper = createMessageHelper
    }

    @MainActor
    func createNimbusMessagingHelper() -> NimbusMessagingHelperProtocol? {
        createMessageHelper()
    }
}
