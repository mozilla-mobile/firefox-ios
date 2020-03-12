/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.fxaclient

import android.util.Log
import com.sun.jna.Native
import com.sun.jna.Pointer
import mozilla.appservices.fxaclient.rust.FxaHandle
import mozilla.appservices.fxaclient.rust.LibFxAFFI
import mozilla.appservices.fxaclient.rust.RustError
import mozilla.appservices.support.native.toNioDirectBuffer
import java.util.concurrent.atomic.AtomicLong
import org.json.JSONObject

/**
 * FirefoxAccount represents the authentication state of a client.
 */
class FirefoxAccount(handle: FxaHandle, persistCallback: PersistCallback?) : AutoCloseable {
    private var handle: AtomicLong = AtomicLong(handle)
    private var persistCallback: PersistCallback? = persistCallback

    /**
     * Create a FirefoxAccount using the given config.
     *
     * This does not make network requests, and can be used on the main thread.
     */
    constructor(config: Config, persistCallback: PersistCallback? = null) :
    this(rustCall { e ->
        LibFxAFFI.INSTANCE.fxa_new(config.contentUrl, config.clientId, config.redirectUri, e)
    }, persistCallback) {
        // Persist the newly created instance state.
        this.tryPersistState()
    }

    companion object {
        /**
         * Restores the account's authentication state from a JSON string produced by
         * [FirefoxAccount.toJSONString].
         *
         * This does not make network requests, and can be used on the main thread.
         *
         * @return [FirefoxAccount] representing the authentication state
         */
        fun fromJSONString(json: String, persistCallback: PersistCallback? = null): FirefoxAccount {
            return FirefoxAccount(rustCall { e ->
                LibFxAFFI.INSTANCE.fxa_from_json(json, e)
            }, persistCallback)
        }
    }

    interface PersistCallback {
        fun persist(data: String)
    }

    /**
     * Registers a PersistCallback that will be called every time the
     * FirefoxAccount internal state has mutated.
     * The FirefoxAccount instance can be later restored using the
     * `fromJSONString` class method.
     * It is the responsibility of the consumer to ensure the persisted data
     * is saved in a secure location, as it can contain Sync Keys and
     * OAuth tokens.
     */
    fun registerPersistCallback(persistCallback: PersistCallback) {
        this.persistCallback = persistCallback
    }

    /**
     * Unregisters any previously registered PersistCallback.
     */
    fun unregisterPersistCallback() {
        this.persistCallback = null
    }

    private fun tryPersistState() {
        this.persistCallback?.let {
            val json: String
            try {
                json = this.toJSONString()
            } catch (e: FxaException) {
                Log.e("FirefoxAccount", "Error serializing the FirefoxAccount state.")
                return
            }
            it.persist(json)
        }
    }

    /**
     * Constructs a URL used to begin the OAuth flow for the requested scopes and keys.
     *
     * This performs network requests, and should not be used on the main thread.
     *
     * @param scopes List of OAuth scopes for which the client wants access
     * @return String that resolves to the flow URL when complete
     */
    fun beginOAuthFlow(scopes: Array<String>): String {
        val scope = scopes.joinToString(" ")
        return rustCallWithLock { e ->
            LibFxAFFI.INSTANCE.fxa_begin_oauth_flow(this.handle.get(), scope, e)
        }.getAndConsumeRustString()
    }

    /**
     * Begins the pairing flow.
     *
     * This performs network requests, and should not be used on the main thread.
     */
    fun beginPairingFlow(pairingUrl: String, scopes: Array<String>): String {
        val scope = scopes.joinToString(" ")
        return rustCallWithLock { e ->
            LibFxAFFI.INSTANCE.fxa_begin_pairing_flow(this.handle.get(), pairingUrl, scope, e)
        }.getAndConsumeRustString()
    }

    /**
     * Authenticates the current account using the code and state parameters fetched from the
     * redirect URL reached after completing the sign in flow triggered by [beginOAuthFlow].
     *
     * Modifies the FirefoxAccount state.
     *
     * This performs network requests, and should not be used on the main thread.
     */
    fun completeOAuthFlow(code: String, state: String) {
        rustCallWithLock { e ->
            LibFxAFFI.INSTANCE.fxa_complete_oauth_flow(this.handle.get(), code, state, e)
        }
        this.tryPersistState()
    }

