// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import Shared
import Storage
import Sync
import SyncTelemetry
import AuthenticationServices
import Logger

// Extends NSObject so we can use timers.
public class RustSyncManager: NSObject, SyncManager {
    // We shouldn't live beyond our containing BrowserProfile, either in the main app
    // or in an extension.
    // But it's possible that we'll finish a side-effect sync after we've ditched the
    // profile as a whole, so we hold on to our Prefs, potentially for a little while
    // longer. This is safe as a strong reference, because there's no cycle.
    unowned fileprivate let profile: BrowserProfile
    fileprivate let prefs: Prefs
    fileprivate var constellationStateUpdate: Any?
    fileprivate var syncTimer: Timer?
    fileprivate var backgrounded: Bool = true
    private let logger: Logger

    let FifteenMinutes = TimeInterval(60 * 15)

    deinit {
        if let c = constellationStateUpdate {
            NotificationCenter.default.removeObserver(c)
        }
    }
    
    public var lastSyncFinishTime: Timestamp? {
        get {
            return self.prefs.timestampForKey(PrefsKeys.KeyLastSyncFinishTime)
        }

        set(value) {
            if let value = value {
                self.prefs.setTimestamp(value,
                                        forKey: PrefsKeys.KeyLastSyncFinishTime)
            } else {
                self.prefs.removeObjectForKey(PrefsKeys.KeyLastSyncFinishTime)
            }
        }
    }
    
    lazy var syncManagerAPI = RustSyncManagerAPI()
    
    private func getPersistedState(engineName: String) -> String? {
        if let enabled = self.prefsForSync.boolForKey("engine.\(engineName).enabled"),
           enabled,
           let result = syncRustEngines(why: .user, engines: [engineName])
            .value
            .successValue
        {
            return result.persistedState
        } else {
            return nil
        }
    }
    
    func migrateSyncData() {
        // The sync functions used by the old native swift sync manager did not return
        // a persisted state string. And if we do not call the sync manager's rust
        // function with persisted state data that call will be treated as the first
        // sync for the account, which could take longer than the user expects to
        // completed. To avoid that, we sync one component with sync manager and store
        // it for the first sync manager full sync.

        if let persistedState = getPersistedState(engineName: "tabs") {
            self.prefs.setString(persistedState, forKey: PrefsKeys.RustSyncManagerPersistedState)
        } else if let persistedState = getPersistedState(engineName: "logins") {
            self.prefs.setString(persistedState, forKey: PrefsKeys.RustSyncManagerPersistedState)
        } else if let persistedState = getPersistedState(engineName: "bookmarks") {
            self.prefs.setString(persistedState, forKey: PrefsKeys.RustSyncManagerPersistedState)
        } else if let persistedState = getPersistedState(engineName: "history") {
            self.prefs.setString(persistedState, forKey: PrefsKeys.RustSyncManagerPersistedState)
        }
        
        // There were no enabled engines to sync so persisted state will be empty.
    }
    
    public var isSyncing: Bool {
        return syncDisplayState != nil && syncDisplayState! == .inProgress
    }

    public var syncDisplayState: SyncDisplayState?
    
    @objc func syncOnTimer() {
        self.syncEverything(why: .scheduled)
        self.profile.pollCommands()
    }
    
    fileprivate func repeatingTimerAtInterval(
        _ interval: TimeInterval,
        selector: Selector
    ) -> Timer {
        return Timer.scheduledTimer(timeInterval: interval,
                                    target: self,
                                    selector: selector,
                                    userInfo: nil,
                                    repeats: true)
    }
    
    func syncEverythingSoon() {
        self.doInBackgroundAfter(SyncConstants.SyncOnForegroundAfterMillis) {
            self.logger.log("Running delayed startup sync.",
                             level: .debug,
                             category: .sync)
            self.syncEverything(why: .startup)
        }
    }
    
    private func beginTimedSyncs() {
        if self.syncTimer != nil {
            logger.log("Already running sync timer.",
                       level: .debug,
                       category: .sync)
            return
        }

        let interval = FifteenMinutes
        let selector = #selector(syncOnTimer)
        logger.log("Starting sync timer.",
                   level: .info,
                   category: .sync)
        self.syncTimer = repeatingTimerAtInterval(interval, selector: selector)
    }

