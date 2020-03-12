/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.rustlog

import com.sun.jna.Library
import com.sun.jna.Callback
import com.sun.jna.Pointer
import com.sun.jna.PointerType
import mozilla.appservices.support.native.loadIndirect
import org.mozilla.appservices.rustlog.BuildConfig

@Suppress("FunctionNaming", "TooGenericExceptionThrown")
internal interface LibRustLogAdapter : Library {
    companion object {
        // XXX this should be direct binding...
        internal var INSTANCE: LibRustLogAdapter =
            loadIndirect(componentName = "rustlog", componentVersion = BuildConfig.LIBRARY_VERSION)
    }

    fun rc_log_adapter_create(
        callback: RawLogCallback,
        outErr: RustError.ByReference
    ): RawLogAdapter?

    fun rc_log_adapter_set_max_level(
        level: Int,
        outErr: RustError.ByReference
    )

    fun rc_log_adapter_destroy(
        adapter: RawLogAdapter
    )

    fun rc_log_adapter_destroy_string(
        stringPtr: Pointer
    )

    fun rc_log_adapter_test__log_msg(
        string: String
    )
}

internal interface RawLogCallback : Callback {
    fun invoke(level: Int, tag: Pointer?, message: Pointer): Byte
}

internal class RawLogAdapter : PointerType()
