/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Account
import XCGLogger
import Deferred

private let log = Logger.syncLogger

private let StorageVersionCurrent = 5

// Names of collections for which a synchronizer is implemented locally.
private let LocalEngines: [String] = [
    "bookmarks",
    "clients",
    "history",
    "passwords",
    "tabs",
]

// Names of collections which will appear in a default meta/global produced locally.
// Map collection name to engine version.  See http://docs.services.mozilla.com/sync/objectformats.html.
private let DefaultEngines: [String: Int] = [
    "bookmarks": BookmarksStorageVersion,
    "clients": ClientsStorageVersion,
    "history": HistoryStorageVersion,
    "passwords": PasswordsStorageVersion,
    "tabs": TabsStorageVersion,
    // We opt-in to syncing collections we don't know about, since no client offers to sync non-enabled,
    // non-declined engines yet.  See Bug 969669.
    "forms": 1,
    "addons": 1,
    "prefs": 2,
]

// Names of collections which will appear as declined in a default
// meta/global produced locally.
private let DefaultDeclined: [String] = [String]()

// public for testing.
public func createMetaGlobalWithEngineConfiguration(engineConfiguration: EngineConfiguration) -> MetaGlobal {
    var engines: [String: EngineMeta] = [:]
    for engine in engineConfiguration.enabled {
        // We take this device's version, or, if we don't know the correct version, 0.  Another client should recognize
        // the engine, see an old version, wipe and start again.
        // TODO: this client does not yet do this wipe-and-update itself!
        let version = DefaultEngines[engine] ?? 0
        engines[engine] = EngineMeta(version: version, syncID: Bytes.generateGUID())
    }
    return MetaGlobal(syncID: Bytes.generateGUID(), storageVersion: StorageVersionCurrent, engines: engines, declined: engineConfiguration.declined)
}

public func createMetaGlobal() -> MetaGlobal {
    let engineConfiguration = EngineConfiguration(enabled: Array(DefaultEngines.keys), declined: DefaultDeclined)
    return createMetaGlobalWithEngineConfiguration(engineConfiguration)
}

public typealias TokenSource = () -> Deferred<Maybe<TokenServerToken>>
public typealias ReadyDeferred = Deferred<Maybe<Ready>>

// See docs in docs/sync.md.

// You might be wondering why this doesn't have a Sync15StorageClient like FxALoginStateMachine
// does. Well, such a client is pinned to a particular server, and this state machine must
// acknowledge that a Sync client occasionally must migrate between two servers, preserving
// some state from the last.
// The resultant 'Ready' will be able to provide a suitably initialized storage client.
public class SyncStateMachine {
    // The keys are used as a set, to prevent cycles in the state machine.
    var stateLabelsSeen = [SyncStateLabel: Bool]()
    var stateLabelSequence = [SyncStateLabel]()

    let scratchpadPrefs: Prefs

    public init(prefs: Prefs) {
        self.scratchpadPrefs = prefs.branch("scratchpad")
    }

    public class func clearStateFromPrefs(prefs: Prefs) {
        log.debug("Clearing all Sync prefs.")
        Scratchpad.clearFromPrefs(prefs.branch("scratchpad")) // XXX this is convoluted.
        prefs.clearAll()
    }

    private func advanceFromState(state: SyncState) -> ReadyDeferred {
        log.info("advanceFromState: \(state.label)")

        // Record visibility before taking any action.
        let labelAlreadySeen = self.stateLabelsSeen.updateValue(true, forKey: state.label) != nil
        stateLabelSequence.append(state.label)

        if let ready = state as? Ready {
            // Sweet, we made it!
            return deferMaybe(ready)
        }

        // Cycles are not necessarily a problem, but seeing the same (recoverable) error condition is a problem.
        if state is RecoverableSyncState && labelAlreadySeen {
            return deferMaybe(StateMachineCycleError())
        }

        return state.advance() >>== self.advanceFromState
    }

