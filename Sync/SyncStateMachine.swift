/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Account

public typealias TokenSource = () -> Deferred<Result<TokenServerToken>>

// See docs in docs/sync.md.

// You might be wondering why this doesn't have a Sync15StorageClient like FxALoginStateMachine
// does. Well, such a client is pinned to a particular server, and this state machine must
// acknowledge that a Sync client occasionally must migrate between two servers, preserving
// some state from the last.
// The resultant 'Ready' will have a suitably initialized storage client.
public class SyncStateMachine {
    public class func getInfoCollections(authState: SyncAuthState) -> Deferred<Result<InfoCollections>> {
        let token = authState.token(NSDate.now(), canBeExpired: true)
        return chainDeferred(token, { (token, kB) in
            let state = InitialWithExpiredToken(scratchpad: Scratchpad(b: KeyBundle.fromKB(kB)), token: token)
            return state.getInfoCollections()
        })
    }

    public class func toReady(authState: SyncAuthState) -> Deferred<Result<Ready>> {
        let token = authState.token(NSDate.now(), canBeExpired: false)
        return chainDeferred(token, { (token, kB) in
            let state = InitialWithLiveToken(scratchpad: Scratchpad(b: KeyBundle.fromKB(kB)), token: token)
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

    let client: Sync15StorageClient!
    let token: TokenServerToken    // Maybe expired.
    var scratchpad: Scratchpad

    // TODO: 304 for i/c.
    public func getInfoCollections() -> Deferred<Result<InfoCollections>> {
        return chain(self.client.getInfoCollections(), {
            return $0.value
        })
    }

    init(client: Sync15StorageClient, scratchpad: Scratchpad, token: TokenServerToken) {
        self.scratchpad = scratchpad
        self.token = token
        self.client = client
    }

    init(scratchpad: Scratchpad, token: TokenServerToken) {
        let workQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        let resultQueue = dispatch_get_main_queue()
        let client = Sync15StorageClient(token: token, workQueue: workQueue, resultQueue: resultQueue)
        self.scratchpad = scratchpad
        self.token = token
        self.client = client
    }
}

public class BaseSyncStateWithInfo: BaseSyncState {
    let info: InfoCollections

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
public protocol SyncError {}

public class CouldNotFetchMetaGlobalError: SyncError, ErrorType {
    public var description: String {
        return "Could not fetch meta/global."
    }
}

public class CouldNotFetchKeysError: SyncError, ErrorType {
    public var description: String {
        return "Could not fetch crypto/keys."
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
    let syncKeyBundle: KeyBundle

    public init(scratchpad: Scratchpad, token: TokenServerToken) {
        self.newToken = token
        self.syncKeyBundle = scratchpad.syncKeyBundle
    }

    public func advance() -> Deferred<Result<SyncState>> {
        // TODO: mutate local storage to allow for a fresh start.
        let state = InitialWithLiveToken(scratchpad: Scratchpad(b: self.syncKeyBundle), token: newToken)
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
        let s = Scratchpad(b: self.previousState.scratchpad.syncKeyBundle, m: self.newMetaGlobal, k: nil)
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

    public func advance() -> Deferred<Result<SyncState>> {
        // TODO: mutate local storage to allow for a fresh start.
        let s = Scratchpad(b: self.previousState.scratchpad.syncKeyBundle, m: nil, k: nil)

        // Note that we discard the previous info/collections -- after all, we just wiped storage.
        let wipe = self.previousState.client.wipeStorage()
        return chain(wipe, { resp in
            // TODO: upload new meta/global.
            return InitialWithLiveToken(client: self.previousState.client, scratchpad: s, token: self.previousState.token)
        })
    }
}

public class InvalidKeysError: ErrorType {
    let keys: Keys

    public init(_ keys: Keys) {
        self.keys = keys
    }

    public var description: String {
        return "Invalid crypto/keys."
    }
}

/*
 * Real states.
 */

public class InitialWithExpiredToken: BaseSyncState {
    public override var label: SyncStateLabel { return SyncStateLabel.InitialWithExpiredToken }

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

    func advanceWithInfo(info: InfoCollections) -> InitialWithLiveTokenAndInfo {
        return InitialWithLiveTokenAndInfo(scratchpad: self.scratchpad, token: self.token, info: info)
    }

    public func advance() -> Deferred<Result<InitialWithLiveTokenAndInfo>> {
        return chain(getInfoCollections(), self.advanceWithInfo)
    }
}

public class InitialWithLiveTokenAndInfo: BaseSyncStateWithInfo {
    public override var label: SyncStateLabel { return SyncStateLabel.InitialWithLiveTokenAndInfo }

    func advanceToMG() -> Deferred<Result<HasMetaGlobal>> {
        // Cached and not changed in i/c? Use that.
        // This check is inaccurate (particularly if a migration indicator is present).
        if let global = self.scratchpad.global {
            if let metaModified = self.info.modified("meta") {
                if global.timestamp == metaModified {
                    // Strictly speaking we can avoid fetching if this condition is not true,
                    // but if meta/ is modified for a different reason -- store timestamps
                    // for the last collection fetch. This will do for now.
                    let newState = HasMetaGlobal.fromState(self)
                    return Deferred(value: Result(success: newState))
                }
            }
        }

        // Fetch.
        // TODO: detect when the global syncID has changed.
        // TODO: detect when an individual collection syncID has changed, and make sure that
        //       collection is reset.
        // TODO: detect when the sets of declined or enabled engines have changed, and update
        //       our preferences accordingly.
        return self.client.getMetaGlobal().map { result in
            if let resp = result.successValue?.value {
                let newState = HasMetaGlobal.fromState(self, scratchpad: self.scratchpad.withGlobal(resp))
                return Result(success: newState)
            }

            // TODO: create, upload, go to Restart?
            // Or should we return an intermediate state to allow a graceful exit?
            // Remember to return a restarted scratchpad, too.
            return Result(failure: result.failureValue!)
        }
    }

    // This method basically hops over HasMetaGlobal, because it's not a state
    // that we expect consumers to know about.
    func advance() -> Deferred<Result<Ready>> {
        // Either m/g and c/k are in our local cache, and they're up-to-date with i/c,
        // or we need to fetch them.
        return chainDeferred(advanceToMG(), { $0.advance() })
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

    func advance() -> Deferred<Result<Ready>> {
        // Fetch crypto/keys, unless it's present in the cache already.
        // For now, just fetch.
        // TODO: detect when the keys have changed, and scream and run away if so.
        // TODO: upload keys if necessary, then go to Restart.
        let syncKey = Keys(defaultBundle: self.scratchpad.syncKeyBundle)
        let keysFactory: (String) -> KeysPayload? = syncKey.factory("keys", { KeysPayload($0) })
        let client = self.client.collectionClient("crypto", factory: keysFactory)
        return client.get("keys").map { result in
            if let resp = result.successValue?.value {
                let collectionKeys = Keys(payload: resp.payload)
                if (!collectionKeys.valid) {
                    return Result(failure: InvalidKeysError(collectionKeys))
                }
                let newState = Ready(client: self.client, scratchpad: self.scratchpad, token: self.token, info: self.info, keys: collectionKeys)
                return Result(success: newState)
            }
            return Result(failure: result.failureValue!)
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
func advanceSyncState(s: InitialWithLiveToken) -> Deferred<Result<Ready>> {
    return chainDeferred(s.advance(), { $0.advance() })
}

func advanceSyncState(s: HasMetaGlobal) -> Deferred<Result<Ready>> {
    return s.advance()
}