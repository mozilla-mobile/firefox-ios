---
title: Account recovery keys in Firefox Accounts
author: Vijay Budhram
authorURL: https://github.com/vbudhram
---

## Account recovery keys in Firefox Account

The Firefox Accounts (FxA) team is in the process of releasing a
new feature called Account Recovery. This feature is aimed at
solving one of the most frustrating issues for our users. When
a user resets their account password, they risk losing data such
as synced bookmarks, passwords and browsing history. FxA encrypts
synced browser data with the user’s account password in order to
protect their privacy. Resetting the password destroys the
encryption key and leaves the data inaccessible which
eventually is deleted.

<!--truncate-->

There are some password reset scenarios that will not lose user
data. For example, if the user has an existing Firefox profile
with a local copy of their data, then it will eventually re-encrypt
and re-upload the data using the new encryption key. But if they
do not (common after a computer format/upgrade) then the previously-synced
data will be lost.

To help solve this problem, we developed a new feature where a
user can create a key that can be used during a password reset.
This key is called “Recovery key” and can be used to restore your
account and it’s encryption keys.

![](/application-services/img/blog/2018-09-10/setup-recovery-key.gif)

The exact process of retrieving and restoring a user’s encryption
keys are outlined in sections below. We were able to do this and not
sacrifice any security properties of the user.

![](/application-services/img/blog/2018-09-10/consume-recovery-key.gif)

If you are interested in giving this feature a try, check out the
instructions [here](https://support.mozilla.org/en-US/kb/reset-your-firefox-account-password-recovery-keys).
Also, if you find any bugs or issues please create
an issue [here](https://github.com/mozilla/fxa-content-server/issues).

### Background

The encryption keys used in the FxA ecosystem all chain back to
a single "master key" that we call kB.  This key is managed by the
Firefox Accounts server and encrypted with the user’s account
password using the [onepw protocol](https://github.com/mozilla/fxa-auth-server/wiki/onepw-protocol). If the user forgets their
password, there is no way for us to recover kB, and all their
encrypted data will be lost.

After performing user testing and gathering feedback for a
couple of designs, we decided to implement a system that stores
a user’s kB in an encrypted bundle on our servers. The recovery
key is part of the encryption key that allows the user to decrypt
the bundle that is stored. It is generated on the user’s web
client and will only be shown once. FxA never sends the recovery
key and it is expected that the user prints or stores this key
in a safe location.

During a password reset, the recovery key is hashed into a recovery
key ID. This ID can be used to retrieve the encrypted bundle and
decrypt it to get the original kB. Finally, when the password is
reset, the original kB and new password are used to  generate
the updated encryption keys.

The security requirements for the feature:

1. The recovery key must be short enough that it can be reliably stored and retrieved by the user without corruption on a printout.
2. The recovery key must be long enough that brute-force guessing a token is infeasible (online or offline)
3. The combination of the recovery key plus some information held by the FxA server must be sufficient to recover kB.
4. It must be infeasible to recover kB from the recovery key alone, without retrieving additional data from the Firefox Account server. (This is a safeguard against leakage of the token from wherever the user stores it).
5. It must be infeasible to recover kB from data held by the Firefox Account server alone, without also possessing the recovery key.  (This is a safeguard against Mozilla, and leaks of our server-side database state).
6. It must be possible for the holder of the recovery key to convince the Firefox Account server that they hold a valid key, without revealing the key itself. (This is a safeguard against Mozilla, and leaks of our server-side database state.)

### Deriving keys and JSON Web Key

A core component to account recovery is how we generate the
different kinds of keys used during encryption. Below is a
summary of those keys and how they are created.

* Recovery Key (recoveryKey)
  * 28-character [Crockford Base32](https://en.wikipedia.org/wiki/Base32) that is generated client-side and shown to the user only once
* Recovery Key ID (recoveryKeyId)
  * recoveryKeyId = HKDF(recoveryKey, salt=uid, info=“fxa recovery fingerprint”, length=16)
  * Opaque key generated from the recovery key and sent to our servers
* Encryption Key (encryptionKey)
  * encryptionKey = HKDF(recoveryKey, salt=uid, info=“fxa recovery encrypt key”, length=32)
  * Key used to encrypt kB
* Unique user ID (uid)
  * User’s unique account identifier

Our servers will ever only know and interact with the recovery
key ID. By doing this, FxA safeguards itself from ever knowing
the raw recovery key and therefore would not be able to derive
kB to decrypt any data. Even if there was a database breach,
an attacker would still not know the original recovery key.

Using the values above, a JSON Web Key [(JWK)](https://tools.ietf.org/html/rfc7517) is created with the following properties.

```javascript
{
“alg”: “A256GCM”,
“k”: encryptionKey,
“kid”: recoveryKeyId,
“kty”: “oct”
}
```

With this JWK, we can encrypt kB and store it for later use.
For more details about this encryption check out this [article](https://openid.net/specs/draft-jones-json-web-encryption-02.html).

### Registering a recovery key

1. From Firefox Account settings, a user visits the new "Account Recovery" section and clicks `Generate`
2. User is prompted to enter their password and retrieves their kB
3. Client-side web content generates a 28-character Crockford Base32 string for recovery key
* This is the string that is shown to the user and what they must store
4. Client transforms the recovery key into a JSON Web Key (JWK)
  * The recovery key ID is created as part of this process
5. Client encrypts the user’s kB using the JWK
6. Client submits recovery data and associates it with the user’s recovery key ID

Below is a diagram that illustrates where the above steps happen:

![](/application-services/img/blog/2018-09-10/setup-recovery-key-diagram.png)

### Consuming the recovery key

1. From login page, the user initiates password reset and clicks `reset password` from email received
  * After clicking the link in the email, a temporary session token is created for subsequent requests
2. User retrieves recovery key from where they saved it. For example, a printout
3. User enters their recovery key into password reset form
4. Client generates JWK from recovery key
5. Client requests for recovery data using the recovery key id
6. Client decrypts the recovery data using the derived encryption key (from Step 4) to obtain the kB
7. From client, user enters new password
8. Client wraps new password and kB and submits password reset form
9. Server updates password and removes the recovery data

The diagram below illustrates this process.

![](/application-services/img/blog/2018-09-10/consume-recovery-key-diagram.png)

Finally, big thanks and kudos to our security team, designers, developers,
testers and everyone else that helped to make this feature happen!
