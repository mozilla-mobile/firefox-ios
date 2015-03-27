/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Account

// See docs in docs/sync.md.

// You might be wondering why this doesn't have a Sync15StorageClient like FxALoginStateMachine
// does. Well, such a client is pinned to a particular server, and this state machine must
// acknowledge that a Sync client occasionally must migrate between two servers, preserving
// some state from the last.
// The resultant 'Ready' will have a suitably initialized storage client.
public class SyncStateMachine {
    public class func toReady(authState: SyncAuthState) -> Deferred<Result<Ready>> {
        let token = authState.token(NSDate.now(), canBeExpired: true)
        return chainDeferred(token, { (token, kB) in
            let state = InitialWithLiveToken(scratchpad: Scratchpad(b: KeyBundle.fromKB(kB)), token: token)
            return state.advance()
        })
    }
}

public enum SyncStateLabel: String {
    case InitialWithExpiredToken = "initialWithExpiredToken"
    case InitialWithLiveToken = "initialWithLiveToken"
    case HasMetaGlobal = "hasMetaGlobal"
    case Restart = "restart"                                  // Go around again... once only, perhaps.
    case Ready = "ready"

    static let allValues: [SyncStateLabel] = [
        InitialWithExpiredToken,
        InitialWithLiveToken,
        HasMetaGlobal,
        Restart,
        Ready,
    ]
}

public protocol SyncState {
    var label: SyncStateLabel { get }
}

public class CouldNotFetchMetaGlobalError: ErrorType {
    public var description: String {
        return "Could not fetch meta/global."
    }
}

public class CouldNotFetchKeysError: ErrorType {
    public var description: String {
        return "Could not fetch crypto/keys."
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



public class InitialWithLiveToken: SyncState {
    public var label: SyncStateLabel { return SyncStateLabel.InitialWithLiveToken }
    let client: Sync15StorageClient!
    var scratchpad: Scratchpad

    public init(scratchpad: Scratchpad, token: TokenServerToken) {
        let workQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        let resultQueue = dispatch_get_main_queue()
        self.client = Sync15StorageClient(token: token, workQueue: workQueue, resultQueue: resultQueue)
        self.scratchpad = scratchpad
    }

    func advanceToMG() -> Deferred<Result<HasMetaGlobal>> {
        // Fetch meta/global, unless it's present in the cache already.
        // For now, just fetch.
        // TODO: detect when the global syncID has changed.
        // TODO: detect when an individual collection syncID has changed, and make sure that
        //       collection is reset.
        // TODO: detect when the sets of declined or enabled engines have changed, and update
        //       our preferences accordingly.
        return self.client.getMetaGlobal().map { result in
            if let resp = result.successValue?.value {
                let newState = HasMetaGlobal(client: self.client, scratchpad: self.scratchpad.withGlobal(resp))
                return Result<HasMetaGlobal>(success: newState)
            }

            // TODO: create, upload, go to Restart?
            // Or should we return an intermediate state to allow a graceful exit?
            // Remember to return a restarted scratchpad, too.
            return Result<HasMetaGlobal>(failure: result.failureValue!)
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

public class HasMetaGlobal: SyncState {
    public var label: SyncStateLabel { return SyncStateLabel.HasMetaGlobal }
    var client: Sync15StorageClient
    var scratchpad: Scratchpad

    init(client: Sync15StorageClient, scratchpad: Scratchpad) {
        self.client = client
        self.scratchpad = scratchpad
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
                    return Result<Ready>(failure: InvalidKeysError(collectionKeys))
                }
                let newState = Ready(client: self.client, scratchpad: self.scratchpad, keys: collectionKeys)
                return Result<Ready>(success: newState)
            }
            return Result<Ready>(failure: result.failureValue!)
        }
    }
}

public class Ready: HasMetaGlobal {
    public override var label: SyncStateLabel { return SyncStateLabel.Ready }
    let collectionKeys: Keys

    public init(client: Sync15StorageClient, scratchpad: Scratchpad, keys: Keys) {
        self.collectionKeys = keys
        super.init(client: client, scratchpad: scratchpad)
    }
}


/*
 * Because a strongly typed state machine is incompatible with protocols,
 * we use function dispatch to ape a protocol.
 */
func advanceSyncState(s: InitialWithLiveToken) -> Deferred<Result<Ready>> {
    return s.advance()
}

func advanceSyncState(s: HasMetaGlobal) -> Deferred<Result<Ready>> {
    return s.advance()
}