    public func toReady(authState: SyncAuthState) -> ReadyDeferred {
        let token = authState.token(NSDate.now(), canBeExpired: false)
        return chainDeferred(token, f: { (token, kB) in
            log.debug("Got token from auth state.")
            if Logger.logPII {
                log.debug("Server is \(token.api_endpoint).")
            }
            let prior = Scratchpad.restoreFromPrefs(self.scratchpadPrefs, syncKeyBundle: KeyBundle.fromKB(kB))
            if prior == nil {
                log.info("No persisted Sync state. Starting over.")
            }
            let scratchpad = prior ?? Scratchpad(b: KeyBundle.fromKB(kB), persistingTo: self.scratchpadPrefs)

            log.info("Advancing to InitialWithLiveToken.")
            let state = InitialWithLiveToken(scratchpad: scratchpad, token: token)

            // Start with fresh visibility data.
            self.stateLabelsSeen = [:]
            self.stateLabelSequence = []

            return self.advanceFromState(state)
        })
    }
}

public enum SyncStateLabel: String {
    case Stub = "STUB"     // For 'abstract' base classes.

    case InitialWithExpiredToken = "initialWithExpiredToken"
    case InitialWithExpiredTokenAndInfo = "initialWithExpiredTokenAndInfo"
    case InitialWithLiveToken = "initialWithLiveToken"
    case InitialWithLiveTokenAndInfo = "initialWithLiveTokenAndInfo"
    case ResolveMetaGlobalVersion = "resolveMetaGlobalVersion"
    case ResolveMetaGlobalContent = "resolveMetaGlobalContent"
    case NewMetaGlobal = "newMetaGlobal"
    case HasMetaGlobal = "hasMetaGlobal"
    case NeedsFreshCryptoKeys = "needsFreshCryptoKeys"
    case HasFreshCryptoKeys = "hasFreshCryptoKeys"
    case Ready = "ready"
    case FreshStartRequired = "freshStartRequired"                                  // Go around again... once only, perhaps.
    case ServerConfigurationRequired = "serverConfigurationRequired"

    case ChangedServer = "changedServer"
    case MissingMetaGlobal = "missingMetaGlobal"
    case MissingCryptoKeys = "missingCryptoKeys"
    case MalformedCryptoKeys = "malformedCryptoKeys"
    case SyncIDChanged = "syncIDChanged"
    case RemoteUpgradeRequired = "remoteUpgradeRequired"
    case ClientUpgradeRequired = "clientUpgradeRequired"

    static let allValues: [SyncStateLabel] = [
        InitialWithExpiredToken,
        InitialWithExpiredTokenAndInfo,
        InitialWithLiveToken,
        InitialWithLiveTokenAndInfo,
        ResolveMetaGlobalVersion,
        ResolveMetaGlobalContent,
        NewMetaGlobal,
        HasMetaGlobal,
        NeedsFreshCryptoKeys,
        HasFreshCryptoKeys,
        Ready,

        FreshStartRequired,
        ServerConfigurationRequired,

        ChangedServer,
        MissingMetaGlobal,
        MissingCryptoKeys,
        MalformedCryptoKeys,
        SyncIDChanged,
        RemoteUpgradeRequired,
        ClientUpgradeRequired,
    ]
}

/**
 * States in this state machine all implement SyncState.
 *
 * States are either successful main-flow states, or (recoverable) error states.
 * Errors that aren't recoverable are simply errors.
 * Main-flow states flow one to one.
 *
 * (Terminal failure states might be introduced at some point.)
 *
 * Multiple error states (but typically only one) can arise from each main state transition.
 * For example, parsing meta/global can result in a number of different non-routine situations.
 *
 * For these reasons, and the lack of useful ADTs in Swift, we model the main flow as
 * the success branch of a Result, and the recovery flows as a part of the failure branch.
 *
 * We could just as easily use a ternary Either-style operator, but thanks to Swift's
 * optional-cast-let it's no saving to do so.
 *
 * Because of the lack of type system support, all RecoverableSyncStates must have the same
 * signature. That signature implies a possibly multi-state transition; individual states
 * will have richer type signatures.
 */
public protocol SyncState {
    var label: SyncStateLabel { get }

    func advance() -> Deferred<Maybe<SyncState>>
}

/*
 * Base classes to avoid repeating initializers all over the place.
 */
public class BaseSyncState: SyncState {
    public var label: SyncStateLabel { return SyncStateLabel.Stub }

    public let client: Sync15StorageClient!
    let token: TokenServerToken    // Maybe expired.
    var scratchpad: Scratchpad

    // TODO: 304 for i/c.
    public func getInfoCollections() -> Deferred<Maybe<InfoCollections>> {
        return chain(self.client.getInfoCollections(), f: {
            return $0.value
        })
    }

