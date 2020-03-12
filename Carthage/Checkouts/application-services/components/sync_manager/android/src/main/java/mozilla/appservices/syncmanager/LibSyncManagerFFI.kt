/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.syncmanager

import com.sun.jna.Library
import com.sun.jna.Pointer
import mozilla.appservices.support.native.RustBuffer
import mozilla.appservices.support.native.loadIndirect
import org.mozilla.appservices.syncmanager.BuildConfig

@Suppress("FunctionNaming", "FunctionParameterNaming", "LongParameterList", "TooGenericExceptionThrown")
internal interface LibSyncManagerFFI : Library {
    companion object {
        internal var INSTANCE: LibSyncManagerFFI =
            loadIndirect(componentName = "syncmanager", componentVersion = BuildConfig.LIBRARY_VERSION)
    }
    fun sync_manager_set_places(handle: PlacesApiHandle, error: RustError.ByReference)
    fun sync_manager_set_logins(handle: LoginsDbHandle, error: RustError.ByReference)
    fun sync_manager_set_tabs(handle: TabsApiHandle, error: RustError.ByReference)
    fun sync_manager_disconnect(error: RustError.ByReference)

    fun sync_manager_sync(data: Pointer, len: Int, error: RustError.ByReference): RustBuffer.ByValue

    fun sync_manager_destroy_string(s: Pointer)
    fun sync_manager_destroy_bytebuffer(bb: RustBuffer.ByValue)
}

internal typealias PlacesApiHandle = Long
internal typealias LoginsDbHandle = Long
internal typealias TabsApiHandle = Long
