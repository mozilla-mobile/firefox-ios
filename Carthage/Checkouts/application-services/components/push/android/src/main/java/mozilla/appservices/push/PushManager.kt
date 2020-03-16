/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.push

import com.sun.jna.Pointer
import java.util.concurrent.atomic.AtomicLong
import org.json.JSONArray
import java.util.Locale

/**
 * An implementation of a [PushAPI] backed by a Rust Push library.
 *
 * @param serverHost the host name for the service (e.g. "updates.push.services.mozilla.com").
 * @param httpProtocol the optional socket protocol (default: "https")
 * @param bridgeType the optional bridge protocol (default: "fcm")
 * @param registrationId the native OS messaging registration id
 */
class PushManager(
    senderId: String,
    serverHost: String = "updates.push.services.mozilla.com",
    httpProtocol: String = "https",
    bridgeType: BridgeType,
    registrationId: String,
    databasePath: String = "push.sqlite"
) : PushAPI {

    private var handle: AtomicLong = AtomicLong(0)

    init {
        try {
            handle.set(rustCall { error ->
                LibPushFFI.INSTANCE.push_connection_new(
                        serverHost,
                        httpProtocol,
                        bridgeType.toString(),
                        registrationId,
                        senderId,
                        databasePath,
                        error)
            })
        } catch (e: InternalPanic) {
            // Do local error handling?

            throw e
        }
    }

    @Synchronized
    override fun close() {
        val handle = this.handle.getAndSet(0L)
        if (handle != 0L) {
            rustCall { error ->
        LibPushFFI.INSTANCE.push_connection_destroy(handle, error)
            }
        }
    }

    override fun subscribe(
        channelID: String,
        scope: String,
        appServerKey: String?
    ): SubscriptionResponse {
        val respBuffer = rustCall { error ->
            LibPushFFI.INSTANCE.push_subscribe(
                this.handle.get(), channelID, scope, appServerKey, error)
        }
        try {
            val response = MsgTypes.SubscriptionResponse.parseFrom(respBuffer.asCodedInputStream()!!)
            return SubscriptionResponse.fromMessage(response)
        } finally {
            LibPushFFI.INSTANCE.push_destroy_buffer(respBuffer)
        }
    }

    override fun unsubscribe(channelID: String): Boolean {
        if (channelID == "") {
            return false
        }
        return rustCall { error ->
            LibPushFFI.INSTANCE.push_unsubscribe(
                this.handle.get(), channelID, error)
        }.toInt() == 1
    }

    override fun unsubscribeAll(): Boolean {
        return rustCall { error ->
            LibPushFFI.INSTANCE.push_unsubscribe_all(
                this.handle.get(), error)
        }.toInt() == 1
    }

    override fun update(registrationToken: String): Boolean {
        return rustCall { error ->
            LibPushFFI.INSTANCE.push_update(
                this.handle.get(), registrationToken, error)
        }.toInt() == 1
    }

    override fun verifyConnection(): List<PushSubscriptionChanged> {
        val respBuffer = rustCall { error ->
            LibPushFFI.INSTANCE.push_verify_connection(
                this.handle.get(), error)
        }

        try {
            val response = MsgTypes.PushSubscriptionsChanged.parseFrom(respBuffer.asCodedInputStream()!!)
            return PushSubscriptionChanged.fromCollectionMessage(response)
        } finally {
            LibPushFFI.INSTANCE.push_destroy_buffer(respBuffer)
        }
    }

    override fun decrypt(
        channelID: String,
        body: String,
        encoding: String,
        salt: String,
        dh: String
    ): ByteArray {
        val result = rustCallForString { error ->
        LibPushFFI.INSTANCE.push_decrypt(
            this.handle.get(), channelID, body, encoding, salt, dh, error
        ) }
        val jarray = JSONArray(result)
        val retarray = ByteArray(jarray.length())
        // `for` is inclusive.
        val end = jarray.length() - 1
        for (i in 0..end) {
            retarray[i] = jarray.getInt(i).toByte()
        }
        return retarray
    }

    override fun dispatchInfoForChid(channelID: String): DispatchInfo? {
        val infoBuffer = rustCall { error ->
            LibPushFFI.INSTANCE.push_dispatch_info_for_chid(
                this.handle.get(), channelID, error)
        }
        try {
            return infoBuffer.asCodedInputStream()?.let { stream ->
                DispatchInfo.fromMessage(MsgTypes.DispatchInfo.parseFrom(stream))
            }
        } finally {
            LibPushFFI.INSTANCE.push_destroy_buffer(infoBuffer)
        }
    }

    private inline fun <U> rustCall(callback: (RustError.ByReference) -> U): U {
        synchronized(this) {
            val e = RustError.ByReference()
            val ret: U = callback(e)
            if (e.isFailure()) {
                throw e.intoException()
            } else {
                return ret
            }
        }
    }

    @Suppress("TooGenericExceptionThrown")
    private inline fun rustCallForString(callback: (RustError.ByReference) -> Pointer?): String {
        val cString = rustCall(callback)
                ?: throw RuntimeException("Bug: Don't use this function when you can return" +
                        " null on success.")
        try {
            return cString.getString(0, "utf8")
        } finally {
            LibPushFFI.INSTANCE.push_destroy_string(cString)
        }
    }
}

