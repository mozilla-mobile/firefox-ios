/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.support.native

import com.google.protobuf.CodedInputStream
import com.google.protobuf.CodedOutputStream
import com.sun.jna.Pointer
import com.sun.jna.Structure

/**
 * This is a mapping for the `ffi_support::ByteBuffer` struct.
 *
 * The name differs for two reasons.
 *
 * 1. To that the memory this type manages is allocated from rust code,
 *    and must subsequently be freed by rust code.
 *
 * 2. To avoid confusion with java's nio ByteBuffer, which we use for
 *    passing data *to* Rust without incurring additional copies.
 *
 * # Caveats:
 *
 * 1. It is for receiving data *FROM* Rust, and not the other direction.
 *    RustBuffer doesn't expose a way to inspect its contents from Rust.
 *    See `docs/howtos/passing-protobuf-data-over-ffi.md` for how to do
 *    this instead.
 *
 * 2. A `RustBuffer` passed into kotlin code must be freed by kotlin
 *    code *after* the protobuf message is completely deserialized.
 *
 *    The rust code must expose a destructor for this purpose,
 *    and it should be called in the finally block after the data
 *    is read from the `CodedInputStream` (and not before).
 *
 * 3. You almost always should use `RustBuffer.ByValue` instead
 *    of `RustBuffer`. E.g.
 *    `fun mylib_get_stuff(some: X, args: Y): RustBuffer.ByValue`
 *    for the function returning the RustBuffer, and
 *    `fun mylib_destroy_bytebuffer(bb: RustBuffer.ByValue)`.
 */
@Structure.FieldOrder("len", "data")
open class RustBuffer : Structure() {
    @JvmField var len: Long = 0
    @JvmField var data: Pointer? = null

    fun asCodedInputStream(): CodedInputStream? {
        return this.data?.let {
            CodedInputStream.newInstance(it.getByteBuffer(0, this.len))
        }
    }

    fun asCodedOutputStream(): CodedOutputStream? {
        return this.data?.let {
            CodedOutputStream.newInstance(it.getByteBuffer(0, this.len))
        }
    }

    class ByValue : RustBuffer(), Structure.ByValue
}