    /**
     * The caller is responsible for calling this on the same thread on which it called
     * beginTimedSyncs.
     */
    public func endTimedSyncs() {
        if let t = self.syncTimer {
            logger.log("Stopping sync timer.",
                       level: .info,
                       category: .sync)
            self.syncTimer = nil
            t.invalidate()
        }
    }

    public func applicationDidBecomeActive() {
        backgrounded = false

        guard self.profile.hasSyncableAccount() else { return }

        self.beginTimedSyncs()

        // Sync now if it's been more than our threshold.
        let now = Date.now()
        let then = self.lastSyncFinishTime ?? 0
        guard now >= then else {
            logger.log("Time was modified since last sync.",
                       level: .debug,
                       category: .sync)
            self.syncEverythingSoon()
            return
        }
        let since = now - then
        logger.log("\(since)msec since last sync.",
                   level: .debug,
                   category: .sync)
        if since > SyncConstants.SyncOnForegroundMinimumDelayMillis {
            self.syncEverythingSoon()
        }
    }

    public func applicationDidEnterBackground() {
        backgrounded = true
    }

    fileprivate func beginSyncing() {
        notifySyncing(notification: .ProfileDidStartSyncing)
    }
    
    private func resolveSyncState(
        result: RustSyncResult
    ) -> SyncDisplayState {
        let hasSynced = !result.successful.isEmpty
        let status = result.status

        // This is similar to the old `SyncStatusResolver.resolveResults` call. If none of
        // the engines successfully synced and a network issue occured we return `.bad`.
        // If none of the engines successfully synced and an auth error occured we return
        // `.warning`. Otherwise we return `.good`.

        if !hasSynced && status == .authError {
            return .warning(message: .FirefoxSyncOfflineTitle)
        } else if !hasSynced && status == .networkError {
            return .bad(message: .FirefoxSyncOfflineTitle)
        } else {
            return .good
        }
    }

    fileprivate func endRustSyncing(_ result: RustSyncResult) {
        logger.log("Ending all syncs.",
                   level: .info,
                   category: .sync)
        
        syncDisplayState = resolveSyncState(result: result)
        
        #if MOZ_TARGET_CLIENT
            if canSendUsageData() {
                let gleanHelper = GleanSyncOperationHelper()
                gleanHelper.reportTelemetry(result)
            } else {
                logger.log("""
                    Profile isn't sending usage data. Not sending sync status event.
                    """,
                    level: .debug,
                    category: .sync)
            }
        #endif

        // Don't notify if we are performing a sync in the background. This prevents more
        // db access from happening
        if !self.backgrounded {
            notifySyncing(notification: .ProfileDidFinishSyncing)
        }
    }

    func canSendUsageData() -> Bool {
        return profile.prefs.boolForKey(AppConstants.PrefSendUsageData) ?? true
    }

    private func notifySyncing(notification: Notification.Name) {
        NotificationCenter.default.post(name: notification,
                                        object: syncDisplayState?.asObject())
    }

    init(profile: BrowserProfile,
         logger: Logger = DefaultLogger.shared) {
        self.profile = profile
        self.prefs = profile.prefs
        self.logger = logger

        super.init()

        let center = NotificationCenter.default

        center.addObserver(self,
                           selector: #selector(onStartSyncing),
                           name: .ProfileDidStartSyncing,
                           object: nil)
        center.addObserver(self,
                           selector: #selector(onFinishSyncing),
                           name: .ProfileDidFinishSyncing,
                           object: nil)
    }

    func doInBackgroundAfter(_ millis: Int64, _ block: @escaping () -> Void) {
        let queue = DispatchQueue.global(qos: DispatchQoS.background.qosClass)
        // Pretty ambiguous here. I'm thinking .now was DispatchTime.now() and not
        // Date.now()
        queue.asyncAfter(
            deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(Int(millis)),
            execute: block)
    }

