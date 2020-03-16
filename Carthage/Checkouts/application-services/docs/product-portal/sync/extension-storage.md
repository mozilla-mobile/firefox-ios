---
title: Extension Storage
---

Extension Storage Sync is available through the chrome.storage.sync
WebExtension API. It syncs as part of Firefox Sync, but using a
different storage backend ([Kinto](https://wiki.mozilla.org/Firefox/Kinto)).

As much as possible, Extension Storage Sync is meant to seem like "part
of Sync" from the user's perspective. This means that Extension Storage
Sync takes a similar approach to its cryptography as the rest of Sync.

### Kinto structure

Kinto is an object store with three levels -- buckets, which contain
collections, which contain records. A given user just uses the "default"
bucket, which is mapped to a different bucket for each user. Each
extension gets its own collection. Each key/value pair that an extension
stores becomes its own record.

### Crypto

When a user does a sync, we want the user's data to be stored securely,
so we encrypt it. This encryption happens using the Kinto "remote
transformer" feature. This means that encryption happens on the client
side before sending the data, or just after receiving the data. This
also means that all data is stored unencrypted locally. Storing the data
encrypted at rest on the user's machine seems hard, because it means you
need to have access to any encryption keys or hash salts when you're
offline or not logged in, as well as reencrypt everything if those keys
change, and it doesn't seem like it provides much in the way of security
because if an attacker has access to a user's machine, they can probably
already get access to the same encryption keys that Firefox uses.

Each collection (thus, extension) gets its own key. These keys are
stored in a separate "keyring", which is itself stored as a record in a
special "crypto" collection. This record is encrypted using a key that
is derived from a user's kB. This two-tier crypto system was inherited
from Firefox Sync and it helps us to minimize data that we reupload when
a user's kB changes. Each collection also gets its own "salt" which is
used to hash IDs related to that collection.

When we sync, we map the local collection name to an "obfuscated" remote
collection name. This is done so that metadata doesn't leak information
about what extensions a user has installed. The "obfuscated" name is
computed by hashing the collection ID using the collection's salt.

### Encrypting records

In chrome.storage.sync, each datum is a key-value pair. Keys can
presumably be any string (for example, an extension might store a value
["yes", "I", "do"] under the key "I ♥ moz://a"). In Kinto, we represent
this same datum as a JSON object like {"id":
"key-I\_20\_\_2665\_\_20\_moz\_3A\_\_2F\_\_2F\_a", "key": "I ♥ moz://a",
"data": ["yes", "I", "do"], "last\_modified": 12345}. As stated above,
this record is stored "in the clear" on the client. Note that we store
the original key, as well as a Kinto-safe key that uses a reduced
character set.

When it's time to send this record to the server, it's encrypted using
an EncryptionRemoteTransformer. The record is serialized to produce a
plaintext. An IV is generated and is used in conjunction with the
extension key (above) to produce a ciphertext. An HMAC is computed over
the record ID, IV, and ciphertext. The ID and last\_modified fields are
copied over from the cleartext record so that syncing can work
correctly. The encrypted record will then look like {"id":
"key-I\_20\_\_2665\_\_20\_moz\_3A\_\_2F\_\_2F\_a", "ciphertext": "[some
gibberish]", "IV": "[some gibberish]", "hmac": "[some gibberish]",
"last\_modified": 12345}.

Additionally, the record ID is hashed to try not to leak information
about the record or the extension being used. The hashed record ID has
to be consistent across clients so that syncing works correctly, so we
hash the ID using the collection's salt. Note that in order for this to
work, we have to always be able to go from a hashed record to its
original ID. This is normally tricky because Kinto doesn't store any
data with the "tombstones" that it stores for deleted records. However,
if we store unencrypted tombstones, we would be leaking information
about records being deleted, so before sending "delete" notifications to
Kinto, we encrypt them the same way we do for normal records. (In the
kinto.js documentation, this is described as "local deletes become
remote keeps".)

When the server provides this record to a client, it decrypts it in the
usual way -- verifying the HMAC first, and then using the IV and the
extension key to decrypt the ciphertext, producing a serialized record,
which is then used as the real record.

### Password changes

Because the "keyring" is encrypted using kB, and there is a relationship
between kB and the user's password, there are a couple of wrinkles that
we need to be aware of when a user's password changes.

A user's password changes due to a "change password" event and due to a
"reset password" event. These behave differently with regard to kB.

During a "change password" event, kB doesn't change. kB is a random
value that is "wrapped" with the user's password, but since a user who
is performing a "change password" has access to the old password, they
have access to the unwrapped kB. After the password is changed, FxA
rewraps kB using the new password and uploads it. kB doesn't change, so
our crypto is fine, and we don't have to do anything.

During a "reset password" event, kB changes because the user no longer
has access to the old kB. However, the desktop client will still have
access to any data that it saved previously. Among other things, this
means the keyring. Since the version of the keyring on the server is
encrypted with the old kB, we will no longer be able to access it. We
should therefore upload the same record encrypted with the new kB every
time kB changes.

We detect kB changing by storing the current kB (as a hash) in the
keyring record itself. We "update" this keyring record with the current
kB hash on every call to sync(). kinto.js tries to track the status of
the keyring in a field called `_status` -- it should be `"synced"` when
it is the same as the version that we expect on the server, and it
should be `"updated"` if we've changed it and haven't pushed it to the
server. So after possibly updating the kB hash (or just replacing it
with what it already is), we check if the keyring is "updated" and if
so, try to upload it to the server. Because encryption happens
"just-in-time", this causes the keyring to be reuploaded but encrypted
by the new kB.

### Losing access to the keyring

All of the above allows the keyring to be preserved across password
resets, but it's possible that a user no longer has access to the device
that had the old keyring. If this happens, the old keyring and any data
encrypted using it is completely lost -- that's the point of encrypting
it with kB, after all -- and we need a way to recover. When we try to
sync our keyring, if we find that we can't decrypt the server version,
we check if it was encrypted using a different kB. If it was, then we no
longer have access to the keyring, so we delete the entire Kinto
collection corresponding to our data and generate a new keyring.

We identify the kB used to encrypt a keyring by storing a hash of that
kB on the keyring itself.

It's possible that another device still had access to the old keyring
when it was thrown away. It got thrown away due to a password reset, so
when it gets the new password (and the new kB), it will try to resync
its keyring. When it does, it will see that the keyring was newly
generated. From this it will know that the Kinto server was wiped, and
it will reset its sync status for all data, and thereby try to reupload
everything.

We detect the "generation" of a keyring by storing a `uuid` field on the
keyring. This is preserved across all keyring operations, but generating
a new keyring generates a new uuid. Thus, if you sync your keyring and
discover that the new version you got has a new uuid, you know you need
to reset your sync status.

### Edge Cases

-   **Can keys in the keyring ever change?** Yes, during a password
    reset, the keyring can be thrown away, with all its keys replaced.
    However, in normal operation, keys are permanent.

-   **What happens if I uninstall and reinstall an add-on?** Keys are
    not discarded on uninstalling an add-on, so the old data will still
    be available to that extension, encrypted in the same way on the
    server.

-   **What happens if a user simultaneously installs an add-on (and uses
    it) in two Firefoxes?** Until one Firefox syncs the data for that
    add-on, no data is encrypted, so there can be no conflict in the
    keyring. Each Firefox will try to update its keyring to have a new
    key for this collection. One will "win"; the other will get a
    conflict, and pull down the new keyring (because syncing is done
    using "server\_wins"). No Firefox will try to upload data for any
    add-on for which it doesn't have a key in a synced keyring, and two
    keyring syncs can't be interleaved, so it's impossible for data to
    be encrypted on the server with two keys.

-   **What happens if a user uploads some data on one device and then
    resets the password on another?** Assuming the second device had the
    old keyring, it will re-encrypt the keyring with the new kB and sync
    it. Because the other device didn't upload a new version of the
    keyring, the sync will succeed and no data will have to be
    reuploaded. The first device won't be able to sync until it gets the
    new password (and the new kB), but once it does, it will try to
    resync the keyring and accept whatever keyring is on the server.

-   **What happens if a user adds a new extension and syncs some data on
    one device and then resets the password on another?** Because the
    first device uploaded a new keyring, the second device will try to
    sync the keyring and fail. Because the kB is different on the two
    keyrings, it will assume that the old keyring is lost and wipe the
    Kinto server. When the first device reconnects, it will find that
    the keyring got replaced and reupload all its data.

-   **What happens if a user resets their password on one device in the
    middle of an upload?** We only consider a user's password state at
    the beginning of a sync. If we get as far as uploading extension
    data, then the keys for those extensions exist on the server,
    encrypted with the old kB. This is fine because next sync, we will
    discover that the keyring was encrypted with the old kB, update the
    kB on that keyring, and reupload it.

-   **What happens if a user resets their password on one device when
    another is uploading?** If the device that gets reset had access to
    the old keyring, it will reupload it. In this case, the keys for
    each extension don't change, so syncing of extension data will
    continue to work. If the device that gets reset didn't have access
    to the old keyring, it will wipe the entire server and start
    uploading from zero. However, it seems like it might be possible for
    the wipe to happen while the other device is in the middle of
    reuploading, in which case the other device could upload data
    encrypted with a key that just got deleted. In this case, the "new"
    device might try to sync this data and fail to decrypt it and throw
    forever. \*I'm not sure how to handle this case.\*

