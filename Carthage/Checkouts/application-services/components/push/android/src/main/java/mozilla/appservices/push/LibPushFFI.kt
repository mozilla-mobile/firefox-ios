@file:Suppress("MaxLineLength")
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.push

import com.sun.jna.Library
import com.sun.jna.Pointer
import mozilla.appservices.support.native.RustBuffer
import mozilla.appservices.support.native.loadIndirect
import org.mozilla.appservices.push.BuildConfig

@Suppress("FunctionNaming", "FunctionParameterNaming", "LongParameterList", "TooGenericExceptionThrown")
internal interface LibPushFFI : Library {
    companion object {
        internal var INSTANCE: LibPushFFI =
            loadIndirect(componentName = "push", componentVersion = BuildConfig.LIBRARY_VERSION)
    }

    // Important: strings returned from rust as *mut char must be Pointers on this end, returning a
    // String will work but either force us to leak them, or cause us to corrupt the heap (when we
    // free them).

    /** Create a new push connection */
    fun push_connection_new(
        server_host: String,
        http_protocol: String?,
        bridge_type: String?,
        registration_id: String,
        sender_id: String?,
        database_path: String,
        out_err: RustError.ByReference
    ): PushManagerHandle

    /** Returns Protocol Buffer */
    fun push_subscribe(
        mgr: PushManagerHandle,
        channel_id: String,
        scope: String,
        appServerKey: String?,
        out_err: RustError.ByReference
    ): RustBuffer.ByValue

    /** Returns bool */
    fun push_unsubscribe(
        mgr: PushManagerHandle,
        channel_id: String,
        out_err: RustError.ByReference
    ): Byte

    fun push_unsubscribe_all(
        mgr: PushManagerHandle,
        out_err: RustError.ByReference
    ): Byte

    fun push_update(
        mgr: PushManagerHandle,
        new_token: String,
        out_err: RustError.ByReference
    ): Byte

    fun push_verify_connection(
        mgr: PushManagerHandle,
        out_err: RustError.ByReference
    ): RustBuffer.ByValue

    fun push_decrypt(
        mgr: PushManagerHandle,
        channel_id: String,
        body: String,
        encoding: String,
        salt: String?,
        dh: String?,
        out_err: RustError.ByReference
    ): Pointer?

    fun push_dispatch_info_for_chid(
        mgr: PushManagerHandle,
        channelID: String,
        out_err: RustError.ByReference
    ): RustBuffer.ByValue

    /** Destroy strings returned from libpush_ffi calls. */
    fun push_destroy_string(s: Pointer)

    /** Destroy a buffer value returned from the decrypt ffi call */
    fun push_destroy_buffer(s: RustBuffer.ByValue)

    /** Destroy connection created using `push_connection_new` */
    fun push_connection_destroy(obj: PushManagerHandle, out_err: RustError.ByReference)
}

internal typealias PushManagerHandle = Long
