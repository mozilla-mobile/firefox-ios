/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public extension Notification.Name {
    static let constellationStateUpdate = Notification.Name("constellationStateUpdate")
}

public struct ConstellationState {
    public let localDevice: Device?
    public let remoteDevices: [Device]
}

public class DeviceConstellation {
    var constellationState: ConstellationState?
    let account: FxAccount

    init(account: FxAccount) {
        self.account = account
    }

    /// Get local + remote devices synchronously.
    /// Note that this state might be empty, which should handle by calling `refreshState()`
    /// A `.constellationStateUpdate` notification is fired if the device list changes at any time.
    public func state() -> ConstellationState? {
        return constellationState
    }

    /// Refresh the list of remote devices.
    /// A `.constellationStateUpdate` notification might get fired once the new device list is fetched.
    public func refreshState() {
        DispatchQueue.global().async {
            FxALog.info("Refreshing device list...")
            do {
                let devices = try self.account.fetchDevices()
                let localDevice = devices.first { $0.isCurrentDevice }
                if localDevice?.subscriptionExpired ?? false {
                    FxALog.debug("Current device needs push endpoint registration.")
                }
                let remoteDevices = devices.filter { !$0.isCurrentDevice }

                let newState = ConstellationState(localDevice: localDevice, remoteDevices: remoteDevices)
                self.constellationState = newState

                FxALog.debug("Refreshed device list; saw \(devices.count) device(s).")

                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .constellationStateUpdate,
                        object: nil,
                        userInfo: ["newState": newState]
                    )
                }
            } catch {
                FxALog.error("Failure fetching the device list: \(error).")
                return
            }
        }
    }

    /// Updates the local device name.
    public func setLocalDeviceName(name: String) {
        DispatchQueue.global().async {
            do {
                try self.account.setDeviceDisplayName(name)
                // Update our list of devices in the background to reflect the change.
                self.refreshState()
            } catch {
                FxALog.error("Failure changing the local device name: \(error).")
            }
        }
    }

    /// Poll for device events we might have missed (e.g. Push notification missed, or device offline).
    /// Your app should probably call this on a regular basic (e.g. once a day).
    public func pollForCommands(completionHandler: @escaping (Result<[IncomingDeviceCommand], Error>) -> Void) {
        DispatchQueue.global().async {
            do {
                let events = try self.account.pollDeviceCommands()
                DispatchQueue.main.async { completionHandler(.success(events)) }
            } catch {
                DispatchQueue.main.async { completionHandler(.failure(error)) }
            }
        }
    }

    /// Send an event to another device such as Send Tab.
    public func sendEventToDevice(targetDeviceId: String, e: DeviceEventOutgoing) {
        DispatchQueue.global().async {
            do {
                switch e {
                case let .sendTab(title, url): do {
                    try self.account.sendSingleTab(targetId: targetDeviceId, title: title, url: url)
                }
                }
            } catch {
                FxALog.error("Error sending event to another device: \(error).")
            }
        }
    }

    /// Register the local AutoPush subscription with the FxA server.
    public func setDevicePushSubscription(sub: DevicePushSubscription) {
        DispatchQueue.global().async {
            do {
                try self.account.setDevicePushSubscription(
                    endpoint: sub.endpoint,
                    publicKey: sub.publicKey,
                    authKey: sub.authKey
                )
            } catch {
                FxALog.error("Failure setting push subscription: \(error).")
            }
        }
    }

    /// Once Push has decrypted a payload, send the payload to this method
    /// which will tell the app what to do with it in form of `DeviceEvents`.
    public func processRawIncomingAccountEvent(pushPayload: String,
                                               completionHandler: @escaping (Result<[AccountEvent], Error>) -> Void) {
        DispatchQueue.global().async {
            do {
                let events = try self.account.handlePushMessage(payload: pushPayload)
                self.processAccountEvents(events)
                DispatchQueue.main.async { completionHandler(.success(events)) }
            } catch {
                DispatchQueue.main.async { completionHandler(.failure(error)) }
            }
        }
    }

    /// This allows us to be helpful in certain circumstances e.g. refreshing the device list
    /// if we see a "device disconnected" push notification.
    internal func processAccountEvents(_ events: [AccountEvent]) {
        let shouldRefreshDevices = events.contains { evt in
            switch evt {
            case .deviceDisconnected, .deviceConnected: return true
            default: return false
            }
        }
        if shouldRefreshDevices {
            refreshState()
        }
    }

    internal func initDevice(name: String, type: DeviceType, capabilities: [DeviceCapability]) {
        // This method is called by `FxAccountManager` on its own asynchronous queue, hence
        // no wrapping in a `DispatchQueue.global().async`.
        assert(!Thread.isMainThread)
        do {
            try account.initializeDevice(name: name, deviceType: type, supportedCapabilities: capabilities)
        } catch {
            FxALog.error("Failure initializing device: \(error).")
        }
    }

    internal func ensureCapabilities(capabilities: [DeviceCapability]) {
        // This method is called by `FxAccountManager` on its own asynchronous queue, hence
        // no wrapping in a `DispatchQueue.global().async`.
        assert(!Thread.isMainThread)
        do {
            try account.ensureCapabilities(supportedCapabilities: capabilities)
        } catch {
            FxALog.error("Failure ensuring device capabilities: \(error).")
        }
    }
}

public enum DeviceEventOutgoing {
    case sendTab(title: String, url: String)
}