    @objc func onStartSyncing(_ notification: NSNotification) {
        syncDisplayState = .inProgress
    }

    @objc func onFinishSyncing(_ notification: NSNotification) {
        if let syncState = syncDisplayState, syncState == .good {
            self.lastSyncFinishTime = Date.now()
        }
    }

    var prefsForSync: Prefs {
        return self.prefs.branch("sync")
    }

    public func onAddedAccount() -> Success {
        // Only sync if we're green lit. This makes sure that we don't sync unverified
        // accounts.
        guard self.profile.hasSyncableAccount() else { return succeed() }

        self.beginTimedSyncs()
        return self.syncEverything(why: .didLogin)
    }

    public func onRemovedAccount() -> Success {
        let clearPrefs: () -> Success = {
            withExtendedLifetime(self) {
                // Clear prefs after we're done clearing everything else -- just in case
                // one of them needs the prefs and we race. Clear regardless of success
                // or failure.

                // This will remove keys from the Keychain if they exist, as well
                // as wiping the Sync prefs.
                
                // XXX: `Scratchpad.clearFromPrefs` and `clearAll` were pulled from
                // `SyncStateMachine.clearStateFromPrefs` to reduce RustSyncManager's
                // dependence on the swift sync state machine. This will make refactoring
                // or eliminating that code easier once the rust sync manager rollout is
                // complete.
                Scratchpad.clearFromPrefs(self.prefsForSync.branch("scratchpad"))
                self.prefsForSync.clearAll()
            }
            return succeed()
        }
        self.syncManagerAPI.disconnect()
        return clearPrefs()
    }

    private func getEngineEnablementChangesForAccount() -> [String: Bool] {
        var engineEnablements: [String: Bool] = [:]
        // We just created the account, the user went through the Choose What to Sync
        // screen on FxA.
        if let declined = UserDefaults.standard.stringArray(
            forKey: "fxa.cwts.declinedSyncEngines") {

            declined.forEach { engineEnablements[$0] = false }
            UserDefaults.standard.removeObject(forKey: "fxa.cwts.declinedSyncEngines")
        } else {
            // Bundle in authState the engines the user activated/disabled since the
            // last sync.
            RustTogglableEngines.forEach { engine in
                let stateChangedPref = "engine.\(engine).enabledStateChanged"
                if self.prefsForSync.boolForKey(stateChangedPref) != nil,
                   let enabled = self.prefsForSync.boolForKey("engine.\(engine).enabled") {
                    engineEnablements[engine] = enabled
                    self.prefsForSync.setObject(nil, forKey: stateChangedPref)
                }
            }
        }
        
        if !engineEnablements.isEmpty {
            logger.log("""
                engines to enable:
                \(engineEnablements.compactMap { $0.value ? $0.key : nil })
                """,
               level: .info,
               category: .sync)
            logger.log("""
                engines to disable:
                \(engineEnablements.compactMap { !$0.value ? $0.key : nil })
                """,
               level: .info,
               category: .sync)
        }
        
        
        return engineEnablements
    }

    public class ScopedKeyError: MaybeErrorType {
        public var description = "No key data found for scope."
    }

    public class EncryptionKeyError: MaybeErrorType {
        public var description = "Failed to get stored key."
    }

    public class DeviceIdError: MaybeErrorType {
        public var description = "Failed to get deviceId."
    }

    public class NoTokenServerURLError: MaybeErrorType {
        public var description = "Failed to get token server endpoint url."
    }

    public class EngineAndKeyRetrievalError: MaybeErrorType {
        public var description = "Failed to get sync engine and key data."
    }
    