    /**
     * Fetches the profile object for the current client either from the existing cached account,
     * or from the server (requires the client to have access to the profile scope).
     *
     * This performs network requests, and should not be used on the main thread.
     *
     * @param ignoreCache Fetch the profile information directly from the server
     * @return [Profile] representing the user's basic profile info
     * @throws FxaException.Unauthorized We couldn't find any suitable access token to make that call.
     * The caller should then start the OAuth Flow again with the "profile" scope.
     */
    fun getProfile(ignoreCache: Boolean): Profile {
        val profileBuffer = rustCallWithLock { e ->
            LibFxAFFI.INSTANCE.fxa_profile(this.handle.get(), ignoreCache, e)
        }
        this.tryPersistState()
        try {
            val p = MsgTypes.Profile.parseFrom(profileBuffer.asCodedInputStream()!!)
            return Profile.fromMessage(p)
        } finally {
            LibFxAFFI.INSTANCE.fxa_bytebuffer_free(profileBuffer)
        }
    }

    /**
     * Convenience method to fetch the profile from a cached account by default, but fall back
     * to retrieval from the server.
     *
     * This performs network requests, and should not be used on the main thread.
     *
     * @return [Profile] representing the user's basic profile info
     * @throws FxaException.Unauthorized We couldn't find any suitable access token to make that call.
     * The caller should then start the OAuth Flow again with the "profile" scope.
     */
    fun getProfile(): Profile {
        return getProfile(false)
    }

    /**
     * Fetches the token server endpoint, for authentication using the SAML bearer flow.
     *
     * This does not make network requests, and can be used on the main thread.
     */
    fun getTokenServerEndpointURL(): String {
        return rustCallWithLock { e ->
            LibFxAFFI.INSTANCE.fxa_get_token_server_endpoint_url(this.handle.get(), e)
        }.getAndConsumeRustString()
    }

    /**
     * Fetches the connection success url.
     *
     * This does not make network requests, and can be used on the main thread.
     */
    fun getConnectionSuccessURL(): String {
        return rustCallWithLock { e ->
            LibFxAFFI.INSTANCE.fxa_get_connection_success_url(this.handle.get(), e)
        }.getAndConsumeRustString()
    }

    /**
     * Fetches the user's manage-account url.
     *
     * This performs network requests, and should not be used on the main thread.
     *
     * @throws FxaException.Unauthorized We couldn't find any suitable access token to identify the user.
     * The caller should then start the OAuth Flow again with the "profile" scope.
     */
    fun getManageAccountURL(entrypoint: String): String {
        return rustCallWithLock { e ->
            LibFxAFFI.INSTANCE.fxa_get_manage_account_url(this.handle.get(), entrypoint, e)
        }.getAndConsumeRustString()
    }

    /**
     * Fetches the user's manage-devices url.
     *
     * This performs network requests, and should not be used on the main thread.
     *
     * @throws FxaException.Unauthorized We couldn't find any suitable access token to identify the user.
     * The caller should then start the OAuth Flow again with the "profile" scope.
     */
    fun getManageDevicesURL(entrypoint: String): String {
        return rustCallWithLock { e ->
            LibFxAFFI.INSTANCE.fxa_get_manage_devices_url(this.handle.get(), entrypoint, e)
        }.getAndConsumeRustString()
    }

    /**
     * Tries to fetch an access token for the given scope.
     *
     * This performs network requests, and should not be used on the main thread.
     * It may modify the persisted account state.
     *
     * @param scope Single OAuth scope (no spaces) for which the client wants access
     * @return [AccessTokenInfo] that stores the token, along with its scopes and keys when complete
     * @throws FxaException.Unauthorized We couldn't provide an access token
     * for this scope. The caller should then start the OAuth Flow again with
     * the desired scope.
     */
    fun getAccessToken(scope: String): AccessTokenInfo {
        val buffer = rustCallWithLock { e ->
            LibFxAFFI.INSTANCE.fxa_get_access_token(this.handle.get(), scope, e)
        }
        this.tryPersistState()
        try {
            val msg = MsgTypes.AccessTokenInfo.parseFrom(buffer.asCodedInputStream()!!)
            return AccessTokenInfo.fromMessage(msg)
        } finally {
            LibFxAFFI.INSTANCE.fxa_bytebuffer_free(buffer)
        }
    }

    fun checkAuthorizationStatus(): IntrospectInfo {
        val buffer = rustCallWithLock { e ->
            LibFxAFFI.INSTANCE.fxa_check_authorization_status(this.handle.get(), e)
        }
        try {
            val msg = MsgTypes.IntrospectInfo.parseFrom(buffer.asCodedInputStream()!!)
            return IntrospectInfo.fromMessage(msg)
        } finally {
            LibFxAFFI.INSTANCE.fxa_bytebuffer_free(buffer)
        }
    }

