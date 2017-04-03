/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Deferred
import Shared

private let log = Logger.syncLogger

/// The current version of the device registration. We use this to re-register
/// devices after we update what we send on device registration.
private let DeviceRegistrationVersion = 1

public enum FxADeviceRegistrationResult {
    case registered
    case updated
    case alreadyRegistered
}

public enum FxADeviceRegistratorError: MaybeErrorType {
    case accountDeleted
    case currentDeviceNotFound
    case invalidSession
    case unknownDevice

    public var description: String {
        switch self {
        case .accountDeleted: return "Account no longer exists."
        case .currentDeviceNotFound: return "Current device not found."
        case .invalidSession: return "Session token was invalid."
        case .unknownDevice: return "Unknown device."
        }
    }
}

open class FxADeviceRegistration: NSObject, NSCoding {
    /// The device identifier identifying this device.  A device is uniquely identified
    /// across the lifetime of a Firefox Account.
    public let id: String

    /// The version of the device registration. We use this to re-register
    /// devices after we update what we send on device registration.
    let version: Int

    /// The last time we successfully (re-)registered with the server.
    let lastRegistered: Timestamp

    init(id: String, version: Int, lastRegistered: Timestamp) {
        self.id = id
        self.version = version
        self.lastRegistered = lastRegistered
    }

    public convenience required init(coder: NSCoder) {
        let id = coder.decodeObject(forKey: "id") as! String
        let version = coder.decodeAsInt(forKey: "version")
        let lastRegistered = coder.decodeAsUInt64(forKey: "lastRegistered")
        self.init(id: id, version: version, lastRegistered: lastRegistered)
    }

    open func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: "id")
        aCoder.encode(version, forKey: "version")
        aCoder.encode(NSNumber(value: lastRegistered), forKey: "lastRegistered")
    }
}

open class FxADeviceRegistrator {
    open static func registerOrUpdateDevice(_ account: FirefoxAccount, sessionToken: NSData, client: FxAClient10? = nil) -> Deferred<Maybe<FxADeviceRegistrationResult>> {
        // If we've already registered, the registration version is up-to-date, *and* we've (re-)registered
        // within the last week, do nothing. We re-register weekly as a sanity check.
        if let registration = account.deviceRegistration, registration.version == DeviceRegistrationVersion &&
            Date.now() < registration.lastRegistered + OneWeekInMilliseconds {
                return deferMaybe(FxADeviceRegistrationResult.alreadyRegistered)
        }

        let pushParams: FxADevicePushParams?
        if AppConstants.MOZ_FXA_PUSH, let pushRegistration = account.pushRegistration {
            let subscription = pushRegistration.defaultSubscription
            pushParams = FxADevicePushParams(callback: subscription.endpoint.absoluteString, publicKey: subscription.p256dhPublicKey, authKey: subscription.authKey)
        } else {
            pushParams = nil
        }

        let client = client ?? FxAClient10(endpoint: account.configuration.authEndpointURL)
        let name = DeviceInfo.defaultClientName()
        let device: FxADevice
        let registrationResult: FxADeviceRegistrationResult
        if let registration = account.deviceRegistration {
            device = FxADevice.forUpdate(name, id: registration.id, push: pushParams)
            registrationResult = FxADeviceRegistrationResult.updated
        } else {
            device = FxADevice.forRegister(name, type: "mobile", push: pushParams)
            registrationResult = FxADeviceRegistrationResult.registered
        }

        let registeredDevice = client.registerOrUpdate(device: device, withSessionToken: sessionToken)
        let registration: Deferred<Maybe<FxADeviceRegistration>> = registeredDevice.bind { result in
            if let device = result.successValue {
                return deferMaybe(FxADeviceRegistration(id: device.id!, version: DeviceRegistrationVersion, lastRegistered: Date.now()))
            }

            // Recover from the error -- if we can.
            if let error = result.failureValue as? FxAClientError,
               case .remote(let remoteError) = error {
                switch remoteError.code {
                case FxAccountRemoteError.DeviceSessionConflict:
                    return recoverFromDeviceSessionConflict(account, client: client, sessionToken: sessionToken)
                case FxAccountRemoteError.InvalidAuthenticationToken:
                    return recoverFromTokenError(account, client: client)
                case FxAccountRemoteError.UnknownDevice:
                    return recoverFromUnknownDevice(account)
                default: break
                }
            }

            // Not an error we can recover from. Rethrow it and fall back to the failure handler.
            return deferMaybe(result.failureValue!)
        }

        // Post-recovery. We either registered or we didn't, but update the account either way.
        return registration.bind { result in
            switch result {
            case .success(let registration):
                account.deviceRegistration = registration.value
                return deferMaybe(registrationResult)
            case .failure(let error):
                log.error("Device registration failed: \(error.description)")
                if let registration = account.deviceRegistration {
                    account.deviceRegistration = FxADeviceRegistration(id: registration.id, version: 0, lastRegistered: registration.lastRegistered)
                }
                return deferMaybe(error)
            }
        }
    }

    fileprivate static func recoverFromDeviceSessionConflict(_ account: FirefoxAccount, client: FxAClient10, sessionToken: NSData) -> Deferred<Maybe<FxADeviceRegistration>> {
        // FxA has already associated this session with a different device id.
        // Perhaps we were beaten in a race to register. Handle the conflict:
        //   1. Fetch the list of devices for the current user from FxA.
        //   2. Look for ourselves in the list.
        //   3. If we find a match, set the correct device id and device registration
        //      version on the account data and return the correct device id. At next
        //      sync or next sign-in, registration is retried and should succeed.
        log.warning("Device session conflict. Attempting to find the current device ID…")
        return client.devices(withSessionToken: sessionToken) >>== { response in
            guard let currentDevice = response.devices.find({ $0.isCurrentDevice }) else {
                return deferMaybe(FxADeviceRegistratorError.currentDeviceNotFound)
            }

            return deferMaybe(FxADeviceRegistration(id: currentDevice.id!, version: 0, lastRegistered: Date.now()))
        }
    }

    fileprivate static func recoverFromTokenError(_ account: FirefoxAccount, client: FxAClient10) -> Deferred<Maybe<FxADeviceRegistration>> {
        return client.status(forUID: account.uid) >>== { status in
            let _ = account.makeDoghouse()
            if !status.exists {
                // TODO: Should be in an "I have an iOS account, but the FxA is gone." state.
                // This will do for now...
                return deferMaybe(FxADeviceRegistratorError.accountDeleted)
            }
            return deferMaybe(FxADeviceRegistratorError.invalidSession)
        }
    }

    fileprivate static func recoverFromUnknownDevice(_ account: FirefoxAccount) -> Deferred<Maybe<FxADeviceRegistration>> {
        // FxA did not recognize the device ID. Handle it by clearing the registration on the account data.
        // At next sync or next sign-in, registration is retried and should succeed.
        log.warning("Unknown device ID. Clearing the local device data.")
        account.deviceRegistration = nil
        return deferMaybe(FxADeviceRegistratorError.unknownDevice)
    }
}
