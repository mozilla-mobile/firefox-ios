/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Sentry

public class SentryIntegration {
    public static let shared = SentryIntegration()
    
    public static var crashedLastLaunch: Bool {
        return Client.shared?.crashedLastLaunch() ?? false
    }
    
    private let SentryDSNKey = "SentryDSN"
    private let SentryDeviceAppHashKey = "SentryDeviceAppHash"
    private let DefaultDeviceAppHash = "0000000000000000000000000000000000000000"
    private let DeviceAppHashLength = UInt(20)
    
    private var enabled = false
    
    private var attributes: [String : Any] = [:]
    
    public func setup(sendUsageData: Bool) {
        assert(!enabled, "SentryIntegration.setup() should only be called once")
        
        if AppInfo.isSimulator() || !sendUsageData {
            print("Sentry not enabled")
            return
        }
        
        guard let dsn = Bundle.main.object(forInfoDictionaryKey: SentryDSNKey) as? String, !dsn.isEmpty else {
            print("Could not obtain Sentry DSN")
            return
        }
        
        do {
            Client.shared = try Client(dsn: dsn)
            try Client.shared?.startCrashHandler()
            enabled = true
            
            // If we have not already for this install, generate a completely random identifier
            // for this device. It is stored in the app group so that the same value will
            // be used for both the main application and the app extensions.
            if let defaults = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier), defaults.string(forKey: SentryDeviceAppHashKey) == nil {
                defaults.set(Bytes.generateRandomBytes(DeviceAppHashLength).hexEncodedString, forKey: SentryDeviceAppHashKey)
                defaults.synchronize()
            }
            
            // For all outgoing reports, override the default device identifier with our own random
            // version. Default to a blank (zero) identifier in case of errors.
            Client.shared?.beforeSerializeEvent = { event in
                let deviceAppHash = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier)?.string(forKey: self.SentryDeviceAppHashKey)
                event.context?.appContext?["device_app_hash"] = deviceAppHash ?? self.DefaultDeviceAppHash
                
                var attributes = event.extra ?? [:]
                attributes.merge(with: self.attributes)
                event.extra = attributes
            }
        } catch {}
    }
    
    public func crash() {
        Client.shared?.crash()
    }
    
    public func send(message: String, tag: String = "general", severity: SentrySeverity = .info, completion: SentryRequestFinished? = nil) {
        if !enabled {
            if let completion = completion {
                completion(nil)
            }
            return
        }
        
        let event = Event(level: severity)
        event.message = message
        event.tags = ["tag": tag]
        
        Client.shared?.send(event: event, completion: completion)
    }
    
    public func sendWithStacktrace(message: String, tag: String = "general", severity: SentrySeverity = .info, completion: SentryRequestFinished? = nil) {
        if !enabled {
            if let completion = completion {
                completion(nil)
            }
            return
        }
        
        Client.shared?.snapshotStacktrace {
            let event = Event(level: severity)
            event.message = message
            event.tags = ["tag": tag]
            
            Client.shared?.appendStacktrace(to: event)
            event.debugMeta = nil
            Client.shared?.send(event: event, completion: completion)
        }
    }
    
    public func addAttributes(_ attributes: [String : Any]) {
        self.attributes.merge(with: attributes)
    }
}
