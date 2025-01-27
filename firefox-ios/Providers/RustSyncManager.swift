// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import Shared
import Storage
import Sync
import AuthenticationServices
import Common

import class MozillaAppServices.MZKeychainWrapper
import enum MozillaAppServices.OAuthScope
import enum MozillaAppServices.SyncEngineSelection
import enum MozillaAppServices.SyncReason
import struct MozillaAppServices.DeviceSettings
import struct MozillaAppServices.SyncAuthInfo
import struct MozillaAppServices.SyncParams
import struct MozillaAppServices.SyncResult
import struct MozillaAppServices.Device
import struct MozillaAppServices.ScopedKey
import struct MozillaAppServices.AccessTokenInfo

// Extends NSObject so we can use timers.
public class RustSyncManager: NSObject, SyncManager {
    // We shouldn't live beyond our containing BrowserProfile, either in the main app
    // or in an extension.
    // But it's possible that we'll finish a side-effect sync after we've ditched the
    // profile as a whole, so we hold on to our Prefs, potentially for a little while
    // longer. This is safe as a strong reference, because there's no cycle.
    private weak var profile: BrowserProfile?
    private let prefs: Prefs
    private var syncTimer: Timer?
    private var backgrounded = true
    private let logger: Logger
    private let fxaDeclinedEngines = "fxa.cwts.declinedSyncEngines"
    private var notificationCenter: NotificationProtocol
    var creditCardAutofillEnabled = false

    let fifteenMinutesInterval = TimeInterval(60 * 15)

    public var lastSyncFinishTime: Timestamp? {
        get {
            return prefs.timestampForKey(PrefsKeys.KeyLastSyncFinishTime)
        }

        set(value) {
            if let value = value {
                prefs.setTimestamp(value,
                                   forKey: PrefsKeys.KeyLastSyncFinishTime)
            } else {
                prefs.removeObjectForKey(PrefsKeys.KeyLastSyncFinishTime)
            }
        }
    }

    lazy var syncManagerAPI = RustSyncManagerAPI(logger: logger)

    public var isSyncing: Bool {
        return syncDisplayState != nil && syncDisplayState! == .inProgress
    }

    public var syncDisplayState: SyncDisplayState?

    var prefsForSync: Prefs {
        return prefs.branch("sync")
    }

    init(profile: BrowserProfile,
         creditCardAutofillEnabled: Bool = false,
         logger: Logger = DefaultLogger.shared,
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.profile = profile
        self.prefs = profile.prefs
        self.logger = logger
        self.notificationCenter = notificationCenter

        super.init()
        self.creditCardAutofillEnabled = creditCardAutofillEnabled
    }

    @objc
    func syncOnTimer() {
        syncEverything(why: .scheduled)
        profile?.pollCommands()
    }

    private func repeatingTimerAtInterval(
        _ interval: TimeInterval,
        selector: Selector
    ) -> Timer {
        return Timer.scheduledTimer(timeInterval: interval,
                                    target: self,
                                    selector: selector,
                                    userInfo: nil,
                                    repeats: true)
    }

    public func updateCreditCardAutofillStatus(value: Bool) {
        creditCardAutofillEnabled = value
    }

    func syncEverythingSoon() {
        doInBackgroundAfter(SyncConstants.SyncOnForegroundAfterMillis) {
            self.logger.log("Running delayed startup sync.",
                            level: .debug,
                            category: .sync)
            self.syncEverything(why: .startup)
        }
    }

    private func beginTimedSyncs() {
        if syncTimer != nil {
            logger.log("Already running sync timer.",
                       level: .debug,
                       category: .sync)
            return
        }

        let interval = fifteenMinutesInterval
        let selector = #selector(syncOnTimer)
        logger.log("Starting sync timer.",
                   level: .info,
                   category: .sync)
        syncTimer = repeatingTimerAtInterval(interval, selector: selector)
    }

    /**
     * The caller is responsible for calling this on the same thread on which it called
     * beginTimedSyncs.
     */
    public func endTimedSyncs() {
        if let timer = syncTimer {
            logger.log("Stopping sync timer.",
                       level: .info,
                       category: .sync)
            syncTimer = nil
            timer.invalidate()
        }
    }

