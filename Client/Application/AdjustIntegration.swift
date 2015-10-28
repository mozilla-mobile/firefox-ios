/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

private let AdjustIntegrationErrorDomain = "org.mozilla.ios.Firefox.AdjustIntegrationErrorDomain"

private let AdjustAttributionFileName = "AdjustAttribution.json"

private let AdjustAppTokenKey = "AdjustAppToken"
private let AdjustEnvironmentKey = "AdjustEnvironment"

private let AdjustSandboxEnvironment = "sandbox"
private let AdjustProductionEnvironment = "production"

private enum AdjustEnvironment: String {
    case Sandbox = "sandbox"
    case Production = "production"
}

private struct AdjustSettings {
    var appToken: String
    var environment: AdjustEnvironment
}

/// Simple (singleton) object to contain all code related to Adjust. The idea is to capture all logic
/// here so that we have one single place where we can see what Adjust is doing. Ideally you only call
/// functions in this object from other parts of the application.

class AdjustIntegration: NSObject {
    static let sharedInstance = AdjustIntegration()

    /// Return an ADJConfig object if Adjust has been enabled. It is determined from the values in
    /// the Info.plist file if Adjust should be enabled, and if so, what its application token and
    /// environment are. If those keys are either missing or empty in the Info.plist then it is
    /// assumed that Adjust is not enabled for this build.

    private func getConfig() -> ADJConfig? {
        guard let settings = getSettings() else {
            return nil
        }

        let config = ADJConfig(appToken: settings.appToken, environment: settings.environment.rawValue)
        if settings.environment == .Sandbox {
            config.logLevel = ADJLogLevelDebug
        }
        config.delegate = self
        return config
    }

    /// Returns the Adjust settings from our Info.plist. If the settings are missing or invalid, such as an unknown
    /// environment, then it will return nil.

    private func getSettings() -> AdjustSettings? {
        let bundle = NSBundle.mainBundle()
        guard let adjustAppToken = bundle.objectForInfoDictionaryKey(AdjustAppTokenKey) as? String,
                adjustEnvironment = bundle.objectForInfoDictionaryKey(AdjustEnvironmentKey) as? String else {
            return nil
        }
        guard !adjustAppToken.isEmpty && !adjustEnvironment.isEmpty else {
            return nil
        }
        guard let environment = AdjustEnvironment.init(rawValue: adjustEnvironment) else {
            Logger.browserLogger.error("Adjust - Invalid environment provided: \(adjustEnvironment)")
            return nil
        }
        return AdjustSettings(appToken: adjustAppToken, environment: environment)
    }

    /// Returns true if the attribution file is present.

    private func hasAttribution() throws -> Bool {
        return NSFileManager.defaultManager().fileExistsAtPath(try getAttributionPath())
    }

    /// Save an `ADJAttribution` instance to a JSON file. Throws an error if the file could not be written. The file
    /// written is a JSON file with a single dictionary in it. We add one extra item to it that contains the current
    /// timestamp in seconds since the UNIX epoch.

    private func saveAttribution(attribution: ADJAttribution) throws -> Void {
        let dictionary = NSMutableDictionary(dictionary: attribution.dictionary())
        dictionary["_timestamp"] = NSNumber(longLong: Int64(NSDate().timeIntervalSince1970))
        let data = try NSJSONSerialization.dataWithJSONObject(dictionary, options: [NSJSONWritingOptions.PrettyPrinted])
        try data.writeToFile(try getAttributionPath(), options: [])
    }

    /// Return the path to the `AdjustAttribution.json` file. Throws an `NSError` if we could not build the path.

    private func getAttributionPath() throws -> String {
        guard let url = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first,
                path = url.URLByAppendingPathComponent(AdjustAttributionFileName).path else {
            throw NSError(domain: AdjustIntegrationErrorDomain, code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Could not build \(AdjustAttributionFileName) path"])
        }
        return path
    }
}

extension AdjustIntegration: AdjustDelegate {
    /// This is called as part of `UIApplication.didFinishLaunchingWithOptions()`. To make sure we only send one ping
    /// to Adjust, we check if the attribution has been written to disk. If it has then that means we have done a
    /// successful attribution ping and we do not run Adjust at all.

    func triggerApplicationDidFinishLaunchingWithOptions(launchOptions: [NSObject : AnyObject]?) -> Void {
        do {
            if try hasAttribution() == false {
                if let config = getConfig() {
                    Adjust.appDidLaunch(config)
                } else {
                    Logger.browserLogger.info("Adjust - Skipping because no or invalid config found")
                }
            } else {
                Logger.browserLogger.info("Adjust - Skipping because we have already seen attribution info for this install")
            }
        } catch let error {
            Logger.browserLogger.error("Adjust - Failed to register application launch: \(error)")
        }
    }

    /// This is called when Adjust has figured out the attribution. It will call us with a summary
    /// of all the things it knows. Like the campaign ID. We simply save this to a local file so
    /// that we know we have done a single attribution ping to Adjust. This is also used to prevent
    /// sending data to adjust multiple times.
    ///
    /// We also disable Adjust here, otherwise it keeps sending session pings until the app is cold
    /// started again.

    func adjustAttributionChanged(attribution: ADJAttribution!) {
        do {
            Adjust.setEnabled(false)
            try AdjustIntegration.sharedInstance.saveAttribution(attribution)
        } catch let error {
            Logger.browserLogger.error("Adjust - Failed to save attribution: \(error)")
        }
    }
}
