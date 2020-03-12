/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.syncmanager

import com.sun.jna.Pointer
import com.sun.jna.Structure

@Structure.FieldOrder("code", "message")
internal open class RustError : Structure() {

    class ByReference : RustError(), Structure.ByReference

    @JvmField var code: Int = 0
    @JvmField var message: Pointer? = null

    fun isSuccess(): Boolean {
        return code == 0
    }

    fun isFailure(): Boolean {
        return code != 0
    }

    @Suppress("ComplexMethod", "ReturnCount", "TooGenericExceptionThrown")
    fun intoException(): SyncManagerException {
        if (!isFailure()) {
            // It's probably a bad idea to throw here! We're probably leaking something if this is
            // ever hit! (But we shouldn't ever hit it?)
            throw RuntimeException("[Bug] intoException called on non-failure!")
        }
        val message = this.consumeErrorMessage()
        when (code) {
            2 -> return UnsupportedEngine(message)
            3 -> return ClosedEngine(message)
            -1 -> return InternalPanic(message)
            // Note: `1` is used as a generic catch all, but we
            // might as well handle the others the same way.
            else -> return UnexpectedError(message)
        }
    }

    /**
     * Get and consume the error message, or null if there is none.
     */
    fun consumeErrorMessage(): String {
        val result = this.getMessage()
        if (this.message != null) {
            LibSyncManagerFFI.INSTANCE.sync_manager_destroy_string(this.message!!)
            this.message = null
        }
        if (result == null) {
            throw NullPointerException("consumeErrorMessage called with null message!")
        }
        return result
    }

    /**
     * Get the error message or null if there is none.
     */
    fun getMessage(): String? {
        return this.message?.getString(0, "utf8")
    }
}