    public init(client: Sync15StorageClient, scratchpad: Scratchpad, token: TokenServerToken) {
        self.scratchpad = scratchpad
        self.token = token
        self.client = client
        log.info("Inited \(self.label.rawValue)")
    }

    public func synchronizer<T: Synchronizer>(synchronizerClass: T.Type, delegate: SyncDelegate, prefs: Prefs) -> T {
        return T(scratchpad: self.scratchpad, delegate: delegate, basePrefs: prefs)
    }

    // This isn't a convenience initializer 'cos subclasses can't call convenience initializers.
    public init(scratchpad: Scratchpad, token: TokenServerToken) {
        let workQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        let resultQueue = dispatch_get_main_queue()
        let backoff = scratchpad.backoffStorage
        let client = Sync15StorageClient(token: token, workQueue: workQueue, resultQueue: resultQueue, backoff: backoff)
        self.scratchpad = scratchpad
        self.token = token
        self.client = client
        log.info("Inited \(self.label.rawValue)")
    }

    public func advance() -> Deferred<Maybe<SyncState>> {
        return deferMaybe(StubStateError())
    }
}

public class BaseSyncStateWithInfo: BaseSyncState {
    public let info: InfoCollections

    init(client: Sync15StorageClient, scratchpad: Scratchpad, token: TokenServerToken, info: InfoCollections) {
        self.info = info
        super.init(client: client, scratchpad: scratchpad, token: token)
    }

    init(scratchpad: Scratchpad, token: TokenServerToken, info: InfoCollections) {
        self.info = info
        super.init(scratchpad: scratchpad, token: token)
    }
}

/*
 * Error types.
 */
public protocol SyncError: MaybeErrorType {}

public class UnknownError: SyncError {
    public var description: String {
        return "Unknown error."
    }
}

public class StateMachineCycleError: SyncError {
    public var description: String {
        return "The Sync state machine encountered a cycle. This is a coding error."
    }
}

public class CouldNotFetchMetaGlobalError: SyncError {
    public var description: String {
        return "Could not fetch meta/global."
    }
}

public class CouldNotFetchKeysError: SyncError {
    public var description: String {
        return "Could not fetch crypto/keys."
    }
}

public class StubStateError: SyncError {
    public var description: String {
        return "Unexpectedly reached a stub state. This is a coding error."
    }
}

public class ClientUpgradeRequiredError: SyncError {
    let targetStorageVersion: Int

    public init(target: Int) {
        self.targetStorageVersion = target
    }

    public var description: String {
        return "Client upgrade required to work with storage version \(self.targetStorageVersion)."
    }
}

public class InvalidKeysError: SyncError {
    let keys: Keys

    public init(_ keys: Keys) {
        self.keys = keys
    }

    public var description: String {
        return "Downloaded crypto/keys, but couldn't parse them."
    }
}

/**
 * Error states. These are errors that can be recovered from by taking actions.  We use RecoverableSyncState as a
 * sentinel: if we see the same recoverable state twice, we bail out and complain that we've seen a cycle.  (Seeing
 * some states -- principally initial states -- twice is fine.)
*/

public protocol RecoverableSyncState: SyncState {
}

/**
 * Recovery: discard our local timestamps and sync states; discard caches.
 * Be prepared to handle a conflict between our selected engines and the new
 * server's meta/global; if an engine is selected locally but not declined
 * remotely, then we'll need to upload a new meta/global and sync that engine.
 */
public class ChangedServerError: RecoverableSyncState {
    public var label: SyncStateLabel { return SyncStateLabel.ChangedServer }

    let newToken: TokenServerToken
    let newScratchpad: Scratchpad

    public init(scratchpad: Scratchpad, token: TokenServerToken) {
        self.newToken = token
        self.newScratchpad = Scratchpad(b: scratchpad.syncKeyBundle, persistingTo: scratchpad.prefs)
    }

    public func advance() -> Deferred<Maybe<SyncState>> {
        // TODO: mutate local storage to allow for a fresh start.
        let state = InitialWithLiveToken(scratchpad: newScratchpad.checkpoint(), token: newToken)
        return deferMaybe(state)
    }
}

/**
 * Recovery: same as for changed server, but no need to upload a new meta/global.
 */
public class SyncIDChangedError: RecoverableSyncState {
    public var label: SyncStateLabel { return SyncStateLabel.SyncIDChanged }

