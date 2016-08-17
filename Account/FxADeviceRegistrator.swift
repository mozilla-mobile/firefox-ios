/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Deferred
import Shared

private let log = Logger.syncLogger

// The current version of the device registration, we use this to re-register
// devices after we update what we send on device registration.
private let DeviceRegistrationVersion = 1

public class FxADeviceRegistrator {
    public enum DeviceRegistratorError: MaybeErrorType {
        case DeviceRegistrationFailed

        public var description: String {
            switch self {
            case DeviceRegistrationFailed: return "Device registration failed."
            }
        }
    }

    public static func registerOrUpdateDevice(account: FirefoxAccount, state: MarriedState) -> Deferred<Maybe<String>> {
        if let deviceId = account.fxaDeviceId where account.deviceRegistrationVersion == DeviceRegistrationVersion {
            return Deferred(value: Maybe(success: deviceId))
        }

        let client = FxAClient10(endpoint: account.configuration.authEndpointURL)
        let sessionToken = state.sessionToken
        let name = DeviceInfo.defaultClientName()
        let device: FxADevice
        if let deviceId = account.fxaDeviceId {
            device = FxADevice.forUpdate(name, id: deviceId)
        } else {
            device = FxADevice.forRegister(name, type: "mobile")
        }

        return client.registerOrUpdateDevice(sessionToken, device: device).bind { result in
            let deferred = Deferred<Maybe<String>>()

            if let device = result.successValue,
                let deviceId = device.id {
                account.fxaDeviceId = deviceId
                account.deviceRegistrationVersion = DeviceRegistrationVersion
                deferred.fill(Maybe(success: deviceId))
                return deferred
            }

            let error = result.failureValue as? FxAClientError
            switch (error) {
            case let .Remote(remoteError)?:
                switch (remoteError.code) {
                case FxAccountRemoteError.DEVICE_SESSION_CONFLICT:
                    recoverFromDeviceSessionConflict(account, client: client, deferred: deferred, sessionToken: sessionToken)
                case FxAccountRemoteError.UNKNOWN_DEVICE:
                    // TODO: Shouldn't this also clear registration version? Android doesn't.
                    handleUnknownDevice(account)
                case FxAccountRemoteError.INVALID_AUTHENTICATION_TOKEN:
                    logErrorAndResetDeviceRegistrationVersion(account, description: String(remoteError))
                    handleTokenError(account, client: client)
                default:
                    logErrorAndResetDeviceRegistrationVersion(account, description: String(remoteError))
                }
            case let .Local(localError)?:
                self.logErrorAndResetDeviceRegistrationVersion(account, description: localError.description)
            default:
                // This shouldn't happen.
                self.logErrorAndResetDeviceRegistrationVersion(account, description: "invalid error type")
                assertionFailure()
            }

            deferred.fillIfUnfilled(Maybe(failure: DeviceRegistratorError.DeviceRegistrationFailed))

            return deferred
        }
    }

    private static func handleUnknownDevice(account: FirefoxAccount) {
        log.info("unknown device id, clearing the cached device id")
        account.fxaDeviceId = nil
    }

    private static func recoverFromDeviceSessionConflict(account: FirefoxAccount, client: FxAClient10, deferred: Deferred<Maybe<String>>, sessionToken: NSData) {
        log.warning("device session conflict, attempting to ascertain the correct device id")
        client.devices(sessionToken).upon { response in
            if let success = response.successValue,
                let currentDevice = success.devices.find({ $0.isCurrentDevice }) {
                deferred.fill(Maybe(success: currentDevice.id))
            } else {
                self.logErrorAndResetDeviceRegistrationVersion(account, description: "conflict recovery failed: \(response.failureValue?.description ?? "")")
                deferred.fill(Maybe(failure: DeviceRegistratorError.DeviceRegistrationFailed))
            }
        }
    }

    private static func handleTokenError(account: FirefoxAccount, client: FxAClient10) {
        client.status(account.uid).upon() { result in
            if let status = result.successValue {
                if !status.exists {
                    log.info("token was invalidated because the account no longer exists")
                    // TODO: Should be in a "I have an Android account, but the FxA is gone." State.
                    // This will do for now..
                    account.makeDoghouse()
                } else {
                    log.error("the session token was invalid")
                    account.makeDoghouse()
                }
            }
        }
    }

    private static func logErrorAndResetDeviceRegistrationVersion(account: FirefoxAccount, description: String) {
        log.error("device registration failed: \(description)")
        account.deviceRegistrationVersion = 0
    }
}