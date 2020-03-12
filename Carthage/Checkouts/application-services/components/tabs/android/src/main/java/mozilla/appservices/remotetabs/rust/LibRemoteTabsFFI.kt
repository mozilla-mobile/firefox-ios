@file:Suppress("MaxLineLength")
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.remotetabs.rust

import com.sun.jna.Library
import com.sun.jna.Pointer
import mozilla.appservices.support.native.RustBuffer
import mozilla.appservices.support.native.loadIndirect
import org.mozilla.appservices.experimental.remotetabs.BuildConfig

@Suppress("FunctionNaming", "FunctionParameterNaming", "LongParameterList", "TooGenericExceptionThrown")
internal interface LibRemoteTabsFFI : Library {
    companion object {
        internal var INSTANCE: LibRemoteTabsFFI =
            loadIndirect(componentName = "tabs", componentVersion = BuildConfig.LIBRARY_VERSION)
    }

    fun remote_tabs_new(
        error: RustError.ByReference
    ): TabsApiHandle

    fun remote_tabs_destroy(handle: TabsApiHandle, error: RustError.ByReference)

    fun remote_tabs_update_local(
        handle: TabsApiHandle,
        local_state_data: Pointer,
        local_state_len: Int,
        error: RustError.ByReference
    )

    fun remote_tabs_get_all(
        handle: TabsApiHandle,
        error: RustError.ByReference
    ): RustBuffer.ByValue

    // Returns a JSON string containing a sync ping.
    fun remote_tabs_sync(
        handle: TabsApiHandle,
        key_id: String,
        access_token: String,
        sync_key: String,
        token_server_url: String,
        local_device_id: String,
        error: RustError.ByReference
    ): Pointer?

    fun remote_tabs_destroy_bytebuffer(buffer: RustBuffer.ByValue)
    fun remote_tabs_destroy_string(p: Pointer)
}

internal typealias TabsApiHandle = Long
