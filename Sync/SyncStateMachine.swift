/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Account
import XCGLogger

// TODO: same comment as for SyncAuthState.swift!
private let log = XCGLogger.defaultInstance()

private let ShortCircuitMissingMetaGlobal = true           // Do this so we don't exercise 'recovery' code.
private let ShortCircuitMissingCryptoKeys = true           // Do this so we don't exercise 'recovery' code.

private let StorageVersionCurrent = 5
private let DefaultEngines: [String: Int] = ["tabs": 1]
private let DefaultDeclined: [String] = [String]()

private func getDefaultEngines() -> [String: EngineMeta] {
    return mapValues(DefaultEngines, { EngineMeta(version: $0, syncID: Bytes.generateGUID()) })
}

public typealias TokenSource = () -> Deferred<Result<TokenServerToken>>
public typealias ReadyDeferred = Deferred<Result<Ready>>

// See docs in docs/sync.md.

// You might be wondering why this doesn't have a Sync15StorageClient like FxALoginStateMachine
// does. Well, such a client is pinned to a particular server, and this state machine must
// acknowledge that a Sync client occasionally must migrate between two servers, preserving
// some state from the last.
// The resultant 'Ready' will be able to provide a suitably initialized storage client.
public class SyncStateMachine {
    private class func scratchpadPrefs(prefs: Prefs) -> Prefs {
        return prefs.branch("scratchpad")
    }

    public class func getInfoCollections(authState: SyncAuthState, prefs: Prefs) -> Deferred<Result<InfoCollections>> {
        log.debug("Fetching info/collections in state machine.")
        let token = authState.token(NSDate.now(), canBeExpired: true)
        return chainDeferred(token, { (token, kB) in
            // TODO: the token might not be expired! Check and selectively advance.
            log.debug("Got token from auth state. Advancing to InitialWithExpiredToken.")
            let state = InitialWithExpiredToken(scratchpad: Scratchpad(b: KeyBundle.fromKB(kB), persistingTo: self.scratchpadPrefs(prefs)), token: token)
            return state.getInfoCollections()
        })
    }

    public class func toReady(authState: SyncAuthState, prefs: Prefs) -> ReadyDeferred {
        let token = authState.token(NSDate.now(), canBeExpired: false)
        return chainDeferred(token, { (token, kB) in
            log.debug("Got token from auth state. Server is \(token.api_endpoint).")
            let scratchpadPrefs = self.scratchpadPrefs(prefs)
            let prior = Scratchpad.restoreFromPrefs(scratchpadPrefs, syncKeyBundle: KeyBundle.fromKB(kB))
            if prior == nil {
                log.info("No persisted Sync state. Starting over.")
            }
            let scratchpad = prior ?? Scratchpad(b: KeyBundle.fromKB(kB), persistingTo: scratchpadPrefs)

            log.info("Advancing to InitialWithLiveToken.")
            let state = InitialWithLiveToken(scratchpad: scratchpad, token: token)
            return advanceSyncState(state)
        })
    }
}

public enum SyncStateLabel: String {
    case Stub = "STUB"     // For 'abstract' base classes.

    case InitialWithExpiredToken = "initialWithExpiredToken"
    case InitialWithExpiredTokenAndInfo = "initialWithExpiredTokenAndInfo"
    case InitialWithLiveToken = "initialWithLiveToken"
    case InitialWithLiveTokenAndInfo = "initialWithLiveTokenAndInfo"
    case ResolveMetaGlobal = "resolveMetaGlobal"
    case NewMetaGlobal = "newMetaGlobal"
    case HasMetaGlobal = "hasMetaGlobal"
    case Restart = "restart"                                  // Go around again... once only, perhaps.
    case Ready = "ready"

    case ChangedServer = "changedServer"
    case MissingMetaGlobal = "missingMetaGlobal"
    case MissingCryptoKeys = "missingCryptoKeys"
    case MalformedCryptoKeys = "malformedCryptoKeys"
    case SyncIDChanged = "syncIDChanged"