    fileprivate func getEnginesAndKeys(
        engines: [String]
    ) -> Deferred<Maybe<([EngineIdentifier], [String: String])>> {
        let deferred = Deferred<Maybe<([EngineIdentifier], [String: String])>>()
        var localEncryptionKeys: [String: String] = [:]
        var rustEngines: [String] = []
        var registeredPlaces: Bool = false
        
        for engine in engines {
            switch engine {
            case "tabs":
                self.profile.tabs.registerWithSyncManager()
                rustEngines.append("tabs")
            case "passwords":
                self.profile.logins.registerWithSyncManager()
                if let key = try? self.profile.logins.getStoredKey() {
                    localEncryptionKeys["passwords"] = key
                    rustEngines.append("passwords")
                } else {
                    SentryIntegration.shared.sendWithStacktrace(
                        message: "Login encryption key could not be retrieved for syncing",
                        tag: SentryTag.rustLogins, severity: .warning)
                }
            case "bookmarks":
                if !registeredPlaces {
                    self.profile.places.registerWithSyncManager()
                    registeredPlaces = true
                }
                rustEngines.append("bookmarks")
            case "history":
                if !registeredPlaces {
                    self.profile.places.registerWithSyncManager()
                    registeredPlaces = true
                }
                rustEngines.append("history")
            default:
                continue
            }
        }
        
        deferred.fill(Maybe(success: (rustEngines, localEncryptionKeys)))
        return deferred
    }