    /**
     * Tries to return a session token
     *
     * @throws FxaException Will send you an exception if there is no session token set
     */
    fun getSessionToken(): String {
        return rustCallWithLock { e ->
            LibFxAFFI.INSTANCE.fxa_get_session_token(this.handle.get(), e)
        }.getAndConsumeRustString()
    }

    /**
     * Get the current device id
     *
     * @throws FxaException Will send you an exception if there is no device id set
     */
    fun getCurrentDeviceId(): String {
        return rustCallWithLock { e ->
            LibFxAFFI.INSTANCE.fxa_get_current_device_id(this.handle.get(), e)
        }.getAndConsumeRustString()
    }

    /**
     * Provisions an OAuth code using the session token from state
     *
     * @param clientId OAuth client id.
     * @param scopes Array of scopes for the OAuth code.
     * @param state OAuth flow state.
     * @param accessType Type of access, "offline" or "online".
     * This performs network requests, and should not be used on the main thread.
     */
    fun authorizeOAuthCode(
        clientId: String,
        scopes: Array<String>,
        state: String,
        accessType: String = "online"
    ): String {
        val scope = scopes.joinToString(" ")
        return rustCallWithLock { e ->
            LibFxAFFI.INSTANCE.fxa_authorize_auth_code(this.handle.get(), clientId, scope, state, accessType, e)
        }.getAndConsumeRustString()
    }

    /**
     * This method should be called when a request made with
     * an OAuth token failed with an authentication error.
     * It clears the internal cache of OAuth access tokens,
     * so the caller can try to call `getAccessToken` or `getProfile`
     * again.
     */
    fun clearAccessTokenCache() {
        rustCallWithLock { e ->
            LibFxAFFI.INSTANCE.fxa_clear_access_token_cache(this.handle.get(), e)
        }
    }

    /**
     * Migrate from a logged-in Firefox Account, takes ownership of the provided session token.
     *
     * Modifies the FirefoxAccount state.
     * @param sessionToken 64 character string of hex-encoded bytes
     * @param kSync 128 character string of hex-encoded bytes
     * @param kXCS 32 character string of hex-encoded bytes
     * @return JSONObject JSON object with the result of the migration
     * This performs network requests, and should not be used on the main thread.
     */
    fun migrateFromSessionToken(sessionToken: String, kSync: String, kXCS: String): JSONObject {
        try {
            val json = rustCallWithLock { e ->
                LibFxAFFI.INSTANCE.fxa_migrate_from_session_token(
                    this.handle.get(),
                    sessionToken,
                    kSync,
                    kXCS,
                    0,
                    e
                )
            }.getAndConsumeRustString()
            return JSONObject(json)
        } finally {
            // Even a failed migration might alter the persisted account state, if it's able to be retried.
            // It's safe to call this unconditionally, as the underlying code will not leave partial states.
            this.tryPersistState()
        }
    }

    /**
     * Migrate from a logged-in Firefox Account, takes ownership of the provided session token.
     *
     * @return bool Returns a boolean if we are in a migration state
     */
    fun isInMigrationState(): MigrationState {
        rustCall { e ->
            val state = LibFxAFFI.INSTANCE.fxa_is_in_migration_state(this.handle.get(), e)
            return MigrationState.fromNumber(state.toInt())
        }
    }

    /**
     * Copy a logged-in session of a Firefox Account, creates a new session token in the process.
     *
     * Modifies the FirefoxAccount state.
     * @param sessionToken 64 character string of hex-encoded bytes
     * @param kSync 128 character string of hex-encoded bytes
     * @param kXCS 32 character string of hex-encoded bytes
     * @return JSONObject JSON object with the result of the migration
     * This performs network requests, and should not be used on the main thread.
     */
    fun copyFromSessionToken(sessionToken: String, kSync: String, kXCS: String): JSONObject {
        try {
            val json = rustCallWithLock { e ->
                LibFxAFFI.INSTANCE.fxa_migrate_from_session_token(this.handle.get(), sessionToken, kSync, kXCS, 1, e)
            }.getAndConsumeRustString()
            return JSONObject(json)
        } finally {
            // Even a failed migration might alter the persisted account state, if it's able to be retried.
            // It's safe to call this unconditionally, as the underlying code will not leave partial states.
            this.tryPersistState()
        }
    }