    private let previousState: BaseSyncStateWithInfo
    private let newMetaGlobal: Fetched<MetaGlobal>

    public init(previousState: BaseSyncStateWithInfo, newMetaGlobal: Fetched<MetaGlobal>) {
        self.previousState = previousState
        self.newMetaGlobal = newMetaGlobal
    }

    public func advance() -> Deferred<Maybe<SyncState>> {
        // TODO: mutate local storage to allow for a fresh start.
        let s = self.previousState.scratchpad.evolve().setGlobal(self.newMetaGlobal).setKeys(nil).build().checkpoint()
        let state = HasMetaGlobal(client: self.previousState.client, scratchpad: s, token: self.previousState.token, info: self.previousState.info)
        return deferMaybe(state)
    }
}

/**
 * Recovery: configure the server.
 */
public class ServerConfigurationRequiredError: RecoverableSyncState {
    public var label: SyncStateLabel { return SyncStateLabel.ServerConfigurationRequired }

    private let previousState: BaseSyncStateWithInfo

    public init(previousState: BaseSyncStateWithInfo) {
        self.previousState = previousState
    }

    public func advance() -> Deferred<Maybe<SyncState>> {
        let client = self.previousState.client
        let s = self.previousState.scratchpad.evolve()
                .setGlobal(nil)
                .addLocalCommandsFromKeys(nil)
                .setKeys(nil)
                .build().checkpoint()
        // Upload a new meta/global ...
        let metaGlobal: MetaGlobal
        if let oldEngineConfiguration = s.engineConfiguration {
            metaGlobal = createMetaGlobalWithEngineConfiguration(oldEngineConfiguration)
        } else {
            metaGlobal = createMetaGlobal()
        }
        return client.uploadMetaGlobal(metaGlobal, ifUnmodifiedSince: nil)
            // ... and a new crypto/keys.
            >>> { return client.uploadCryptoKeys(Keys.random(), withSyncKeyBundle: s.syncKeyBundle, ifUnmodifiedSince: nil) }
            >>> { return deferMaybe(InitialWithLiveToken(client: client, scratchpad: s, token: self.previousState.token)) }
    }
}

/**
 * Recovery: wipe the server (perhaps unnecessarily) and proceed to configure the server.
 */
public class FreshStartRequiredError: RecoverableSyncState {
    public var label: SyncStateLabel { return SyncStateLabel.FreshStartRequired }

    private let previousState: BaseSyncStateWithInfo

    public init(previousState: BaseSyncStateWithInfo) {
        self.previousState = previousState
    }

    public func advance() -> Deferred<Maybe<SyncState>> {
        let client = self.previousState.client
        return client.wipeStorage()
            >>> { return deferMaybe(ServerConfigurationRequiredError(previousState: self.previousState)) }
    }
}

public class MissingMetaGlobalError: RecoverableSyncState {
    public var label: SyncStateLabel { return SyncStateLabel.MissingMetaGlobal }

    private let previousState: BaseSyncStateWithInfo

    public init(previousState: BaseSyncStateWithInfo) {
        self.previousState = previousState
    }

    public func advance() -> Deferred<Maybe<SyncState>> {
        return deferMaybe(FreshStartRequiredError(previousState: self.previousState))
    }
}

public class MissingCryptoKeysError: RecoverableSyncState {
    public var label: SyncStateLabel { return SyncStateLabel.MissingCryptoKeys }

    private let previousState: BaseSyncStateWithInfo

    public init(previousState: BaseSyncStateWithInfo) {
        self.previousState = previousState
    }

    public func advance() -> Deferred<Maybe<SyncState>> {
        return deferMaybe(FreshStartRequiredError(previousState: self.previousState))
    }
}

public class RemoteUpgradeRequired: RecoverableSyncState {
    public var label: SyncStateLabel { return SyncStateLabel.RemoteUpgradeRequired }

    private let previousState: BaseSyncStateWithInfo

    public init(previousState: BaseSyncStateWithInfo) {
        self.previousState = previousState
    }

    public func advance() -> Deferred<Maybe<SyncState>> {
        return deferMaybe(FreshStartRequiredError(previousState: self.previousState))
    }
}

public class ClientUpgradeRequired: RecoverableSyncState {
    public var label: SyncStateLabel { return SyncStateLabel.ClientUpgradeRequired }

    private let previousState: BaseSyncStateWithInfo
    let targetStorageVersion: Int

