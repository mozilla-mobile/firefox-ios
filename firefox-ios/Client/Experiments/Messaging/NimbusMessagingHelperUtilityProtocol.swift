// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

import protocol MozillaAppServices.NimbusMessagingHelperProtocol

protocol NimbusMessagingHelperUtilityProtocol: Sendable {
    func createNimbusMessagingHelper() -> NimbusMessagingHelperProtocol?
}

final class NimbusMessagingHelperUtility: NimbusMessagingHelperUtilityProtocol {
    private let createMessageHelper: @Sendable () -> NimbusMessagingHelperProtocol?

    init(createMessageHelper: @escaping @Sendable () -> NimbusMessagingHelperProtocol? = Experiments.createJexlHelper) {
        self.createMessageHelper = createMessageHelper
    }

    func createNimbusMessagingHelper() -> NimbusMessagingHelperProtocol? {
        createMessageHelper()
    }
}