    public func applicationDidBecomeActive() {
        backgrounded = false
        setPreferenceForSignIn()
        guard let profile = profile, profile.hasSyncableAccount() else { return }
        beginTimedSyncs()

        // Sync now if it's been more than our threshold.
        let now = Date.now()
        let then = lastSyncFinishTime ?? 0
        guard now >= then else {
            logger.log("Time was modified since last sync.",
                       level: .debug,
                       category: .sync)
            syncEverythingSoon()
            return
        }
        let since = now - then
        logger.log("\(since)msec since last sync.",
                   level: .debug,
                   category: .sync)
        if since > SyncConstants.SyncOnForegroundMinimumDelayMillis {
            syncEverythingSoon()
        }
    }

    public func applicationDidEnterBackground() {
        backgrounded = true
    }

    private func setPreferenceForSignIn() {
        let signedInFxaAccountValue = profile?.prefs.boolForKey(PrefsKeys.Sync.signedInFxaAccount)
        // We only want to set the prefs if it has not been set (nil)
        // There is a case where a user has a syncable account, but returns
        // false so we check if nil here.
        guard signedInFxaAccountValue == nil else { return }
        let userHasSyncableAccount = profile?.hasSyncableAccount() ?? false
        profile?.prefs.setBool(userHasSyncableAccount, forKey: PrefsKeys.Sync.signedInFxaAccount)
    }

    private func resetUserSyncPreferences() {
        profile?.prefs.setBool(false, forKey: PrefsKeys.Sync.signedInFxaAccount)
        profile?.prefs.setInt(0, forKey: PrefsKeys.Sync.numberOfSyncedDevices)
    }

    private func beginSyncing() {
        syncDisplayState = .inProgress
        notifySyncing(notification: .ProfileDidStartSyncing)
        AppEventQueue.started(.profileSyncing)
    }

    private func resolveSyncState(result: SyncResult) -> SyncDisplayState {
        let hasSynced = !result.successful.isEmpty
        let status = result.status

        // This is similar to the old `SyncStatusResolver.resolveResults` call. If none of
        // the engines successfully synced and a network issue occurred we return `.bad`.
        // If none of the engines successfully synced and an auth error occurred we return
        // `.warning`. Otherwise we return `.good`.

        if !hasSynced && status == .authError {
            return .warning(message: .FirefoxSyncOfflineTitle)
        } else if !hasSynced && status == .networkError {
            return .bad(message: .FirefoxSyncOfflineTitle)
        } else {
            return .good
        }
    }

    private func endSyncing(_ result: SyncResult) {
        logger.log("Ending all syncs.",
                   level: .info,
                   category: .sync)

        syncDisplayState = resolveSyncState(result: result)

        if let syncState = syncDisplayState, syncState == .good {
            lastSyncFinishTime = Date.now()
        }

        if canSendUsageData() {
            self.syncManagerAPI.reportSyncTelemetry(syncResult: result) { _ in }
        } else {
            logger.log("Profile isn't sending usage data. Not sending sync status event.",
                       level: .debug,
                       category: .sync)
        }

        // Don't notify if we are performing a sync in the background. This prevents more
        // db access from happening
        if !backgrounded {
            notifySyncing(notification: .ProfileDidFinishSyncing)
            AppEventQueue.completed(.profileSyncing)
        }
    }

    func canSendUsageData() -> Bool {
        return profile?.prefs.boolForKey(AppConstants.prefSendUsageData) ?? true
    }

    private func notifySyncing(notification: Notification.Name) {
        notificationCenter.post(name: notification)
    }

    func doInBackgroundAfter(_ millis: Int64, _ block: @escaping () -> Void) {
        let queue = DispatchQueue.global(qos: DispatchQoS.background.qosClass)
        queue.asyncAfter(
            deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(Int(millis)),
            execute: block)
    }

