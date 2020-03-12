/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.syncmanager

import com.sun.jna.Native
import mozilla.appservices.support.native.toNioDirectBuffer

object SyncManager {

    /**
     * Point the manager at the implementation of `PlacesApi` to use.
     *
     * @param placesApiHandle A value returned by `PlacesApi.getHandle()`
     * @throws [UnsupportedEngine] If the manager was not compiled with places support.
     */
    fun setPlaces(placesApiHandle: Long) {
        rustCall { err ->
            LibSyncManagerFFI.INSTANCE.sync_manager_set_places(placesApiHandle, err)
        }
    }

    /**
     * Point the manager at the implementation of `DatabaseLoginsStorage` to use.
     *
     * @param loginsDbHandle A value returned by `DatabaseLoginsStorage.getHandle()`
     * @throws [UnsupportedEngine] If the manager was not compiled with logins support.
     */
    fun setLogins(loginsDbHandle: Long) {
        rustCall { err ->
            LibSyncManagerFFI.INSTANCE.sync_manager_set_logins(loginsDbHandle, err)
        }
    }

    /**
     * Point the manager at the implementation of `RemoteTabsProvider` to use.
     *
     * @param tabsProviderHandle A value returned by `RemoteTabsProvider.getHandle()`
     * @throws [UnsupportedEngine] If the manager was not compiled with tabs support.
     */
    fun setTabs(tabsProviderHandle: Long) {
        rustCall { err ->
            LibSyncManagerFFI.INSTANCE.sync_manager_set_tabs(tabsProviderHandle, err)
        }
    }

    /**
     * Disconnect this device from sync. This essentially clears shared state having to do with
     * sync, as well as each engine's sync-specific local state.
     */
    fun disconnect() {
        rustCall { err ->
            LibSyncManagerFFI.INSTANCE.sync_manager_disconnect(err)
        }
    }
    /**
     * Perform a sync.
     */
    fun sync(params: SyncParams): SyncResult {
        val buf = params.toProtobuf()
        val (nioBuf, len) = buf.toNioDirectBuffer()
        val rustBuf = rustCall { err ->
            val ptr = Native.getDirectBufferPointer(nioBuf)
            LibSyncManagerFFI.INSTANCE.sync_manager_sync(ptr, len, err)
        }

        try {
            val stream = rustBuf.asCodedInputStream()
            return SyncResult.fromProtobuf(MsgTypes.SyncResult.parseFrom(stream))
        } finally {
            LibSyncManagerFFI.INSTANCE.sync_manager_destroy_bytebuffer(rustBuf)
        }
    }
}

internal inline fun <U> rustCall(callback: (RustError.ByReference) -> U): U {
    val e = RustError.ByReference()
    val ret: U = callback(e)
    if (e.isFailure()) {
        throw e.intoException()
    } else {
        return ret
    }
}