    static let allValues: [SyncStateLabel] = [
        InitialWithExpiredToken,
        InitialWithExpiredTokenAndInfo,
        InitialWithLiveToken,
        InitialWithLiveTokenAndInfo,
        ResolveMetaGlobal,
        NewMetaGlobal,
        HasMetaGlobal,
        Restart,
        Ready,

        ChangedServer,
        MissingMetaGlobal,
        MissingCryptoKeys,
        MalformedCryptoKeys,
        SyncIDChanged,
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
    public func getInfoCollections() -> Deferred<Result<InfoCollections>> {
        return chain(self.client.getInfoCollections(), {
            return $0.value
        })
    }

    public init(client: Sync15StorageClient, scratchpad: Scratchpad, token: TokenServerToken) {
        self.scratchpad = scratchpad
        self.token = token
        self.client = client
        log.info("Inited \(self.label.rawValue)")
    }

    public func synchronizer<T: Synchronizer>(synchronizerClass: T.Type, prefs: Prefs) -> T {
        return T(scratchpad: self.scratchpad, basePrefs: prefs)
    }

    // This isn't a convenience initializer 'cos subclasses can't call convenience initializers.
    public init(scratchpad: Scratchpad, token: TokenServerToken) {
        let workQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        let resultQueue = dispatch_get_main_queue()
        let client = Sync15StorageClient(token: token, workQueue: workQueue, resultQueue: resultQueue)
        self.scratchpad = scratchpad
        self.token = token
        self.client = client
        log.info("Inited \(self.label.rawValue)")
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
public protocol SyncError: ErrorType {}

public class UnknownError: SyncError {
    public var description: String {
        return "Unknown error."
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

public class UpgradeRequiredError: SyncError {
    let targetStorageVersion: Int

    public init(target: Int) {
        self.targetStorageVersion = target
    }

    public var description: String {
        return "Upgrade required to work with storage version \(self.targetStorageVersion)."
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

public class MissingMetaGlobalAndUnwillingError: SyncError {
    public var description: String {
        return "No meta/global on server, and we're unwilling to create one."
    }
}

public class MissingCryptoKeysAndUnwillingError: SyncError {
    public var description: String {
        return "No crypto/keys on server, and we're unwilling to create one."
    }
}

/*
 * Error states. These are errors that can be recovered from by taking actions.
 */

public protocol RecoverableSyncState: SyncState, SyncError {
    // All error states must be able to advance to a usable state.
    func advance() -> Deferred<Result<SyncState>>
}

/**
 * Recovery: discard our local timestamps and sync states; discard caches.
 * Be prepared to handle a conflict between our selected engines and the new
 * server's meta/global; if an engine is selected locally but not declined
 * remotely, then we'll need to upload a new meta/global and sync that engine.
 */
public class ChangedServerError: RecoverableSyncState {
    public var label: SyncStateLabel { return SyncStateLabel.ChangedServer }

    public var description: String {
        return "Token destination changed to \(self.newToken.api_endpoint)/\(self.newToken.uid)."
    }

    let newToken: TokenServerToken
    let newScratchpad: Scratchpad

    public init(scratchpad: Scratchpad, token: TokenServerToken) {
        self.newToken = token
        self.newScratchpad = Scratchpad(b: scratchpad.syncKeyBundle, persistingTo: scratchpad.prefs)
    }

    public func advance() -> Deferred<Result<SyncState>> {
        // TODO: mutate local storage to allow for a fresh start.
        let state = InitialWithLiveToken(scratchpad: newScratchpad.checkpoint(), token: newToken)
        return Deferred(value: Result(success: state))
    }
}

/**
 * Recovery: same as for changed server, but no need to upload a new meta/global.
 */
public class SyncIDChangedError: RecoverableSyncState {
    public var label: SyncStateLabel { return SyncStateLabel.SyncIDChanged }

    public var description: String {
        return "Global sync ID changed."
    }

    private let previousState: BaseSyncStateWithInfo
    private let newMetaGlobal: Fetched<MetaGlobal>

    public init(previousState: BaseSyncStateWithInfo, newMetaGlobal: Fetched<MetaGlobal>) {
        self.previousState = previousState
        self.newMetaGlobal = newMetaGlobal
    }

    public func advance() -> Deferred<Result<SyncState>> {
        // TODO: mutate local storage to allow for a fresh start.
        let s = self.previousState.scratchpad.evolve().setGlobal(self.newMetaGlobal).setKeys(nil).build().checkpoint()
        let state = HasMetaGlobal(client: self.previousState.client, scratchpad: s, token: self.previousState.token, info: self.previousState.info)
        return Deferred(value: Result(success: state))
    }
}

/**
 * Recovery: wipe the server (perhaps unnecessarily), upload a new meta/global,
 * do a fresh start.
 */
public class MissingMetaGlobalError: RecoverableSyncState {
    public var label: SyncStateLabel { return SyncStateLabel.MissingMetaGlobal }

    public var description: String {
        return "Missing meta/global."
    }

    private let previousState: BaseSyncStateWithInfo

    public init(previousState: BaseSyncStateWithInfo) {
        self.previousState = previousState
    }

    // TODO: this needs EnginePreferences.
    private class func createMetaGlobal(previous: MetaGlobal?, scratchpad: Scratchpad) -> MetaGlobal {
        return MetaGlobal(syncID: Bytes.generateGUID(), storageVersion: StorageVersionCurrent, engines: getDefaultEngines(), declined: DefaultDeclined)
    }

    private func onWiped(resp: StorageResponse<JSON>, s: Scratchpad) -> Deferred<Result<SyncState>> {
        // Upload a new meta/global.
        // Note that we discard info/collections -- we just wiped storage.
        return Deferred(value: Result(success: InitialWithLiveToken(client: self.previousState.client, scratchpad: s, token: self.previousState.token)))
    }

    private func advanceFromWiped(wipe: Deferred<Result<StorageResponse<JSON>>>) -> Deferred<Result<SyncState>> {
        // TODO: mutate local storage to allow for a fresh start.
        // Note that we discard the previous global and keys -- after all, we just wiped storage.

        let s = self.previousState.scratchpad.evolve().setGlobal(nil).setKeys(nil).build().checkpoint()
        return chainDeferred(wipe, { self.onWiped($0, s: s) })
    }

    public func advance() -> Deferred<Result<SyncState>> {
        return self.advanceFromWiped(self.previousState.client.wipeStorage())
    }
}

// TODO
public class MissingCryptoKeysError: RecoverableSyncState {
    public var label: SyncStateLabel { return SyncStateLabel.MissingCryptoKeys }

    public var description: String {
        return "Missing crypto/keys."
    }

    public func advance() -> Deferred<Result<SyncState>> {
        return Deferred(value: Result(failure: MissingCryptoKeysAndUnwillingError()))
    }
}

/*
 * Non-error states.
 */

public class InitialWithExpiredToken: BaseSyncState {
    public override var label: SyncStateLabel { return SyncStateLabel.InitialWithExpiredToken }

    // This looks totally redundant, but try taking it out, I dare you.
    public override init(scratchpad: Scratchpad, token: TokenServerToken) {
        super.init(scratchpad: scratchpad, token: token)
    }

    func advanceWithInfo(info: InfoCollections) -> InitialWithExpiredTokenAndInfo {
        return InitialWithExpiredTokenAndInfo(scratchpad: self.scratchpad, token: self.token, info: info)
    }

    public func advanceIfNeeded(previous: InfoCollections?, collections: [String]?) -> Deferred<Result<InitialWithExpiredTokenAndInfo?>> {
        return chain(getInfoCollections(), { info in
            // Unchanged or no previous state? Short-circuit.
            if let previous = previous {
                if info.same(previous, collections: collections) {
                    return nil
                }
            }

            // Changed? Move to the next state with the fetched info.
            return self.advanceWithInfo(info)
        })
    }
}

public class InitialWithExpiredTokenAndInfo: BaseSyncStateWithInfo {
    public override var label: SyncStateLabel { return SyncStateLabel.InitialWithExpiredTokenAndInfo }

    public func advanceWithToken(liveTokenSource: TokenSource) -> Deferred<Result<InitialWithLiveTokenAndInfo>> {
        return chainResult(liveTokenSource(), { token in
            if self.token.sameDestination(token) {
                return Result(success: InitialWithLiveTokenAndInfo(scratchpad: self.scratchpad, token: token, info: self.info))
            }

            // Otherwise, we're screwed: we need to start over.
            // Pass in the new token, of course.
            return Result(failure: ChangedServerError(scratchpad: self.scratchpad, token: token))
        })
    }
}

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

    func advanceWithInfo(info: InfoCollections) -> InitialWithLiveTokenAndInfo {
        return InitialWithLiveTokenAndInfo(scratchpad: self.scratchpad, token: self.token, info: info)
    }

    public func advance() -> Deferred<Result<InitialWithLiveTokenAndInfo>> {
        return chain(getInfoCollections(), self.advanceWithInfo)
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
 * This state is similar in purpose to GlobalSession.processMetaGlobal in Android Sync.
 * TODO
 */

public class ResolveMetaGlobal: BaseSyncStateWithInfo {
    let fetched: Fetched<MetaGlobal>

    init(fetched: Fetched<MetaGlobal>, client: Sync15StorageClient, scratchpad: Scratchpad, token: TokenServerToken, info: InfoCollections) {
        self.fetched = fetched
        super.init(client: client, scratchpad: scratchpad, token: token, info: info)
    }
    public override var label: SyncStateLabel { return SyncStateLabel.ResolveMetaGlobal }

    class func fromState(state: BaseSyncStateWithInfo, fetched: Fetched<MetaGlobal>) -> ResolveMetaGlobal {
        return ResolveMetaGlobal(fetched: fetched, client: state.client, scratchpad: state.scratchpad, token: state.token, info: state.info)
    }


    func advanceAfterWipe(resp: StorageResponse<JSON>) -> ReadyDeferred {
        // This will only be called on a successful response.
        // Upload a new meta/global by advancing to an initial state.
        // Note that we discard info/collections -- we just wiped storage.
        let s = self.scratchpad.evolve().setGlobal(nil).setKeys(nil).build().checkpoint()
        let initial: InitialWithLiveToken = InitialWithLiveToken(client: self.client, scratchpad: s, token: self.token)
        return advanceSyncState(initial)
    }

    func advance() -> ReadyDeferred {
        // TODO: detect when an individual collection syncID has changed, and make sure that
        //       collection is reset.

        // First: check storage version.
        let v = fetched.value.storageVersion
        if v > StorageVersionCurrent {
            log.info("Client upgrade required for storage version \(v)")
            return Deferred(value: Result(failure: UpgradeRequiredError(target: v)))
        }

        if v < StorageVersionCurrent {
            log.info("Server storage version \(v) is outdated.")

            // Wipe the server and upload.
            // TODO: if we're connecting for the first time, and this is an old server, try
            //       to salvage old preferences from the old meta/global -- e.g., datatype elections.
            //       This doesn't need to be implemented until we rev the storage format, which
            //       might never happen.
            return chainDeferred(client.wipeStorage(), self.advanceAfterWipe)
        }

        // Second: check syncID and contents.
        if let previous = self.scratchpad.global?.value {
            // Do checks that only apply when we're coming from a previous meta/global.
            if previous.syncID != fetched.value.syncID {
                // Global syncID changed. Reset for every collection, and also throw away any cached keys.
                return resetStateWithGlobal(fetched)
            }

            // TODO: Check individual collections, resetting them as necessary if their syncID has changed!
            // For now, we just adopt the new meta/global, adjust our engines to match, and move on.
            // This means that if a per-engine syncID changes, *we won't do the right thing*.
            let withFetchedGlobal = self.scratchpad.withGlobal(fetched)
            return applyEngineChoicesAndAdvance(withFetchedGlobal)
        }

        // No previous meta/global. We know we need to do a fresh start sync.
        // This function will do the right thing if there's no previous meta/global.
        return resetStateWithGlobal(fetched)
    }

    /**
     * In some cases we downloaded a new meta/global, and we recognize that we need
     * a blank slate. This method makes one from our scratchpad, applies any necessary
     * changes to engine elections from the downloaded meta/global, uploads a changed
     * meta/global if we must, and then moves to HasMetaGlobal and on to Ready.
     * TODO: reset all local collections.
     */
    private func resetStateWithGlobal(fetched: Fetched<MetaGlobal>) -> ReadyDeferred {
        let fresh = self.scratchpad.freshStartWithGlobal(fetched)
        return applyEngineChoicesAndAdvance(fresh)
    }

    private func applyEngineChoicesAndAdvance(newScratchpad: Scratchpad) -> ReadyDeferred {
        // When we adopt a new meta global, we might update our local enabled/declined
        // engine lists (which are stored in the scratchpad itself), or need to add
        // some to meta/global. This call asks the scratchpad to return a possibly new
        // scratchpad, and optionally a meta/global to upload.
        // If this upload fails, we abort, of course.
        let previousMetaGlobal = self.scratchpad.global?.value
        let (withEnginesApplied: Scratchpad, toUpload: MetaGlobal?) = newScratchpad.applyEngineChoices(previousMetaGlobal)

        if let toUpload = toUpload {
            // Upload the new meta/global.
            // The provided scratchpad *does not reflect this new meta/global*: you need to
            // get the timestamp from the upload!
            let upload = self.client.uploadMetaGlobal(toUpload, ifUnmodifiedSince: fetched.timestamp)
            return chainDeferred(upload, { resp in
                let postUpload = withEnginesApplied.checkpoint()    // TODO: add the timestamp!
                return HasMetaGlobal.fromState(self, scratchpad: postUpload).advance()
            })
        }

        // If the meta/global was quietly applied, great; roll on with what we were given.
        return HasMetaGlobal.fromState(self, scratchpad: withEnginesApplied.checkpoint()).advance()
    }
}

public class InitialWithLiveTokenAndInfo: BaseSyncStateWithInfo {
    public override var label: SyncStateLabel { return SyncStateLabel.InitialWithLiveTokenAndInfo }

    private func processFailure(failure: ErrorType?) -> ErrorType {
        // For now, avoid the risky stuff.
        if ShortCircuitMissingMetaGlobal {
            return MissingMetaGlobalAndUnwillingError()
        }

        if let failure = failure as? NotFound<StorageResponse<GlobalEnvelope>> {
            // OK, this is easy.
            // This state is responsible for creating the new m/g, uploading it, and
            // restarting with a clean scratchpad.
            return MissingMetaGlobalError(previousState: self)
        }

        // TODO: backoff etc. for all of these.
        if let failure = failure as? ServerError<StorageResponse<GlobalEnvelope>> {
            // Be passive.
            return failure
        }

        if let failure = failure as? BadRequestError<StorageResponse<GlobalEnvelope>> {
            // Uh oh.
            log.error("Bad request. Bailing out. \(failure.description)")
            return failure
        }

        log.error("Unexpected failure. \(failure?.description)")
        return failure ?? UnknownError()
    }

    // This method basically hops over HasMetaGlobal, because it's not a state
    // that we expect consumers to know about.
    func advance() -> ReadyDeferred {
        // Either m/g and c/k are in our local cache, and they're up-to-date with i/c,
        // or we need to fetch them.
        // Cached and not changed in i/c? Use that.
        // This check would be inaccurate if any other fields were stored in meta/; this
        // has been the case in the past, with the Sync 1.1 migration indicator.
        if let global = self.scratchpad.global {
            if let metaModified = self.info.modified("meta") {
                // The record timestamp *should* be no more recent than the current collection.
                // We don't check that (indeed, we don't even store it!).
                // We also check the last fetch timestamp for the record, and that can be
                // later than the collection timestamp. All we care about here is if the
                // server might have a newer record.
                if global.timestamp >= metaModified {
                    log.info("Using cached meta/global.")
                    // Strictly speaking we can avoid fetching if this condition is not true,
                    // but if meta/ is modified for a different reason -- store timestamps
                    // for the last collection fetch. This will do for now.
                    return HasMetaGlobal.fromState(self).advance()
                }
            }
        }

        // Fetch.
        return self.client.getMetaGlobal().bind { result in
            if let resp = result.successValue {
                if let fetched = resp.value.toFetched() {
                    // We bump the meta/ timestamp because, though in theory there might be
                    // other records in that collection, even if there are we don't care about them.
                    self.scratchpad.collectionLastFetched["meta"] = resp.metadata.lastModifiedMilliseconds
                    return ResolveMetaGlobal.fromState(self, fetched: fetched).advance()
                }

                // This should not occur.
                log.error("Unexpectedly no meta/global despite a successful fetch.")
            }

            // Otherwise, we have a failure state.
            return Deferred(value: Result(failure: self.processFailure(result.failureValue)))
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

    private func processFailure(failure: ErrorType?) -> ErrorType {
        // For now, avoid the risky stuff.
        if ShortCircuitMissingCryptoKeys {
            return MissingCryptoKeysAndUnwillingError()
        }

        if let failure = failure as? NotFound<StorageResponse<KeysPayload>> {
            // This state is responsible for creating the new c/k, uploading it, and
            // restarting with a clean scratchpad.
            // But we haven't implemented it yet.
            return MissingCryptoKeysError()
        }

        // TODO: backoff etc. for all of these.
        if let failure = failure as? ServerError<StorageResponse<KeysPayload>> {
            // Be passive.
            return failure
        }

        if let failure = failure as? BadRequestError<StorageResponse<KeysPayload>> {
            // Uh oh.
            log.error("Bad request. Bailing out. \(failure.description)")
            return failure
        }

        log.error("Unexpected failure. \(failure?.description)")
        return failure ?? UnknownError()
    }

    func advance() -> ReadyDeferred {
        // Fetch crypto/keys, unless it's present in the cache already.
        // For now, just fetch.
        //
        // N.B., we assume that if the server has a meta/global, we don't have a cached crypto/keys,
        // and the server doesn't have crypto/keys, that the server was wiped.
        //
        // This assumption is basically so that we don't get trapped in a cycle of seeing this situation,
        // blanking the server, trying to upload meta/global, getting interrupted, and so on.
        //
        // I think this is pretty safe. TODO: verify this assumption by reading a-s and desktop code.
        //
        // TODO: detect when the keys have changed, and scream and run away if so.
        // TODO: upload keys if necessary, then go to Restart.
        let syncKey = Keys(defaultBundle: self.scratchpad.syncKeyBundle)
        let encoder = RecordEncoder<KeysPayload>(decode: { KeysPayload($0) }, encode: { $0 })
        let encrypter = syncKey.encrypter("keys", encoder: encoder)
        let client = self.client.clientForCollection("crypto", encrypter: encrypter)

        // TODO: this assumes that there are keys on the server. Check first, and if there aren't,
        // go ahead and go to an upload state without having to fail.
        return client.get("keys").bind {
            result in
            if let resp = result.successValue {
                let collectionKeys = Keys(payload: resp.value.payload)
                if (!collectionKeys.valid) {
                    log.error("Unexpectedly invalid crypto/keys during a successful fetch.")
                    return Deferred(value: Result(failure: InvalidKeysError(collectionKeys)))
                }

                // setKeys bumps the crypto/ timestamp because, though in theory there might be
                // other records in that collection, even if there are we don't care about them.
                let fetched = Fetched(value: collectionKeys, timestamp: resp.value.modified)
                let s = self.scratchpad.evolve().setKeys(fetched).build().checkpoint()
                let ready = Ready(client: self.client, scratchpad: s, token: self.token, info: self.info, keys: collectionKeys)

                log.info("Arrived in Ready state.")
                return Deferred(value: Result(success: ready))
            }

            // Otherwise, we have a failure state.
            // Much of this logic is shared with the meta/global fetch.
            return Deferred(value: Result(failure: self.processFailure(result.failureValue)))
        }
    }
}

public class Ready: BaseSyncStateWithInfo {
    public override var label: SyncStateLabel { return SyncStateLabel.Ready }
    let collectionKeys: Keys

    public init(client: Sync15StorageClient, scratchpad: Scratchpad, token: TokenServerToken, info: InfoCollections, keys: Keys) {
        self.collectionKeys = keys
        super.init(client: client, scratchpad: scratchpad, token: token, info: info)
    }
}


/*
 * Because a strongly typed state machine is incompatible with protocols,
 * we use function dispatch to ape a protocol.
 */
func advanceSyncState(s: InitialWithLiveToken) -> ReadyDeferred {
    return chainDeferred(s.advance(), { $0.advance() })
}

func advanceSyncState(s: HasMetaGlobal) -> ReadyDeferred {
    return s.advance()
}