    public init(previousState: BaseSyncStateWithInfo, target: Int) {
        self.previousState = previousState
        self.targetStorageVersion = target
    }

    public func advance() -> Deferred<Maybe<SyncState>> {
        return deferMaybe(ClientUpgradeRequiredError(target: self.targetStorageVersion))
    }
}

/*
 * Non-error states.
 */

public class InitialWithLiveToken: BaseSyncState {
    public override var label: SyncStateLabel { return SyncStateLabel.InitialWithLiveToken }

    // This looks totally redundant, but try taking it out, I dare you.
    public override init(scratchpad: Scratchpad, token: TokenServerToken) {
        super.init(scratchpad: scratchpad, token: token)
    }

    // This looks totally redundant, but try taking it out, I dare you.
    public override init(client: Sync15StorageClient, scratchpad: Scratchpad, token: TokenServerToken) {
        super.init(client: client, scratchpad: scratchpad, token: token)
    }

    func advanceWithInfo(info: InfoCollections) -> SyncState {
        return InitialWithLiveTokenAndInfo(scratchpad: self.scratchpad, token: self.token, info: info)
    }

    override public func advance() -> Deferred<Maybe<SyncState>> {
        return chain(getInfoCollections(), f: self.advanceWithInfo)
    }
}

/**
 * Each time we fetch a new meta/global, we need to reconcile it with our
 * current state.
 *
 * It might be identical to our current meta/global, in which case we can short-circuit.
 *
 * We might have no previous meta/global at all, in which case this state
 * simply configures local storage to be ready to sync according to the
 * supplied meta/global. (Not necessarily datatype elections: those will be per-device.)
 *
 * Or it might be different. In this case the previous m/g and our local user preferences
 * are compared to the new, resulting in some actions and a final state.
 *
 * This states are similar in purpose to GlobalSession.processMetaGlobal in Android Sync.
 */

public class ResolveMetaGlobalVersion: BaseSyncStateWithInfo {
    let fetched: Fetched<MetaGlobal>

    init(fetched: Fetched<MetaGlobal>, client: Sync15StorageClient, scratchpad: Scratchpad, token: TokenServerToken, info: InfoCollections) {
        self.fetched = fetched
        super.init(client: client, scratchpad: scratchpad, token: token, info: info)
    }
    public override var label: SyncStateLabel { return SyncStateLabel.ResolveMetaGlobalVersion }

    class func fromState(state: BaseSyncStateWithInfo, fetched: Fetched<MetaGlobal>) -> ResolveMetaGlobalVersion {
        return ResolveMetaGlobalVersion(fetched: fetched, client: state.client, scratchpad: state.scratchpad, token: state.token, info: state.info)
    }

    override public func advance() -> Deferred<Maybe<SyncState>> {
        // First: check storage version.
        let v = fetched.value.storageVersion
        if v > StorageVersionCurrent {
            // New storage version?  Uh-oh.  No recovery possible here.
            log.info("Client upgrade required for storage version \(v)")
            return deferMaybe(ClientUpgradeRequired(previousState: self, target: v))
        }

        if v < StorageVersionCurrent {
            // Old storage version?  Uh-oh.  Wipe and upload both meta/global and crypto/keys.
            log.info("Server storage version \(v) is outdated.")
            return deferMaybe(RemoteUpgradeRequired(previousState: self))
        }

        return deferMaybe(ResolveMetaGlobalContent.fromState(self, fetched: self.fetched))
    }
}

public class ResolveMetaGlobalContent: BaseSyncStateWithInfo {
    let fetched: Fetched<MetaGlobal>

    init(fetched: Fetched<MetaGlobal>, client: Sync15StorageClient, scratchpad: Scratchpad, token: TokenServerToken, info: InfoCollections) {
        self.fetched = fetched
        super.init(client: client, scratchpad: scratchpad, token: token, info: info)
    }
    public override var label: SyncStateLabel { return SyncStateLabel.ResolveMetaGlobalContent }

    class func fromState(state: BaseSyncStateWithInfo, fetched: Fetched<MetaGlobal>) -> ResolveMetaGlobalContent {
        return ResolveMetaGlobalContent(fetched: fetched, client: state.client, scratchpad: state.scratchpad, token: state.token, info: state.info)
    }

