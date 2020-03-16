@file:Suppress("MaxLineLength")
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.logins.rust

import com.sun.jna.Library
import com.sun.jna.Pointer
import com.sun.jna.PointerType
import mozilla.appservices.support.native.loadIndirect
import mozilla.appservices.support.native.RustBuffer
import org.mozilla.appservices.logins.BuildConfig

@Suppress("FunctionNaming", "FunctionParameterNaming", "LongParameterList", "TooGenericExceptionThrown")
internal interface PasswordSyncAdapter : Library {
    companion object {
        internal var INSTANCE: PasswordSyncAdapter =
            loadIndirect(componentName = "logins", componentVersion = BuildConfig.LIBRARY_VERSION)
    }

    fun sync15_passwords_state_new(
        mentat_db_path: String,
        encryption_key: String,
        error: RustError.ByReference
    ): LoginsDbHandle

    fun sync15_passwords_state_new_with_hex_key(
        db_path: String,
        encryption_key_bytes: ByteArray,
        encryption_key_len: Int,
        error: RustError.ByReference
    ): LoginsDbHandle

    fun sync15_passwords_state_destroy(handle: LoginsDbHandle, error: RustError.ByReference)

    // Important: strings returned from rust as *char must be Pointers on this end, returning a
    // String will work but either force us to leak them, or cause us to corrupt the heap (when we
    // free them).

    // Returns null if the id does not exist, otherwise protocol buffer
    fun sync15_passwords_get_by_id(handle: LoginsDbHandle, id: String, error: RustError.ByReference): RustBuffer.ByValue

    // return protocol buffer
    fun sync15_passwords_get_all(handle: LoginsDbHandle, error: RustError.ByReference): RustBuffer.ByValue

    // return protocol buffer
    fun sync15_passwords_get_by_base_domain(handle: LoginsDbHandle, basedomain: String, error: RustError.ByReference): RustBuffer.ByValue

    // Returns a JSON string containing a sync ping.
    fun sync15_passwords_sync(
        handle: LoginsDbHandle,
        key_id: String,
        access_token: String,
        sync_key: String,
        token_server_url: String,
        error: RustError.ByReference
    ): Pointer?

    fun sync15_passwords_wipe(handle: LoginsDbHandle, error: RustError.ByReference)
    fun sync15_passwords_wipe_local(handle: LoginsDbHandle, error: RustError.ByReference)
    fun sync15_passwords_reset(handle: LoginsDbHandle, error: RustError.ByReference)

    fun sync15_passwords_touch(handle: LoginsDbHandle, id: String, error: RustError.ByReference)

    fun sync15_passwords_check_valid(handle: LoginsDbHandle, data: Pointer, len: Int, error: RustError.ByReference)

    // This is 1 for true and 0 for false, it would be a boolean but we need to return a value with
    // a known size.
    fun sync15_passwords_delete(handle: LoginsDbHandle, id: String, error: RustError.ByReference): Byte
    // Note: returns guid of new login entry (unless one was specifically requested)
    fun sync15_passwords_add(handle: LoginsDbHandle, data: Pointer, len: Int, error: RustError.ByReference): Pointer?
    fun sync15_passwords_update(handle: LoginsDbHandle, data: Pointer, len: Int, error: RustError.ByReference)

    // Returns a JSON string containing import metrics
    fun sync15_passwords_import(handle: LoginsDbHandle, data: Pointer, len: Int, error: RustError.ByReference): Pointer?

    fun sync15_passwords_destroy_string(p: Pointer)
    fun sync15_passwords_destroy_buffer(b: RustBuffer.ByValue)

    fun sync15_passwords_new_interrupt_handle(handle: LoginsDbHandle, error: RustError.ByReference): RawLoginsInterruptHandle?
    fun sync15_passwords_interrupt(handle: RawLoginsInterruptHandle, error: RustError.ByReference)
    fun sync15_passwords_interrupt_handle_destroy(handle: RawLoginsInterruptHandle)

    fun sync15_passwords_rekey_database(
        handle: LoginsDbHandle,
        new_encryption_key: String,
        error: RustError.ByReference
    )
    fun sync15_passwords_rekey_database_with_hex_key(
        handle: LoginsDbHandle,
        new_encryption_key_bytes: ByteArray,
        new_encryption_key_len: Int,
        error: RustError.ByReference
    )
}

internal typealias LoginsDbHandle = Long

internal class RawLoginsInterruptHandle : PointerType()