/** The types of supported native bridges.
 *
 * FCM = Google Android Firebase Cloud Messaging
 * ADM = Amazon Device Messaging for FireTV
 * APNS = Apple Push Notification System for iOS
 *
 * Please contact services back-end for any additional bridge protocols.
 */

@Suppress("Unused")
enum class BridgeType {
    FCM, ADM, APNS, TEST;

    override fun toString() = name.toLowerCase(Locale.US)
}

/**
 * A class for providing the auth-related information needed to sync.
 * Note that this has the same shape as `SyncUnlockInfo` from logins - we
 * probably want a way of sharing these.
 */

class KeyInfo constructor (
    var auth: String,
    var p256dh: String
) {
    companion object {
        internal fun fromMessage(msg: MsgTypes.KeyInfo): KeyInfo {
            return KeyInfo(
                auth = msg.auth,
                p256dh = msg.p256Dh
            )
        }
    }
}

class SubscriptionInfo constructor (
    val endpoint: String,
    val keys: KeyInfo
) {

    companion object {
        internal fun fromMessage(msg: MsgTypes.SubscriptionInfo): SubscriptionInfo {
            return SubscriptionInfo(
                    endpoint = msg.endpoint,
                    keys = KeyInfo.fromMessage(msg.keys)
            )
        }
    }
}

class SubscriptionResponse constructor (
    val channelID: String,
    val subscriptionInfo: SubscriptionInfo
) {
    companion object {
        internal fun fromMessage(msg: MsgTypes.SubscriptionResponse): SubscriptionResponse {
            return SubscriptionResponse(
                channelID = msg.channelID,
                subscriptionInfo = SubscriptionInfo.fromMessage(msg.subscriptionInfo)
            )
        }
    }
}

class DispatchInfo constructor (
    val uaid: String,
    val scope: String,
    val endpoint: String,
    val appServerKey: String?
) {
    companion object {
        internal fun fromMessage(msg: MsgTypes.DispatchInfo): DispatchInfo {
            return DispatchInfo(
                uaid = msg.uaid,
                scope = msg.scope,
                endpoint = msg.endpoint,
                appServerKey = if (msg.hasAppServerKey()) msg.appServerKey else null
            )
        }
    }
}

class PushSubscriptionChanged constructor (
    val channelID: String,
    val scope: String
) {
    companion object {
        internal fun fromMessage(msg: MsgTypes.PushSubscriptionChanged): PushSubscriptionChanged {
            return PushSubscriptionChanged(
                channelID = msg.channelID,
                scope = msg.scope
            )
        }

        internal fun fromCollectionMessage(msg: MsgTypes.PushSubscriptionsChanged): List<PushSubscriptionChanged> {
            return msg.subsList.map {
                fromMessage(it)
            }
        }
    }
}