    override public func advance() -> Deferred<Maybe<SyncState>> {
        // Check global syncID and contents.
        if let previous = self.scratchpad.global?.value {
            // Do checks that only apply when we're coming from a previous meta/global.
            if previous.syncID != fetched.value.syncID {
                log.info("Remote global sync ID has changed. Dropping keys and resetting all local collections.")
                let s = self.scratchpad.freshStartWithGlobal(fetched).checkpoint()
                return deferMaybe(HasMetaGlobal.fromState(self, scratchpad: s))
            }

            let b = self.scratchpad.evolve()
                .setGlobal(fetched) // We always adopt the upstream meta/global record.

            let previousEngines = Set(previous.engines.keys)
            let remoteEngines = Set(fetched.value.engines.keys)

            for engine in previousEngines.subtract(remoteEngines) {
                log.info("Remote meta/global disabled previously enabled engine \(engine).")
                b.localCommands.insert(.DisableEngine(engine: engine))
            }

            for engine in remoteEngines.subtract(previousEngines) {
                log.info("Remote meta/global enabled previously disabled engine \(engine).")
                b.localCommands.insert(.EnableEngine(engine: engine))
            }

            for engine in remoteEngines.intersect(previousEngines) {
                let remoteEngine = fetched.value.engines[engine]!
                let previousEngine = previous.engines[engine]!
                if previousEngine.syncID != remoteEngine.syncID {
                    log.info("Remote sync ID for \(engine) has changed. Resetting local.")
                    b.localCommands.insert(.ResetEngine(engine: engine))
                }
            }

            let s = b.build().checkpoint()
            return deferMaybe(HasMetaGlobal.fromState(self, scratchpad: s))
        }

        // No previous meta/global. Adopt the new meta/global.
        let s = self.scratchpad.freshStartWithGlobal(fetched).checkpoint()
        return deferMaybe(HasMetaGlobal.fromState(self, scratchpad: s))
    }
}

private func processFailure(failure: MaybeErrorType?) -> MaybeErrorType {
    if let failure = failure as? ServerInBackoffError {
        log.warning("Server in backoff. Bailing out. \(failure.description)")
        return failure
    }

    // TODO: backoff etc. for all of these.
    if let failure = failure as? ServerError<NSHTTPURLResponse> {
        // Be passive.
        log.error("Server error. Bailing out. \(failure.description)")
        return failure
    }

    if let failure = failure as? BadRequestError<NSHTTPURLResponse> {
        // Uh oh.
        log.error("Bad request. Bailing out. \(failure.description)")
        return failure
    }

    log.error("Unexpected failure. \(failure?.description)")
    return failure ?? UnknownError()
}

public class InitialWithLiveTokenAndInfo: BaseSyncStateWithInfo {
    public override var label: SyncStateLabel { return SyncStateLabel.InitialWithLiveTokenAndInfo }

    // This method basically hops over HasMetaGlobal, because it's not a state
    // that we expect consumers to know about.
    override public func advance() -> Deferred<Maybe<SyncState>> {
        // Either m/g and c/k are in our local cache, and they're up-to-date with i/c,
        // or we need to fetch them.
        // Cached and not changed in i/c? Use that.
        // This check would be inaccurate if any other fields were stored in meta/; this
        // has been the case in the past, with the Sync 1.1 migration indicator.
        if let global = self.scratchpad.global {
            if let metaModified = self.info.modified("meta") {
                // We check the last time we fetched the record, and that can be
                // later than the collection timestamp. All we care about here is if the
                // server might have a newer record.
                if global.timestamp >= metaModified {
                    log.debug("Cached meta/global fetched at \(global.timestamp), newer than server modified \(metaModified). Using cached meta/global.")
                    // Strictly speaking we can avoid fetching if this condition is not true,
                    // but if meta/ is modified for a different reason -- store timestamps
                    // for the last collection fetch. This will do for now.
                    return deferMaybe(HasMetaGlobal.fromState(self))
                }
                log.info("Cached meta/global fetched at \(global.timestamp) older than server modified \(metaModified). Fetching fresh meta/global.")
            } else {
                // No known modified time for meta/. That means the server has no meta/global.
                // Drop our cached value and fall through; we'll try to fetch, fail, and
                // go through the usual failure flow.
                log.warning("Local meta/global fetched at \(global.timestamp) found, but no meta collection on server. Dropping cached meta/global.")
                self.scratchpad = self.scratchpad.evolve().setGlobal(nil).setKeys(nil).build().checkpoint()
            }
        } else {
            log.debug("No cached meta/global found. Fetching fresh meta/global.")
        }

        // Fetch.
        return self.client.getMetaGlobal().bind { result in
            if let resp = result.successValue {
                // We use the server's timestamp, rather than the record's modified field.
                // Either can be made to work, but the latter has suffered from bugs: see Bug 1210625.
                let fetched = Fetched(value: resp.value, timestamp: resp.metadata.timestampMilliseconds)
                return deferMaybe(ResolveMetaGlobalVersion.fromState(self, fetched: fetched))
            }

            if let _ = result.failureValue as? NotFound<NSHTTPURLResponse> {
                // OK, this is easy.
                // This state is responsible for creating the new m/g, uploading it, and
                // restarting with a clean scratchpad.
                return deferMaybe(MissingMetaGlobalError(previousState: self))
            }

            // Otherwise, we have a failure state.  Die on the sword!
            return deferMaybe(processFailure(result.failureValue))
        }
    }
}

