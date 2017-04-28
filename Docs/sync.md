# Firefox Sync Through The Lens Of Jaded Developers
## Or, Let's Use A State Machine For Our Own Sakes

(These docs are approximately one sentence per line to make changes more civilized in version control.)

Sync moves through a number of states.

Initially, we know only the Married account state: we have a valid, verified FxA. This also gives us kB.

Sync will need to know when kB changes, but it does so implicitly -- when kB changes, we fetch a new token, and the X-Client-State header we supply will result in a new storage endpoint.

We transition from this state, then, to one where we also have a Sync storage token and a node assignment. This is the point at which we can first talk to the Sync server. We call this "Initial Assigned". We start in this state when first signed in, and also when creating an account on the device.

(Note that the Sync server allows us to fetch info/collections with an expired token. This is to make the process of short-circuiting a sync cheaper. We still need a server assignment, of course. That we can do this implies that the Sync client has a pull-based relationship with the token server client.)


The process thereafter depends on some amount of locally persisted state.

This state falls into three categories:

* Real storage metadata on which our syncing behavior relies. This involves timestamps of collection fetches, syncIDs for storage as a whole and for each collection, and lists of engines. (Perhaps more.)

* Protocol-level signaling, such as Retry-After and Backoff headers. These need to persist in order for us to behave correctly.

* Cached data to avoid repeating operations. The client can cache info/collections for the duration of a sync, and meta/global and crypto/keys until they change.

For more on this, see "Persistence", below.

Starting from that "initial assigned" state, we will always fetch info/collections.

If we have local meta/global and crypto/keys caches, and nothing is indicated as changed in i/c, we can move directly to Ready.

If either is missing, each needs to be fetched and processed. These two tasks should be independent, but typically a change to meta/global will be followed by fetching keys.

If meta/global is missing, one must be created based on the user's datatype elections, ideally preserved from any previous configuration. For consistency's sake, the rest of storage should be wiped prior to uploading a meta/global; a missing meta/global implies that something is wrong, and it probably went wrong during a wipe or node reassignment.

If crypto/keys is missing, there should be no other data on the server. On a non-first-sync, this is likely to be an error state, requiring recovery. If crypto/keys changed, but the server wasn't wiped and refilled, then HMAC errors will result.

So now we have meta/global and crypto/keys, in one of three ways: cached, fetched, or computed and uploaded. If we don't get to that point, we error out; the intermediate fetching states really aren't exposed. If we had to compute and upload -- a very uncommon situation -- we re-enter the state machine from the beginning to simplify analysis.

We call this state "Ready".

From Ready we can perform a number of operations:

* We can wipe the server.

* We can safely change datatype elections or keys for collections.

* We can perform storage operations on one or more collections.

The first two we'll ignore for now. They're relatively straightforward.

The last is encapsulated in a datatype-specific synchronizer and a `Sync15CollectionClient` that pushes and pulls records.


The process of synchronizing is driven by info/collections (indicating remote changes), by meta/global (a change to syncID implies a reset), and by local change indicators.


## Invalidation

At any point we might get a 401 in response to a storage request. At this point our token is invalidated; we abort this sync, fetch a new token, and continue. That token might itself point to a new Sync server, which might result in a fresh-start sync.


## Persistence

So what do we need to persist? Quite apart from the actual datatype-specific stuff:

* We need to store the syncID and last fetch timestamp for each collection. If the syncID changes, we need to throw away the timestamp.
* We need to store the list of enabled engines, and keep it in lockstep with meta/global. The same for declined.
* We need to store our own client ID, and use that when uploading our client record.
* We need to pay attention to kB; if it changes, e.g., via a password change, then any in-memory copy of the Sync Key should be discarded.
* We ought to cache meta/global.
* We ought to cache bulk keys. If i/c changes for crypto, we should redownload and compare. If any collection key changes, then we should act as if the syncID changed. (TODO: should we change the syncID for that collection? Probably.)
  (If we can't decrypt your bulk keys, probably our kB is now invalid. If it's not, the server is corrupt.)
* We ought to remember the last info/collections.
* We should store the last info/collections timestamp, so that an i/c fetch can return 304.
