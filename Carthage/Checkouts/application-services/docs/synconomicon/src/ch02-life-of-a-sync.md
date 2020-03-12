# Life of a sync

Each sync goes through a number of steps, implemented as a state machine. These states handle authentication, fetching encryption keys, pulling new changes from the server and local store, merging, and updating the server and store.

## 1. Authentication

### 1.1 Get an OAuth token

The first step authenticates with [Firefox Accounts](https://mozilla.github.io/application-services/docs/accounts/welcome.html) to obtain an **OAuth token** and **Sync encryption keys**. If we already have a token and keys, we can skip ahead to 1.2, and exchange it for a tokenserver token. The authentication and encryption scheme is described in [this wiki page](https://github.com/mozilla/fxa-auth-server/wiki/onepw-protocol).

*Legacy clients also support authentication with signed BrowserID assertions, but this flow is deprecated and intentionally undocumented.*

### 1.2 Exchange the OAuth token for a tokenserver token

The [tokenserver](https://mozilla-services.readthedocs.io/en/latest/token/index.html) handles **node assignment**, so we know which storage node to talk to, and **token generation**, so we can authenticate to that node.

## 2. Setup

At this point, we have our tokenserver token, and can make authenticated requests to our storage node.

### 1.1 Fetch `info/collections`

The `info/collections` endpoint returns last-modified times for all collections.

### 1.2 Fetch or upload `meta/global`

The `meta/global` record holds sync IDs, storage versions, and collections that we declined to sync.

### 1.3 Fetch or upload `crypto/keys`

The `crypto/keys` record holds collection encryption keys. This key is encrypted with kB.

## 3. Sync

Now that we know what we're syncing, and have our keys, we can download and upload records.

