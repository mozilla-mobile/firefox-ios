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

public enum FxADeviceRegistrationResult {
    case Registered
    case Updated
    case AlreadyRegistered
}

public enum FxADeviceRegistratorError: MaybeErrorType {
    case AccountDeleted
    case CurrentDeviceNotFound
    case InvalidSession

    public var description: String {
        switch self {
        case AccountDeleted: return "Account no longer exists."
        case CurrentDeviceNotFound: return "Current device not found."
        case InvalidSession: return "Session token was invalid."
        }
    }
}

public class FxADeviceRegistrator {
    public static func registerOrUpdateDevice(account: FirefoxAccount, state: MarriedState) -> Deferred<Maybe<FxADeviceRegistrationResult>> {
        if let _ = account.fxaDeviceId where account.deviceRegistrationVersion == DeviceRegistrationVersion {
            return deferMaybe(FxADeviceRegistrationResult.AlreadyRegistered)
        }

        let client = FxAClient10(endpoint: account.configuration.authEndpointURL)
        let sessionToken = state.sessionToken
        let name = DeviceInfo.defaultClientName()
        let device: FxADevice
        let registrationResult: FxADeviceRegistrationResult
        if let deviceId = account.fxaDeviceId {
            device = FxADevice.forUpdate(name, id: deviceId)
            registrationResult = FxADeviceRegistrationResult.Updated
        } else {
            device = FxADevice.forRegister(name, type: "mobile")
            registrationResult = FxADeviceRegistrationResult.Registered
        }

        let registeredDevice = client.registerOrUpdateDevice(sessionToken, device: device)
        let deviceId: Deferred<Maybe<String>> = registeredDevice.bind { result in
            if let device = result.successValue {
                return deferMaybe(device.id!)
            }

            // Recover from the error -- if we can.
            if let error = result.failureValue as? FxAClientError,
               case .Remote(let remoteError) = error {
                switch (remoteError.code) {
                case FxAccountRemoteError.DeviceSessionConflict:
                    return recoverFromDeviceSessionConflict(account, client: client, sessionToken: sessionToken)
                case FxAccountRemoteError.InvalidAuthenticationToken:
                    return recoverFromTokenError(account, client: client)
                default: break
                }
            }

            // Not an error we can recover from. Rethrow it and fall back to the failure handler.
            return deferMaybe(result.failureValue!)
        }

        // Post-recovery. We either got the device ID or we didn't, but update the account either way.
        return deviceId.bind { result in
            switch result {
            case .Success(let deviceId):
                account.fxaDeviceId = deviceId.value
                account.deviceRegistrationVersion = DeviceRegistrationVersion
                return deferMaybe(registrationResult)
            case .Failure(let error):
                log.error("Device registration failed: \(error.description)")
                account.fxaDeviceId = nil
                account.deviceRegistrationVersion = 0
                return deferMaybe(error)
            }
        }
    }

    private static func recoverFromDeviceSessionConflict(account: FirefoxAccount, client: FxAClient10, sessionToken: NSData) -> Deferred<Maybe<String>> {
        log.warning("Device session conflict. Attempting to find the current device ID…")
        return client.devices(sessionToken) >>== { response in
            guard let currentDevice = response.devices.find({ $0.isCurrentDevice! }) else {
                return deferMaybe(FxADeviceRegistratorError.CurrentDeviceNotFound)
            }

            return deferMaybe(currentDevice.id!)
        }
    }

    private static func recoverFromTokenError(account: FirefoxAccount, client: FxAClient10) -> Deferred<Maybe<String>> {
        return client.status(account.uid) >>== { status in
            if !status.exists {
                // TODO: Should be in an "I have an iOS account, but the FxA is gone." state.
                // This will do for now...
                account.makeDoghouse()
                return deferMaybe(FxADeviceRegistratorError.AccountDeleted)
            }

            account.makeDoghouse()
            return deferMaybe(FxADeviceRegistratorError.InvalidSession)
        }
    }
}