    public func onAddedAccount() -> Success {
        // Only sync if we're green lit. This makes sure that we don't sync unverified
        // accounts.
        guard let profile = profile, profile.hasSyncableAccount() else { return succeed() }
        setPreferenceForSignIn()
        beginTimedSyncs()
        return syncEverything(why: .enabledChange)
    }

    public func onRemovedAccount() -> Success {
        resetUserSyncPreferences()
        let clearPrefs: () -> Success = {
            withExtendedLifetime(self) {
                // Clear prefs after we're done clearing everything else -- just in case
                // one of them needs the prefs and we race. Clear regardless of success
                // or failure.

                // This will remove keys from the Keychain if they exist, as well
                // as wiping the Sync prefs.

                if let keyLabel = self
                    .prefsForSync
                    .branch("scratchpad")
                    .stringForKey("keyLabel") {
                        MZKeychainWrapper
                            .sharedClientAppContainerKeychain
                            .removeObject(forKey: keyLabel)
                }
                self.prefsForSync.clearAll()
            }
            return succeed()
        }
        self.syncManagerAPI.disconnect()
        return clearPrefs()
    }

    public func checkCreditCardEngineEnablement() -> Bool {
        let engine = RustSyncManagerAPI.TogglableEngine.creditcards.rawValue
        guard let declined = UserDefaults.standard.stringArray(forKey: fxaDeclinedEngines),
              !declined.isEmpty,
              declined.contains(engine)
        else {
            let engineEnabled = prefsForSync.boolForKey("engine.\(engine).enabled") ?? false
            return engineEnabled
        }
        return false
    }

    public func getEngineEnablementChangesForAccount() -> [String: Bool] {
        var engineEnablements: [String: Bool] = [:]
        // We just created the account, the user went through the Choose What to Sync
        // screen on FxA.
        if let declined = UserDefaults.standard.stringArray(forKey: fxaDeclinedEngines) {
            declined.forEach { engineEnablements[$0] = false }
            UserDefaults.standard.removeObject(forKey: fxaDeclinedEngines)
        } else {
            // Bundle in authState the engines the user activated/disabled since the
            // last sync.
            let engines = self.creditCardAutofillEnabled ?
                syncManagerAPI.rustTogglableEngines :
                syncManagerAPI.rustTogglableEngines.filter({ $0 != RustSyncManagerAPI.TogglableEngine.creditcards })

            engines.forEach { engine in
                let stateChangedPref = "engine.\(engine).enabledStateChanged"
                if prefsForSync.boolForKey(stateChangedPref) != nil,
                   let enabled = prefsForSync.boolForKey("engine.\(engine).enabled") {
                    engineEnablements[engine.rawValue] = enabled
                }
            }
        }

        if !engineEnablements.isEmpty {
            let enabled = engineEnablements.compactMap { $0.value ? $0.key : nil }
            logger.log("engines to enable: \(enabled)",
                       level: .info,
                       category: .sync)

            let disabled = engineEnablements.compactMap { !$0.value ? $0.key : nil }
            let msg = "engines to disable: \(disabled)"
            logger.log(msg,
                       level: .info,
                       category: .sync)
        }
        return engineEnablements
    }

    public class ScopedKeyError: MaybeErrorType {
        public let description = "No key data found for scope."
    }

    public class DeviceIdError: MaybeErrorType {
        public let description = "Failed to get deviceId."
    }

    public class NoTokenServerURLError: MaybeErrorType {
        public let description = "Failed to get token server endpoint url."
    }

