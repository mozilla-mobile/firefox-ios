# Rust Push Component

This is a companion library for the work being proposed for the Rust
Push Component. This skeleton is very much incomplete and subject to
drastic change.


The code was derived from the `mozilla-central/dom/push/` directory
and best estimates were used to determine types and structures. Note
that `unknown.rs` contains structres that could not be readily
determined. These must be resolved before meaningful work on this API
can continue.

In many instances, best guesses were made for the return types and
functions (e.g. the original code makes heavy use of Javascript
Promise objects, which have no analog in Rust. These were converted to
rust `futures`)

Note: we've been encouraged to model after the "places" component.
this means defining the final Push API elements as kotlin in the
android directory ffi descriptions. Since this could cause compile
failures, it's currently not checked in.

## System Dependencies:

 * Sqlite > 3.24
 * SqlCipher > 3.4

## API

## Initialization

Calls are handled by the `PushManager`, which provides a handle for future calls.

example:
```kotlin

import mozilla.appservices.push.(PushManager, BridgeTypes)

// The following are mock calls for fetching application level configuration options.
// "SenderID" is the native OS push message application identifier. See Native
// messaging documentation for details.
val sender_id = SystemConfigurationOptions.get("SenderID")

// The "bridge type" is the identifier for the native OS push message system.
// (e.g. FCM for Google Firebase Cloud Messaging, ADM for Amazon Direct Messaging,
// etc.)
val bridge_type = BridgeTypes.FCM

// The "registration_id" is the native OS push message user registration number.
// Native push message registration usually happens at application start, and returns
// an opaque user identifier string. See Native messaging documentation for details.
val registration_id = NativeMessagingSystem.register(sender_id)

val push_manager = PushManager(
    sender_id,
    bridge_type,
    registration_id
)

// It is strongly encouraged that the connection is verified at least once a day.
// This will ensure that the server and UA have matching information regarding
// subscriptions. This call usually returns quickly, but may take longer if the
// UA has a large number of subscriptions and things have fallen out of sync.

for change in push_manager.verify_connection() {
    // fetch the subscriber from storage using the change[0] and
    // notify them with a `pushsubscriptionchange` message containing the new
    // endpoint change[1]
}

```

## New subscription

Before messages can be delivered, a new subscription must be requested. The subscription info block contains all the information a remote subscription provider service will need to encrypt and transmit a message to this user agent.

example:
```kotlin

// Each new request must have a unique "channel" identifier. This channel helps
// later identify recipients and aid in routing. A ChannelID is a UUID4 value.
// the "scope" is the ServiceWorkerRegistration scope. This will be used
// later for push notification management.
val channelID = GUID.randomUUID()

val subscription_info = push_manager.subscribe(channelID, endpoint_scope)

// the published subscription info has the following JSON format:
// {"endpoint": subscription_info.endpoint,
//  "keys": {
//      "auth": subscription_info.keys.auth,
//      "p256dh": subscription_info.keys.p256dh
//  }}
```

## End a subscription

A user may decide to no longer receive a given subscription. To remove a given subscription, pass the associated channelID

```kotlin
push_manager.unsubscribe(channelID)  // Terminate a single subscription
```

If the user wishes to terminate all subscriptions, send and empty string for channelID

```kotlin
push_manager.unsubscribe("")        // Terminate all subscriptions for a user
```

If this function returns `false` the subsequent `verify_connection` may result in new channel endpoints.

## Decrypt an incoming subscription message

An incoming subscription body will contain a number of metadata elements along with the body of the message. Due to platform differences, how that metadata is provided may vary, however the most common form is that the messages "payload" looks like.

```javascript
{"chid": "...",         // ChannelID
 "con": "...",          // Encoding form
 "enc": "...",          // Optional encryption header
 "crypto-key": "...",   // Optional crypto key header
 "body": "...",         // Encrypted message body
}
```
These fields may be included as a sub-hash, or may be intermingled with other data fields. If you have doubts or concerns, please contact the Application Services team for guidance.

Based on the above payload, an example call might look like:

```kotlin
    val result = manager.decrypt(
        channelID = payload["chid"].toString(),
        body = payload["body"].toString(),
        encoding = payload["con"].toString(),
        salt = payload.getOrElse("enc", "").toString(),
        dh = payload.getOrElse("dh", "").toString()
    )
    // result returns a byte array. You may need to convert to a string
    return result.toString(Charset.forName("UTF-8"))
```