    fileprivate func syncRustEngines(
        why: RustSyncReason,
        engines: [String]
    ) -> Deferred<Maybe<RustSyncResult>> {
        let deferred = Deferred<Maybe<RustSyncResult>>()

        logger.log("Syncing \(engines)", level: .info, category: .sync)
        self.profile.rustFxA.accountManager.upon { accountManager in
            guard let device = accountManager.deviceConstellation()?
                .state()?
                .localDevice else {
                SentryIntegration.shared.sendWithStacktrace(
                    message: "Device Id could not be retrieved",
                    tag: SentryTag.rustSyncManager,
                    severity: .warning
                )
                deferred.fill(Maybe(failure: DeviceIdError()))
                return
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

                    self.getEnginesAndKeys(engines: engines).upon { result in
                        guard let (rustEngines, localEncryptionKeys) = result
                            .successValue else {
                            deferred.fill(Maybe(failure: EngineAndKeyRetrievalError()))
                            return
                        }
                        let params = SyncParams(
                            reason: why,
                            engines: SyncEngineSelection.some(engines: rustEngines),
                            enabledChanges: self.getEngineEnablementChangesForAccount(),
                            localEncryptionKeys: localEncryptionKeys,
                            authInfo: SyncAuthInfo(
                                kid: key.kid,
                                fxaAccessToken: accessTokenInfo.token,
                                syncKey: key.k,
                                tokenserverUrl: tokenServerEndpointURL.absoluteString),
                            persistedState:
                                self.prefs
                                    .stringForKey(PrefsKeys.RustSyncManagerPersistedState),
                            deviceSettings:  DeviceSettings(
                                fxaDeviceId: device.id,
                                name: device.displayName,
                                kind: self.toSyncManagerDeviceType(
                                    deviceType: device.deviceType)))

                        self.beginSyncing()
                        self.syncManagerAPI.sync(params: params) { syncResult in
                            // Save the persisted state
                            self.prefs.setString(syncResult.persistedState, forKey: PrefsKeys.RustSyncManagerPersistedState)

                            self.logger.log("""
                                        Finished syncing with \(syncResult.status) status
                                        """,
                                       level: .info,
                                       category: .sync)
                            self.logger.log("""
                                        Declined engines
                                        \(String(describing: syncResult.declined))
                                        """,
                                       level: .info,
                                       category: .sync)
                            self.logger.log("""
                                        Returned telemetry:
                                        \(String(describing: syncResult.telemetryJson))
                                        """,
                                        level: .info,
                                        category: .sync)

                            // Save declined/enabled engines - we assume the engines
                            // not included in the returned `declined` property of the
                            // result of the sync manager `sync` are enabled.
                            let updateEnginePref:
                            (String, Bool) -> Void = { engine, enabled in
                                self.prefsForSync
                                    .setBool(enabled,
                                             forKey: "engine.\(engine).enabled")
                            }

                            if let declined = syncResult.declined {
                                RustTogglableEngines.forEach ({
                                    if declined.contains($0) {
                                        updateEnginePref($0, false)
                                    } else {
                                        updateEnginePref($0, true)
                                    }
                                })
                            } else {
                                RustTogglableEngines.forEach ({
                                    updateEnginePref($0, true)
                                })
                            }
                            
                            deferred.fill(Maybe(success: syncResult))
                            
                            self.endRustSyncing(syncResult)
                        }
                    }
                }
            }
        }
        return deferred
    }
    
    fileprivate func toSyncManagerDeviceType(
        deviceType: DeviceType
    ) -> SyncManagerDeviceType {
        switch deviceType{
        case .desktop:
            return SyncManagerDeviceType.desktop
        case .mobile:
            return SyncManagerDeviceType.mobile
        case .tablet:
            return SyncManagerDeviceType.tablet
        case .vr:
            return SyncManagerDeviceType.vr
        case .tv:
            return SyncManagerDeviceType.tv
        case .unknown:
            return SyncManagerDeviceType.unknown
        }
    }

    @discardableResult public func syncEverything(why: SyncReason) -> Success {
        if let accountManager = RustFirefoxAccounts.shared.accountManager.peek(),
           accountManager.accountMigrationInFlight() {
            accountManager.retryMigration { _ in }
            return Success()
        }

        let engines = [
            "tabs",
            "bookmarks",
            "history",
            "passwords",
        ]

        let convertedWhy = toRustSyncReason(reason: why)
        return self.syncRustEngines(why: convertedWhy, engines: engines) >>> succeed
    }

    /**
     * Allows selective sync of different collections, for use by external APIs.
     * Some help is given to callers who use different namespaces (specifically: `passwords` is mapped to `logins`)
     * and to preserve some ordering rules.
     */
    public func syncNamedCollections(why: SyncReason, names: [String]) -> Success {
        // Massage the list of names into engine identifiers.var engines = [String]()
        var engines = [String]()

        for name in names {
            // There may be duplicates in `names` so we are removing them here
            if !engines.contains(name) {
                engines.append(name)
            }
        }
        
        let orderedEngines = engines.compactMap {
            switch $0 {
            case "tabs": return "tabs"
            case "passwords": return "passwords"
            case "bookmarks": return "bookmarks"
            case "history": return "history"
            default: return nil
            }
        }
        
        let convertedWhy = toRustSyncReason(reason: why)
        return syncRustEngines(why: convertedWhy, engines: orderedEngines) >>> succeed
    }

    public func syncTabs() -> Deferred<Maybe<RustSyncResult>> {
        return syncRustEngines(why: .user, engines: ["tabs"])
    }
    
    public func syncClientsThenTabs() -> SyncResult {
        // XXX: This function exists to comply with the `SyncManager` protocol while the
        // rust sync manager rollout is enabled and will not be called. To be safe,
        // `syncTabs` is called. Once the rollout is complete this can be removed along
        // with an update to the protocol.
        
        return self.syncTabs().bind { result in
            if let error = result.failureValue {
                return deferMaybe(error)
            }
            
            // The current callers of `BrowserSyncManager.syncClientsThenTabs` only care
            // whether the function fails or succeeds, so we are returning a meaningless
            // value here
            return deferMaybe(SyncStatus.notStarted(SyncNotStartedReason.unknown))
        }
    }
        
    public func syncClients() -> SyncResult {
        // XXX: This function exists to to comply with the `SyncManager` protocol and has
        // no callers. It will be removed when the rust sync manager rollout is complete.
        // To be safe, `syncClientsThenTabs` is called.
        return self.syncClientsThenTabs()
    }
    
    public func syncHistory() -> SyncResult {
        // XXX: The retrurn type of this function has been changed to comply with the
        // `SyncManager` protocol during the rust sync manager rollout. It will be updated
        // once the rollout is complete.
        return syncRustEngines(why: .user, engines: ["history"]).bind { result in
            if let error = result.failureValue {
                return deferMaybe(error)
            }
            
            // The current callers of this function only care whether this function fails
            // or succeeds, so we are returning a meaningless value here.
            return deferMaybe(SyncStatus.notStarted(SyncNotStartedReason.unknown))
        }
    }
}
