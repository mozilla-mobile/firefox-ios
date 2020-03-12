/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.rustlog

import com.sun.jna.Pointer
import com.sun.jna.Structure

/**
 * This should be considered private, but it needs to be public for JNA.
 */
@Structure.FieldOrder("code", "message")
open class RustError : Structure() {

    class ByReference : RustError(), Structure.ByReference

    @JvmField var code: Int = 0
    @JvmField var message: Pointer? = null

    fun isFailure(): Boolean {
        return code != 0
    }

    /**
     * Get and consume the error message, or null if there is none.
     */
    @Synchronized
    fun consumeErrorMessage(): String {
        val result = this.message?.getAndConsumeRustString()
        this.message = null
        if (result == null) {
            throw NullPointerException("consumeErrorMessage called with null message!")
        }
        return result
    }
}