/**
 * An API for interacting with Push.

    Usage:

    The push component is designed to be as light weight as possible. The "Push Manager"
    handles subscription management and message decryption.

    In general, usage would consist of calling:

    ```kotlin
    val manager = PushManager(
        senderId = "SomeSenderIDValue",
        bridgeType = BridgeType.FCM,
        registrationId = systemProvidedRegistrationValue,
        databasePath = "/path/to/database.sql"
    )
    val newEndpoints = manager.verifyConnection()
    if newEndpoints.length() > 0 {
        for (channelId in newEndpoints.keys()) {
            // send the endpoint (newEndpoint[channelId]) to the process tied to channelId
        }
    }

    // On new message:
    // A new incoming message generally has the following format:
    // {"chid": ChannelID, "body": Body, "con": Encoding, "enc": Salt, "crypto_key": DH}

    val decryptedMessage = manager.decrypt(
        channelID=message["chid"],
        body=message["body"],
        encoding=message["con"],
        salt=message.getOrElse("enc", ""),
        dh=message.getOrElse("crypto-key", "")
    )

    // On new subscription:
    val subscriptionInfo = manager.subscribe(channelID, scope)

    // channelID is a UUID4 value that can either be created before hand, or an empty string
    //           can be passed in and one will be created for you.
    // scope     is the site scope string. This will be used for rate limiting
    //
    // The subscription info matches what is usually passed on to
    // the requesting application.
    // This could be JSON encoded and returned.

    // On deleting a subscription:
    manger.unsubscribe(channelID)
    // returns true/false on server unsubscribe request. A False may cause a
    // verifyConnection() failure and new endpoints generation

    // On a new native OS registration ID change:
    manager.update(newSubscriptionID)
    // sets the new registration ID (sender ID) on the server. Returns a false if this
    // operation fails. A failure may prevent future messages from being received.

```
 */
interface PushAPI : AutoCloseable {
    /**
     * Get the Subscription Info block
     *
     * @param channelID Channel ID (UUID4) for new subscription, either pre-generated or "" and one will be created.
     * @param scope Site scope string (defaults to "" for no site scope string).
     * @param appServerKey optional VAPID public key to "lock" subscriptions (defaults to "" for no key)
     * @return a SubscriptionInfo structure
     */
    fun subscribe(
        channelID: String = "",
        scope: String = "",
        appServerKey: String? = null
    ): SubscriptionResponse

    /**
     * Unsubscribe a given channelID, ending that subscription for the user.
     *
     * @param channelID Channel ID (UUID) for subscription to remove
     * @return bool
     */
    fun unsubscribe(channelID: String): Boolean

    /**
     * Unsubscribe all channels for the user.
     *
     * @return bool
     */
    fun unsubscribeAll(): Boolean

    /**
     * Updates the Native OS push registration ID.
     * NOTE: if this returns false, the subsequent `verifyConnection()` may result in new
     * endpoint registrations.
     *
     * @param registrationToken the new Native OS push registration ID.
     * @return bool
     */
    fun update(registrationToken: String): Boolean

    /**
     * Verifies the connection state.
     *
     * @return bool indicating if connection state is valid (true) or if channels should get a
     * `pushsubscriptionchange` event (false).
     */
    fun verifyConnection(): List<PushSubscriptionChanged>

    /**
     * Decrypts a raw push message.
     *
     * This accepts the content of a Push Message (from websocket or via Native Push systems).
     * for example:
     * ```kotlin
     * val decryptedMessage = manager.decrypt(
     *  channelID=message["chid"],
     *  body=message["body"],
     *  encoding=message["con"],
     *  salt=message.getOrElse("enc", ""),
     *  dh=message.getOrElse("crypto-key", "")
     * )
     * ```
     *
     * @param channelID: the ChannelID (included in the envelope of the message)
     * @param body: The encrypted body of the message
     * @param encoding: The Content Encoding "enc" field of the message (defaults to "aes128gcm")
     * @param salt: The "salt" field (if present in the raw message, defaults to "")
     * @param dh: the "dh" field (if present in the raw message, defaults to "")
     * @return Decrypted message body.
     */
    fun decrypt(
        channelID: String,
        body: String,
        encoding: String = "aes128gcm",
        salt: String = "",
        dh: String = ""
    ): ByteArray

    /** get the dispatch info for a given subscription channel
     *
     * @param channelID subscription channelID
     * @return DispatchInfo containing the channelID and scope string.
     */
    fun dispatchInfoForChid(channelID: String): DispatchInfo?
}