public class HasMetaGlobal: BaseSyncStateWithInfo {
    public override var label: SyncStateLabel { return SyncStateLabel.HasMetaGlobal }

    class func fromState(state: BaseSyncStateWithInfo) -> HasMetaGlobal {
        return HasMetaGlobal(client: state.client, scratchpad: state.scratchpad, token: state.token, info: state.info)
    }

    class func fromState(state: BaseSyncStateWithInfo, scratchpad: Scratchpad) -> HasMetaGlobal {
        return HasMetaGlobal(client: state.client, scratchpad: scratchpad, token: state.token, info: state.info)
    }

    override public func advance() -> Deferred<Maybe<SyncState>> {
        // Check if crypto/keys is fresh in the cache already.
        if let keys = self.scratchpad.keys where keys.value.valid {
            if let cryptoModified = self.info.modified("crypto") {
                // Both of these are server timestamps. If the record we stored was fetched after the last time the record was modified, as represented by the "crypto" entry in info/collections, and we're fetching from the
                // same server, then the record must be identical, and we can use it directly.  If are ever additional records in the crypto collection, this will fetch keys too frequently.  In that case, we should use X-I-U-S and expect some 304 responses.
                if keys.timestamp >= cryptoModified {
                    log.debug("Cached keys fetched at \(keys.timestamp), newer than server modified \(cryptoModified). Using cached keys.")
                    return deferMaybe(HasFreshCryptoKeys.fromState(self, scratchpad: self.scratchpad, collectionKeys: keys.value))
                }

                // The server timestamp is newer, so there might be new keys.
                // Re-fetch keys and check to see if the actual contents differ.
                // If the keys are the same, we can ignore this change. If they differ,
                // we need to re-sync any collection whose keys just changed.
                log.info("Cached keys fetched at \(keys.timestamp) older than server modified \(cryptoModified). Fetching fresh keys.")
                return deferMaybe(NeedsFreshCryptoKeys.fromState(self, scratchpad: self.scratchpad, staleCollectionKeys: keys.value))
            } else {
                // No known modified time for crypto/. That likely means the server has no keys.
                // Drop our cached value and fall through; we'll try to fetch, fail, and
                // go through the usual failure flow.
                log.warning("Local keys fetched at \(keys.timestamp) found, but no crypto collection on server. Dropping cached keys.")
                self.scratchpad = self.scratchpad.evolve().setKeys(nil).build().checkpoint()
            }
        } else {
            log.debug("No cached keys found. Fetching fresh keys.")
        }

        return deferMaybe(NeedsFreshCryptoKeys.fromState(self, scratchpad: self.scratchpad, staleCollectionKeys: nil))
    }
}

public class NeedsFreshCryptoKeys: BaseSyncStateWithInfo {
    public override var label: SyncStateLabel { return SyncStateLabel.NeedsFreshCryptoKeys }
    let staleCollectionKeys: Keys?

    class func fromState(state: BaseSyncStateWithInfo, scratchpad: Scratchpad, staleCollectionKeys: Keys?) -> NeedsFreshCryptoKeys {
        return NeedsFreshCryptoKeys(client: state.client, scratchpad: scratchpad, token: state.token, info: state.info, keys: staleCollectionKeys)
    }