    /**
     * Retry migration from a logged-in Firefox Account.
     *
     * Modifies the FirefoxAccount state.
     * @return JSONObject JSON object with the result of the migration
     * This performs network requests, and should not be used on the main thread.
     */
    fun retryMigrateFromSessionToken(): JSONObject {
        try {
            val json = rustCallWithLock { e ->
                LibFxAFFI.INSTANCE.fxa_retry_migrate_from_session_token(this.handle.get(), e)
            }.getAndConsumeRustString()
            return JSONObject(json)
        } finally {
            // A failure her might alter the persisted account state, if we discover a permanent migration failure.
            // It's safe to call this unconditionally, as the underlying code will not leave partial states.
            this.tryPersistState()
        }
    }

    /**
     * Saves the current account's authentication state as a JSON string, for persistence in
     * the Android KeyStore/shared preferences. The authentication state can be restored using
     * [FirefoxAccount.fromJSONString].
     *
     * This does not make network requests, and can be used on the main thread.
     *
     * @return String containing the authentication details in JSON format
     */
    fun toJSONString(): String {
        return rustCallWithLock { e ->
            LibFxAFFI.INSTANCE.fxa_to_json(this.handle.get(), e)
        }.getAndConsumeRustString()
    }

    /**
     * Update the push subscription details for the current device.
     * This needs to be called every time a push subscription is modified or expires.
     *
     * This performs network requests, and should not be used on the main thread.
     *
     * @param endpoint Push callback URL
     * @param publicKey Public key used to encrypt push payloads
     * @param authKey Auth key used to encrypt push payloads
     */
    fun setDevicePushSubscription(endpoint: String, publicKey: String, authKey: String) {
        rustCall { e ->
            LibFxAFFI.INSTANCE.fxa_set_push_subscription(this.handle.get(), endpoint, publicKey, authKey, e)
        }
    }

    /**
     * Update the display name (as shown in the FxA device manager, or the Send Tab target list)
     * for the current device.
     *
     * This performs network requests, and should not be used on the main thread.
     *
     * @param displayName The current device display name
     */
    fun setDeviceDisplayName(displayName: String) {
        rustCall { e ->
            LibFxAFFI.INSTANCE.fxa_set_device_name(this.handle.get(), displayName, e)
        }
    }

    /**
     * Retrieves the list of the connected devices in the current account, including the current one.
     *
     * This performs network requests, and should not be used on the main thread.
     */
    fun getDevices(): Array<Device> {
        val devicesBuffer = rustCall { e ->
            LibFxAFFI.INSTANCE.fxa_get_devices(this.handle.get(), e)
        }
        try {
            val devices = MsgTypes.Devices.parseFrom(devicesBuffer.asCodedInputStream()!!)
            return Device.fromCollectionMessage(devices)
        } finally {
            LibFxAFFI.INSTANCE.fxa_bytebuffer_free(devicesBuffer)
        }
    }

    /**
     * Disconnect from the account and optionaly destroy our device record.
     * `beginOAuthFlow` will need to be called to reconnect.
     *
     * This performs network requests, and should not be used on the main thread.
     */
    fun disconnect() {
        rustCall { e ->
            LibFxAFFI.INSTANCE.fxa_disconnect(this.handle.get(), e)
        }
        this.tryPersistState()
    }

    /**
     * Retrieves any pending commands for the current device.
     * This should be called semi-regularly as the main method of commands delivery (push)
     * can sometimes be unreliable on mobile devices.
     * If a persist callback is set and the host application failed to process the
     * returned account events, they will never be seen again.
     *
     * This performs network requests, and should not be used on the main thread.
     *
     * @return A collection of [IncomingDeviceCommand] that should be handled by the caller.
     */
    fun pollDeviceCommands(): Array<IncomingDeviceCommand> {
        val eventsBuffer = rustCall { e ->
            LibFxAFFI.INSTANCE.fxa_poll_device_commands(this.handle.get(), e)
        }
        this.tryPersistState()
        try {
            val commands = MsgTypes.IncomingDeviceCommands.parseFrom(eventsBuffer.asCodedInputStream()!!)
            return IncomingDeviceCommand.fromCollectionMessage(commands)
        } finally {
            LibFxAFFI.INSTANCE.fxa_bytebuffer_free(eventsBuffer)
        }
    }