    private func registerSyncEngines(engines: [RustSyncManagerAPI.TogglableEngine],
                                     loginKey: String?,
                                     creditCardKey: String?,
                                     completion: @escaping (([String], [String: String])) -> Void) {
        var localEncryptionKeys: [String: String] = [:]
        var rustEngines: [String] = []
        var registeredPlaces = false
        var registeredAutofill = false

        for engine in engines.filter({
            self.syncManagerAPI.rustTogglableEngines.contains($0) }) {
             switch engine {
             case .tabs:
                 self.profile?.tabs.registerWithSyncManager()
                 rustEngines.append(engine.rawValue)
             case .passwords:
                 if let key = loginKey {
                     self.profile?.logins.registerWithSyncManager()
                     localEncryptionKeys[engine.rawValue] = key
                     rustEngines.append(engine.rawValue)
                 }
             case .creditcards:
                 if self.creditCardAutofillEnabled {
                    if let key = creditCardKey {
                        // checking if autofill was already registered with addresses
                        if !registeredAutofill {
                            self.profile?.autofill.registerWithSyncManager()
                            registeredAutofill = true
                        }
                        localEncryptionKeys[engine.rawValue] = key
                        rustEngines.append(engine.rawValue)
                     }
                 }
             case .addresses:
                 // checking if autofill was already registered with credit cards
                 if !registeredAutofill {
                     self.profile?.autofill.registerWithSyncManager()
                     registeredAutofill = true
                 }
                 rustEngines.append(engine.rawValue)
             case .bookmarks, .history:
                 if !registeredPlaces {
                     self.profile?.places.registerWithSyncManager()
                     registeredPlaces = true
                 }
                 rustEngines.append(engine.rawValue)
             }
        }
        completion((rustEngines, localEncryptionKeys))
    }

    func getEnginesAndKeys(engines: [RustSyncManagerAPI.TogglableEngine],
                           completion: @escaping (([String], [String: String])) -> Void) {
        profile?.logins.getStoredKey { loginResult in
            var loginKey: String?

            switch loginResult {
            case .success(let key):
                loginKey = key
            case .failure(let err):
                self.logger.log("Login encryption key could not be retrieved for syncing: \(err)",
                                level: .warning,
                                category: .sync)
            }

            self.profile?.autofill.getStoredKey { creditCardResult in
                var creditCardKey: String?

                switch creditCardResult {
                case .success(let key):
                    creditCardKey = key
                case .failure(let err):
                    self.logger.log("Credit card encryption key could not be retrieved for syncing: \(err)",
                                    level: .warning,
                                    category: .sync)
                }

                self.registerSyncEngines(engines: engines,
                                         loginKey: loginKey,
                                         creditCardKey: creditCardKey,
                                         completion: completion)
            }
        }
    }

    private func doSync(params: SyncParams, completion: @escaping (SyncResult) -> Void) {
        beginSyncing()
        syncManagerAPI.sync(params: params) { syncResult in
            // Save the persisted state
            if !syncResult.persistedState.isEmpty {
                self.prefs
                    .setString(syncResult.persistedState,
                               forKey: PrefsKeys.RustSyncManagerPersistedState)
            }

            let declinedEngines = String(describing: syncResult.declined ?? [])
            let telemetryData = syncResult.telemetryJson ??
                "(No telemetry data was returned)"
            let telemetryMessage = "\(String(describing: telemetryData))"
            let syncDetails = ["status": "\(syncResult.status)",
                               "declinedEngines": "\(declinedEngines)",
                               "telemetry": telemetryMessage]

            self.logger.log("Finished syncing",
                            level: .info,
                            category: .sync,
                            extra: syncDetails)

            if let declined = syncResult.declined {
                self.updateEnginePrefs(declined: declined)
            }

            self.endSyncing(syncResult)
            completion(syncResult)
        }
    }

    func updateEnginePrefs(declined: [String]) {
        // Save declined/enabled engines - we assume the engines
        // not included in the returned `declined` property of the
        // result of the sync manager `sync` are enabled.

        let updateEnginePref: (String, Bool) -> Void = { engine, enabled in
            let enabledPref = "engine.\(engine).enabled"
            self.prefsForSync.setBool(enabled, forKey: enabledPref)

            let stateChangedPref = "engine.\(engine).enabledStateChanged"
            self.prefsForSync.setObject(nil, forKey: stateChangedPref)

            let enablementDetails = [enabledPref: String(enabled)]
            self.logger.log("Finished setting \(engine) enablement prefs",
                            level: .info,
                            category: .sync,
                            extra: enablementDetails)
        }

        syncManagerAPI.rustTogglableEngines.forEach({
            if declined.contains($0.rawValue) {
                updateEnginePref($0.rawValue, false)
            } else {
                updateEnginePref($0.rawValue, true)
            }
        })
    }