    public init(client: Sync15StorageClient, scratchpad: Scratchpad, token: TokenServerToken, info: InfoCollections, keys: Keys?) {
        self.staleCollectionKeys = keys
        super.init(client: client, scratchpad: scratchpad, token: token, info: info)
    }

    override public func advance() -> Deferred<Maybe<SyncState>> {
        // Fetch crypto/keys.
        return self.client.getCryptoKeys(self.scratchpad.syncKeyBundle, ifUnmodifiedSince: nil).bind { result in
            if let resp = result.successValue {
                let collectionKeys = Keys(payload: resp.value.payload)
                if (!collectionKeys.valid) {
                    log.error("Unexpectedly invalid crypto/keys during a successful fetch.")
                    return Deferred(value: Maybe(failure: InvalidKeysError(collectionKeys)))
                }

                let fetched = Fetched(value: collectionKeys, timestamp: resp.metadata.timestampMilliseconds)
                let s = self.scratchpad.evolve()
                        .addLocalCommandsFromKeys(fetched)
                        .setKeys(fetched)
                        .build().checkpoint()
                return deferMaybe(HasFreshCryptoKeys.fromState(self, scratchpad: s, collectionKeys: collectionKeys))
            }

            if let _ = result.failureValue as? NotFound<NSHTTPURLResponse> {
                // No crypto/keys?  We can handle this.  Wipe and upload both meta/global and crypto/keys.
                return deferMaybe(MissingCryptoKeysError(previousState: self))
            }

            // Otherwise, we have a failure state.
            return deferMaybe(processFailure(result.failureValue))
        }
    }
}

public class HasFreshCryptoKeys: BaseSyncStateWithInfo {
    public override var label: SyncStateLabel { return SyncStateLabel.HasFreshCryptoKeys }
    let collectionKeys: Keys

    class func fromState(state: BaseSyncStateWithInfo, scratchpad: Scratchpad, collectionKeys: Keys) -> HasFreshCryptoKeys {
        return HasFreshCryptoKeys(client: state.client, scratchpad: scratchpad, token: state.token, info: state.info, keys: collectionKeys)
    }

    public init(client: Sync15StorageClient, scratchpad: Scratchpad, token: TokenServerToken, info: InfoCollections, keys: Keys) {
        self.collectionKeys = keys
        super.init(client: client, scratchpad: scratchpad, token: token, info: info)
    }

    override public func advance() -> Deferred<Maybe<SyncState>> {
        return deferMaybe(Ready(client: self.client, scratchpad: self.scratchpad, token: self.token, info: self.info, keys: self.collectionKeys))
    }
}

public protocol EngineStateChanges {
    func collectionsThatNeedLocalReset() -> [String]
    func enginesEnabled() -> [String]
    func enginesDisabled() -> [String]
    func clearLocalCommands()
}

public class Ready: BaseSyncStateWithInfo {
    public override var label: SyncStateLabel { return SyncStateLabel.Ready }
    let collectionKeys: Keys

    public init(client: Sync15StorageClient, scratchpad: Scratchpad, token: TokenServerToken, info: InfoCollections, keys: Keys) {
        self.collectionKeys = keys
        super.init(client: client, scratchpad: scratchpad, token: token, info: info)
    }
}

extension Ready: EngineStateChanges {
    public func collectionsThatNeedLocalReset() -> [String] {
        var needReset: Set<String> = Set()
        for command in self.scratchpad.localCommands {
            switch command {
            case let .ResetAllEngines(except: except):
                needReset.unionInPlace(Set(LocalEngines).subtract(except))
            case let .ResetEngine(engine):
                needReset.insert(engine)
            case .EnableEngine, .DisableEngine:
                break
            }
        }
        return Array(needReset).sort()
    }

    public func enginesEnabled() -> [String] {
        var engines: Set<String> = Set()
        for command in self.scratchpad.localCommands {
            switch command {
            case let .EnableEngine(engine):
                engines.insert(engine)
            default:
                break
            }
        }
        return Array(engines).sort()
    }

    public func enginesDisabled() -> [String] {
        var engines: Set<String> = Set()
        for command in self.scratchpad.localCommands {
            switch command {
            case let .DisableEngine(engine):
                engines.insert(engine)
            default:
                break
            }
        }
        return Array(engines).sort()
    }

    public func clearLocalCommands() {
        self.scratchpad = self.scratchpad.evolve().clearLocalCommands().build().checkpoint()
    }
}
