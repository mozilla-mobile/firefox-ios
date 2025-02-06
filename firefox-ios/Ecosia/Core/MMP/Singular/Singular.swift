// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

#if os(iOS)

public struct Singular: MMPProvider {

    let singularService: SingularServiceProtocol
    let skanHelper: SingularAdNetworkHelperProtocol?

    init(singularService: SingularServiceProtocol = SingularService(),
         skanHelper: SingularAdNetworkHelperProtocol? = SingularAdNetworkHelper()) {
        self.singularService = singularService
        self.skanHelper = skanHelper
    }

    /// Initializer for Singular as MMPProvider.
    /// - Parameters:
    ///   - includeSKAN: If true, all required logic for SKAdNetwork will be executed (e.g. register on first session or fetch updated conversion values from singular server before any event)
    public init(includeSKAN: Bool) {
        self.singularService = SingularService()
        self.skanHelper = includeSKAN ? SingularAdNetworkHelper() : nil
    }

    /// Reports a session to the Singular service.
    /// - Parameters:
    ///     - appDeviceInfo: The device info parameters being set to Singular session endpoint.
    public func sendSessionInfo(appDeviceInfo: AppDeviceInfo) async throws {
        let sessionIdentifier = User.shared.analyticsId.uuidString

        var skanParameters: [String: String]?
        if let skanHelper = skanHelper {
            if skanHelper.isRegistered {
                try? await skanHelper.fetchFromSingularServerAndUpdate(forEvent: .session,
                                                                       sessionIdentifier: sessionIdentifier,
                                                                       appDeviceInfo: appDeviceInfo)
            } else {
                try? await skanHelper.registerAppForAdNetworkAttribution()
            }

            skanParameters = skanHelper.persistedValuesDictionary
        }

        let request = SingularSessionInfoSendRequest(identifier: sessionIdentifier, info: appDeviceInfo, skanParameters: skanParameters)
        try await singularService.sendNotification(request: request)
    }

    /// Reports an event to the Singular service.
    /// - Parameters:
    ///     - event: MMPEvent in question out of the supported cases
    ///     - appDeviceInfo: The device info parameters being set to Singular session endpoint.
    public func sendEvent(_ event: MMPEvent, appDeviceInfo: AppDeviceInfo) async throws {
        let sessionIdentifier = User.shared.analyticsId.uuidString
        let request = SingularEventRequest(identifier: sessionIdentifier, name: event.rawValue, info: appDeviceInfo)
        try await singularService.sendNotification(request: request)
    }
}

#endif