    /**
     * Handle any incoming push message payload coming from the Firefox Accounts
     * servers that has been decrypted and authenticated by the Push crate.
     *
     * This performs network requests, and should not be used on the main thread.
     *
     * @return A collection of [AccountEvent] that should be handled by the caller.
     */
    fun handlePushMessage(payload: String): Array<AccountEvent> {
        val eventsBuffer = rustCall { e ->
            LibFxAFFI.INSTANCE.fxa_handle_push_message(this.handle.get(), payload, e)
        }
        this.tryPersistState()
        try {
            val events = MsgTypes.AccountEvents.parseFrom(eventsBuffer.asCodedInputStream()!!)
            return AccountEvent.fromCollectionMessage(events)
        } finally {
            LibFxAFFI.INSTANCE.fxa_bytebuffer_free(eventsBuffer)
        }
    }

    /**
     * Ensure the current device is registered with the specified name and device type, with
     * the required capabilities (at this time only Send Tab).
     * This method should be called once per "device lifetime".
     *
     * This performs network requests, and should not be used on the main thread.
     */
    fun initializeDevice(name: String, deviceType: Device.Type, supportedCapabilities: Set<Device.Capability>) {
        val (nioBuf, len) = supportedCapabilities.toCollectionMessage().toNioDirectBuffer()
        rustCall { e ->
            val ptr = Native.getDirectBufferPointer(nioBuf)
            LibFxAFFI.INSTANCE.fxa_initialize_device(this.handle.get(), name, deviceType.toNumber(), ptr, len, e)
        }
        this.tryPersistState()
    }

    /**
     * Ensure that the supported capabilities described earlier in `initializeDevice` are A-OK.
     * A set of capabilities to be supported by the Device must also be passed (at this time only
     * Send Tab).
     *
     * As for now there's only the Send Tab capability, so we ensure the command is registered with the server.
     * This method should be called at least every time the sync keys change (because Send Tab relies on them).
     *
     * This performs network requests, and should not be used on the main thread.
     */
    fun ensureCapabilities(supportedCapabilities: Set<Device.Capability>) {
        val (nioBuf, len) = supportedCapabilities.toCollectionMessage().toNioDirectBuffer()
        rustCall { e ->
            val ptr = Native.getDirectBufferPointer(nioBuf)
            LibFxAFFI.INSTANCE.fxa_ensure_capabilities(this.handle.get(), ptr, len, e)
        }
        this.tryPersistState()
    }

    /**
     * Send a single tab to another device identified by its device ID.
     *
     * This performs network requests, and should not be used on the main thread.
     *
     * @param targetDeviceId The target Device ID
     * @param title The document title of the tab being sent
     * @param url The url of the tab being sent
     */
    fun sendSingleTab(targetDeviceId: String, title: String, url: String) {
        rustCall { e ->
            LibFxAFFI.INSTANCE.fxa_send_tab(this.handle.get(), targetDeviceId, title, url, e)
        }
    }

    @Synchronized
    override fun close() {
        val handle = this.handle.getAndSet(0)
        if (handle != 0L) {
            rustCall { err ->
                LibFxAFFI.INSTANCE.fxa_free(handle, err)
            }
        }
    }

    private inline fun <U> nullableRustCallWithLock(callback: (RustError.ByReference) -> U?): U? {
        return synchronized(this) {
            nullableRustCall { callback(it) }
        }
    }

    private inline fun <U> rustCallWithLock(callback: (RustError.ByReference) -> U?): U {
        return nullableRustCallWithLock(callback)!!
    }
}

// In practice we usually need to be synchronized to call this safely, so it doesn't
// synchronize itself
private inline fun <U> nullableRustCall(callback: (RustError.ByReference) -> U?): U? {
    val e = RustError.ByReference()
    try {
        val ret = callback(e)
        if (e.isFailure()) {
            throw e.intoException()
        }
        return ret
    } finally {
        // This only matters if `callback` throws (or does a non-local return, which
        // we currently don't do)
        e.ensureConsumed()
    }
}

private inline fun <U> rustCall(callback: (RustError.ByReference) -> U?): U {
    return nullableRustCall(callback)!!
}

/**
 * Helper to read a null terminated String out of the Pointer and free it.
 *
 * Important: Do not use this pointer after this! For anything!
 */
internal fun Pointer.getAndConsumeRustString(): String {
    try {
        return this.getRustString()
    } finally {
        LibFxAFFI.INSTANCE.fxa_str_free(this)
    }
}

/**
 * Helper to read a null terminated string out of the pointer.
 *
 * Important: doesn't free the pointer, use [getAndConsumeRustString] for that!
 */
internal fun Pointer.getRustString(): String {
    return this.getString(0, "utf8")
}
