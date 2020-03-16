# Sync manager

We've identified the need for a "sync manager" (although are yet to identify a
good name for it!) This manager will be responsible for managing "global sync
state" and coordinating each engine.

At a very high level, the sync manager is responsible for all syncing. So far,
so obvious. However, given our architecture, it's possible to identify a
key architectural split.

* The embedding application will be responsible for most high-level operations.
  For example, the app itself will choose how often regular syncs should
  happen, what environmental concerns apply (eg, should I only sync on WiFi?),
  letting the user choose exactly what to sync, and so forth.

* A lower-level component will be responsible for the direct interaction with
  the engines and with the various servers needed to perform a sync. It will
  also have the ultimate responsibility to not cause harm to the service (for
  example, it will be likely to enforce some kind of rate limiting or ensuring
  that service requests for backoff are enforced)

Because all application-services engines are written in Rust, it's tempting to
suggest that this lower-level component also be written in Rust and everything
"just works", but there are a couple of complications here:

* For iOS, we hope to integrate with older engines which aren't written in
  Rust, even if iOS does move to the new Sync Manager.

* For Desktop, we hope to start by reusing the existing "sync manager"
  implemented by Desktop, and start moving individual engines across.

* There may be some cross-crate issues even for the Rust implemented engines.
  Or more specifically, we'd like to avoid assuming any particular linkage or
  packaging of Rust implemented engines.

Even with these complications, we expect there to be a number of high-level
components, each written in a platform specific language (eg, Kotlin or Swift)
and a single lower-level component to be implemented in Rust and delivered
as part of the application-services library - but that's not a free-pass.

Why "a number of high-level components"? Because that is the thing which
understands the requirements of the embedding application. For example, Android
may end up with a single high-level component in the android-components repo
and shared between all Android components. Alternatively, the Android teams
may decide the sync manager isn't generic enough to share, so each app will
have their own. iOS will probably end up with its own and you could imagine
a future where Desktop does too - but they should all be able to share the
low level component.

# The responsibilities of the Sync Manager.

The primary responsibilities of the "high level" portion of the sync manager are:

* Manage all FxA interaction. The low-level component will have a way to
  communicate auth related problems, but it is the high-level component
  which takes concrete FxA action.

* Expose all UI for the user to choose what to sync and coordinate this with
  the low-level component. Note that because these choices can be made on any
  connected device, these choices must be communicated in both directions.

* Implement timers or any other mechanism to fully implement the "sync
  scheduler", including any policy decisions such as only syncing on WiFi,
  etc.

* Implement a UI so the user can "sync now".

* Collect telemetry from the low-level component, probably augment it, then
  submit it to the telemetry pipeline.

The primary responsibilities of the "low level" portion of the sync manager are:

* Manage the `meta/global`, `crypto/keys` and `info/collections` resources,
  and interact with each engine as necessary based on the content of these
  resources.

* Manage interaction with the token server.

* Enforce constraints necessary to ensure the entire ecosystem is not
  subject to undue load. For example, this component should ignore attempts to
  sync continuously, or to sync when the services have requested backoff.