    private func syncRustEngines(why: SyncReason,
                                 engines: [String]) -> Deferred<Maybe<SyncResult>> {
        let deferred = Deferred<Maybe<SyncResult>>()

        logger.log("Syncing \(engines)", level: .info, category: .sync)
        if let accountManager = RustFirefoxAccounts.shared.accountManager {
            guard let device = accountManager.deviceConstellation()?
                .state()?
                .localDevice else {
                self.logger.log("Device Id could not be retrieved",
                                level: .warning,
                                category: .sync)
                deferred.fill(Maybe(failure: DeviceIdError()))
                return deferred
            }

            accountManager.getAccessToken(scope: OAuthScope.oldSync) { result in
                guard let accessTokenInfo = try? result.get(),
                      let key = accessTokenInfo.key else {
                    deferred.fill(Maybe(failure: ScopedKeyError()))
                    return
                }

                accountManager.getTokenServerEndpointURL { result in
                    guard case .success(let tokenServerEndpointURL) = result else {
                        deferred.fill(Maybe(failure: NoTokenServerURLError()))
                        return
                    }

                    self.getEnginesAndKeys(engines: engines.compactMap {
                        RustSyncManagerAPI.TogglableEngine(rawValue: $0)
                    }) { (rustEngines, localEncryptionKeys) in
                        let params = SyncParams(
                            reason: why,
                            engines: SyncEngineSelection.some(engines: rustEngines),
                            enabledChanges: self.getEngineEnablementChangesForAccount(),
                            localEncryptionKeys: localEncryptionKeys,
                            authInfo: self.createSyncAuthInfo(key: key,
                                                              accessTokenInfo: accessTokenInfo,
                                                              tokenServerEndpointURL: tokenServerEndpointURL),
                            persistedState:
                                self.prefs
                                    .stringForKey(PrefsKeys.RustSyncManagerPersistedState),
                            deviceSettings: self.createDeviceSettings(device: device))

                        self.doSync(params: params) { syncResult in
                            deferred.fill(Maybe(success: syncResult))
                        }
                    }
                }
            }
        }
        return deferred
    }

    private func createSyncAuthInfo(key: ScopedKey,
                                    accessTokenInfo: AccessTokenInfo,
                                    tokenServerEndpointURL: URL) -> SyncAuthInfo {
        return SyncAuthInfo(
            kid: key.kid,
            fxaAccessToken: accessTokenInfo.token,
            syncKey: key.k,
            tokenserverUrl: tokenServerEndpointURL.absoluteString)
    }

    private func createDeviceSettings(device: Device) -> DeviceSettings {
        return DeviceSettings(
            fxaDeviceId: device.id,
            name: device.displayName,
            kind: device.deviceType)
    }

    @discardableResult
    public func syncEverything(why: SyncReason) -> Success {
        return syncRustEngines(why: why,
                               engines: syncManagerAPI.rustTogglableEngines.compactMap { $0.rawValue }) >>> succeed
    }

    /**
     * Allows selective sync of different collections, for use by external APIs.
     * Some help is given to callers who use different namespaces (specifically: `passwords` is mapped to `logins`)
     * and to preserve some ordering rules.
     */
    public func syncNamedCollections(why: SyncReason, names: [String]) -> Success {
        // Massage the list of names into engine identifiers.var engines = [String]()
        var engines = [String]()

        // There may be duplicates in `names` so we are removing them here
        for name in names where !engines.contains(name) {
            engines.append(name)
        }

        return syncRustEngines(why: why, engines: engines) >>> succeed
    }

    public func syncTabs() -> Deferred<Maybe<SyncResult>> {
        return syncRustEngines(why: .user, engines: ["tabs"])
    }

    public func syncHistory() -> Deferred<Maybe<SyncResult>> {
        return syncRustEngines(why: .user, engines: ["history"])
    }
}