* Manage the "clients" collection - we probably can't ignore this any longer,
  especially for bookmarks (as desktop will send a wipe command on bookmark
  restore, and things will "be bad" if we don't see that command).

* Define a minimal "service state" so certain things can be coordinated with
  the high-level component. Examples of these states are "everything seems ok",
  "the service requested we backoff for some period", "an authentication error
  occurred", and possibly others.

* Perform, or coordinate, the actual sync of the rust implemented engines -
  from the containing app's POV, there's a single "sync now" entry-point (in
  practice there might be a couple, but conceptually there's a single way to
  sync). Note that as below, how non-rust implemented engines are managed is
  TBD.

* Manage the collection of (but *not* the submission of) telemetry from the
  various engines.

* Expose APIs and otherwise coordinate with the high-level component.

Stuff we aren't quite sure where it fits include:

* Coordination with non-rust implemented engines. These engines are almost
  certainly going to be implemented in the same language as the high-level
  component, which will make integration simpler. However, the low-level
  component will almost certainly need some information about these engines for
  populating info/collections etc. For now, we are punting on this until things
  become a bit clearer.

# Implementation Details.

The above has been carefully written to try and avoid implementation details -
the intent is that it's an overview of the architecture without any specific
implementation decisions.

These next sections start getting specific, so implementation choices need to
be made, and thus will possibly be more contentious.

In other words, get your spray-cans ready because there's a bikeshed being built!

However, let's start small and make some general observations.

## Current implementations and challenges with the Rust components

* Some apps only care about a subset of the engines - lockbox is one such app
  and only cares about a single collection/engine. It might be the case that
  lockbox uses a generic application-services library with many engines
  available, even though it only wants logins. Thus, the embedding application
  is the only thing which knows which engines should be considered to "exist".
  It may be that the app layer passes an engine to the sync manager, or the
  sync manager knows via some magic how to obtain these handles.

* Some apps will use a combination of Rust components and "legacy"
  engines. For example, iOS is moving some of the engines to using Rust
  components, while other engines will be ported after delivery of the
  sync manager, if they are ported at all. We also plan
  to introduce some rust engines into desktop without integrating the
  "sync manager"

* The rust components themselves are designed to be consumed as individual
  components - the "logins" component doesn't know anything about the
  "bookmarks" component.

There are a couple of gotchyas in the current implementations too - there's an
issue when certain engines don't yet appear in meta/global - see bug 1479929
for all the details.

The tl;dr of the above is that each rust component should be capable of
working with different sync managers. That said though, let's not over-engineer
this and pretend we can design a single, canonical thing that will not need
changing as we consider desktop and iOS.

## State, state and more state. And then some state.

There's loads of state here. The app itself has some state. The high-level
Sync Manager component will have state, the low-level component will have state,
and each engine has state. Some of this state will need to be persisted (either
on the device or on the storage servers) and some of this state can be considered
ephemeral and lives only as long as the app.

A key challenge will be defining this state in a coherent way with clear
boundaries between them, in an effort to allow decoupling of the various bits
so Desktop and iOS can fit into this world.

This state management should also provide the correct degree of isolation for
the various components. For example, each engine should only know about state
which directly impacts how it works. For example, the keys used to encrypt
a collection should only be exposed to that specific engine, and there's no
need for one engine to know what info/collections returns for other engines,
nor whether the device is currently connected to WiFi.

A thorn here is for persisted state - it would be ideal if the low-level
component could avoid needing to persist any state, so it can avoid any
kind of storage abstraction. We have a couple of ways of managing this:

* The state which needs to be persisted is quite small, so we could delegate
  state storage to the high-level component in an opaque way, as this
  high-level component almost certainly already has storage requirements, such
  as storing the "choose what to sync" preferences.

* The low-level component could add its own storage abstraction. This would
  isolate the high-level component from this storage requirement, but would
  add complexity to the sync manager - for example, it would need to be passed
  a directory where it should create a file or database.

We'll probably go with the former.

# Implementation plan for the low-level component.

Let's try and move into actionable decisions for the implementation. We expect
the implementation of the low-level component to happen first, followed very
closely by the implementation of the high-level component for Android. So we
focus first on these.

## Clients Engine

The clients engine includes some meta-data about each client. We've decided
we can't replace the clients engine with the FxA device record and we can't
simply drop this engine entirely.

Of particular interest is "commands" - these involve communicating with the
engine regarding commands targetting it, and accepting commands to be send to
other devices. Note that outgoing commands are likely to not originate from a sync,
but instead from other actions, such as "restore bookmarks".

However, because the only current requirement for commands is to wipe the
store, and because you could anticipate "wipe" also being used when remotely
disconnecting a device (eg, when a device is lost or stolen), our lives would
probably be made much simpler by initially supporting only per-engine wipe
commands.

Note that there has been some discussion about not implementing the client
engine and replacing "commands" with some other mechanism. However, we have
decided to not do that because the implementation isn't considered too
difficult, and because desktop will probably require a number of changes to
remove it (eg, "synced tabs" will not work correctly without a client record
with the same guid as the clients engine.)

Note however that unlike desktop, we will use the FxA device ID as the client
ID. Because FxA device IDs are more ephemeral than sync IDs, it will be
necessary for engines using this ID to track the most-recent ID they synced
with so the old record can be deleted when a change is detected.

## Collections vs engines vs stores vs preferences vs Apis

For the purposes of the sync manager, we define:

* An *engine* is the unit exposed to the user - an "engine" can be enabled
  or disabled. There is a single set of canonical "engines" used across the
  entire sync ecosystem - ie, desktop and mobile devices all need to agree
  about what engines exist and what the identifier for an engine is.

* An *Api* is the unit exposed to the application layer for general application
  functionality. Application services has 'places' and 'logins' Apis and is
  the API used by the application to store and fetch items. Each 'Api' may
  have one or more 'stores' (although the application layer will generally not
  interact directly with a store)

* A *store* is the code which actually syncs. This is largely an implementation
  detail. There may be multiple stores per engine (eg, the "history" engine
  may have "history" and "forms" stores) and a single 'Api' may expose multiple
  stores (eg, the "places Api" will expose history and bookmarks stores)

* A *collection* is a unit of storage on a server. It's even more of an
  implementation detail than a store. For example, you might imagine a future
  where the "history" store uses multiple "collections" to help with containers.

In practice, this means that the high-level component should only need to care
about an *engine* (for exposing a choice of what to sync to the user) and an
*api* (for interacting with the data managed by that api). The low-level
component will manage the mapping of engines to stores.

## The declined list

This document isn't going to outline the history of how "declined" is used, nor
talk about how this might change in the future. For the purposes of the sync
manager, we have the following hard requirements:

* The low-level component needs to know what the currently declined set of
  engines is for the purposes of re-populating `meta/global`.

* The low-level component needs to know when the declined set needs to change
  based on user input (ie, when the user opts in to or out of a particular
  engine on this device)

* The high-level component needs to be aware that the set of declined engines
  may change on every sync (ie, when the user opts in to or out of a particular
  engine on another device)

A complication is that due to networks being unreliable, there's an inherent
conflict between "what is the current state?" and "what state changes are
requested?". For example, if the user changes the state of an engine while
there's no network, then exits the app, how do we ensure the user's new state
is updated next time the app starts? What if the user has since made a
different state request on a different device? Is the state as last-known on
this device considered canonical?

To clarify, consider:

* User on this device declines logins. This device now believes logins is
  disabled but history is enabled, but is unable to write this to the server
  due to no network.

* The user declines history on a different device, but doesn't change logins.
  This device does manage to write the new list to the server.

* This device restarts and the network is up. It believes history is enabled
  but logins is not - however, the state on the server is the exact opposite.

How does this device react?

(On the plus side, this is an extreme edge-case which none of our existing
implementations handle "correctly" - which is easy to say, because there's
no real definition for "correctly")

Regardless, the low-level component will not pretend to hide this complexity
(ie, it will ignore it!). The low-level component will allow the app to ask
for state changes as part of a sync, and will return what's on the server at
the end of every sync. The app is then free to build whatever experience
it desires around this.

## Disconnecting from Sync

The low-level component needs to have the ability to disconnect all engines
from Sync. Engines which are declined should also be reset.

Because we will need wipe() functionality to implement the clients engine,
and because Lockbox wants to wipe on disconnect, we will provide disconnect
and wipe functionality.

# Specific deliverables for the low-level component.

Breaking the above down into actionable tasks which can be some somewhat
concurrently, we will deliver:

## The API

A straw-man for the API we will expose to the high-level components. This
probably isn't too big, but we should do this as thoroughly as we can. In
particular, ensure we have covered:

* Declined management - how the app changes the declined list and how it learns
  of changes from other devices.

* How telemetry gets handed from the low-level to the high-level.

* The "state" - in particular, how the high-level component understands the
  auth state is wrong, and whether the service is in a degraded mode (eg,
  server requested backoff)

* How the high-level component might specify "special" syncs, such as "just
  one engine" or "this is a pre-sleep, quick-as-possible sync", etc

There's a straw-man proposal for this at the end of the document.

## A command-line (and possibly Android) utility.

We should build a utility (or 2) which can stand in for the high-level
component, for testing and demonstration purposes.

This is something like places-utils.rs and the little utility Grisha has
been using. This utility should act like a real client (ie, it should have
an FxA device record, etc) and it should use the low-level component in
exactly the same we we expect real products to use it.

Because it is just a consumer of the low-level component, it will force us to
confront some key issues, such as how to get references to engines stored in
multiple crates, how to present a unified "state" for things like auth errors,
etc.

## The "clients" engine

The initial work for the clients engine can probably be done without too
much regard for how things are tied together - for example, much work could
be done without caring how we get a reference to engines across crates.

## State work

Implementing things needed to we can expose the correct state to the high-level
manager for things like auth errors, backoff semantics, etc

## Tie it together and other misc things.

There will be lots of loose ends to clean up - things like telemetry, etc.

# Followup with non-rust engines.

We have identified that iOS will, at least in the short term, want the
sync manager to be implemented in Swift. This will be responsible for
syncing both the Swift and Rust implemented engines.

At some point in the future, Desktop may do the same - we will have both
Rust and JS implemented engines which need to be coordinated. We ignore this
requirement for now.

This approach still has a fairly easy time coordinating with the Rust
implemented engines - the FFI will need to expose the relevant sync
entry-points to be called by Swift, but the Swift code can hard-code the
Rust engines it has and make explicit calls to these entry-points.

This Swift code will need to create the structures identified below, but this
shouldn't be too much of a burden as it already has the information necessary
to do so (ie, it already has info/collections etc)

TODO: dig into the Swift code and make sure this is sane.

# Details

While we use rust struct definitions here, it's important to keep in mind that
as mentioned above, we'll need to support the manager being written in
something other than rust, and to support engines written in other than rust.

The structures below are a straw-man, but hopefully capture all the information
that needs to be passed around.

```rust

// We want to define a list of "engine IDs" - ie, canonical strings which
// refer to what the user perceives as an "enigine" - but as above, these
// *do not* correspond 1:1 with either "stores" or "collections" (eg, "history"
// refers to 2 stores, and in a future world, might involve 3 collections).
enum Engine {
  History, // The "History" and "Forms" stores.
  Bookmarks, // The "Bookmark" store.
  Passwords,
}

impl Engine {
  fn as_str(&self) -> &'static str {
    match self {
      History => "history",
      // etc
  }
}

// A struct which reflects engine declined states.
struct EngineState {
  engine: Engine,
  enabled: bool,
}

// A straw-man for the reasons why a sync is happening.
enum SyncReason {
  Scheduled,
  User,
  PreSleep,
  Startup,
}

// A straw man for the general status.
enum ServiceStatus {
  Ok,
  // Some general network issue.
  NetworkError,
  // Some apparent issue with the servers.
  ServiceError,
  // Some external FxA action needs to be taken.
  AuthenticationError,
  // We declined to do anything for backoff or rate-limiting reasons.
  BackedOff,
  // Something else - you need to check the logs for more details.
  OtherError,
}

// Info we need from FxA to sync. This is roughly our Sync15StorageClientInit
// structure with the FxA device ID.
struct AccountInfo {
  key_id: String,
  access_token: String,
  tokenserver_url: Url,
  device_id: String,
}

// Instead of massive param and result lists, we use structures.
// This structure is passed to each and every sync.
struct SyncParams {
  // The engines to Sync. None means "sync all"
  engines: Option<Vec<Engine>>,
  // Why this sync is being done.
  reason: SyncReason,

  // Any state changes which should be done as part of this sync.
  engine_state_changes: Vec<EngineState>,

  // An opaque state "blob". This should be persisted by the app so it is
  // reused next sync.
  persisted_state: Option<String>,
}

struct SyncResult {
  // The general health.
  service_status: ServiceStatus,

  // The result for each engine.
  engine_results: HashMap<Engine, Result<()>>,

  // The list of declined engines, or None if we failed to get that far.
  declined_engines: Option<Vec<Engine>>,

  // When we are allowed to sync again. If > now() then there's some kind
  // of back-off. Note that it's not strictly necessary for the app to
  // enforce this (ie, it can keep asking us to sync, but we might decline).
  // But we might not too - eg, we might try a user-initiated sync.
  next_sync_allowed_at: Timestamp,

  // New opaque state which should be persisted by the embedding app and supplied
  // the next time Sync is called.
  persisted_state: String,

  // Telemetry. Nailing this down is tbd.
  telemetry: Option<JSONValue>,
}

struct SyncManager {}

impl SyncManager {
  // Initialize the sync manager with the set of Engines known by this
  // application without regard to the enabled/declined states.
  // XXX - still TBD is how we will pass "stores" around - it may be that
  // this function ends up taking an `impl Store`
  fn init(&self, engines: Vec<&str>) -> Result<()>;

  fn sync(&self, params: SyncParams) -> Result<SyncResult>;

  // Interrupt any current syncs. Note that this can be called from a different
  // thread.
  fn interrupt() -> Result<()>;

  // Disconnect this device from sync. This may "reset" the stores, but will
  // not wipe local data.
  fn disconnect(&self) -> Result<()>;

  // Wipe all local data for all local stores. This can be done after
  // disconnecting.
  // There's no exposed way to wipe the remote store - while it's possible
  // stores will want to do this, there's no need to expose this to the user.
  fn wipe(&self) -> Result<()>;
}
```
