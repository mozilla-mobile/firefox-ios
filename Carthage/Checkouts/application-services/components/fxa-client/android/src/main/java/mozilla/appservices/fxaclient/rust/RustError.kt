/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.fxaclient.rust

import com.sun.jna.Pointer
import com.sun.jna.Structure
import mozilla.appservices.fxaclient.FxaException
import mozilla.appservices.fxaclient.getAndConsumeRustString

@Structure.FieldOrder("code", "message")
internal open class RustError : Structure() {

    class ByReference : RustError(), Structure.ByReference

    @JvmField var code: Int = 0
    @JvmField var message: Pointer? = null

    /**
     * Does this represent success?
     */
    fun isSuccess(): Boolean {
        return code == 0
    }

    /**
     * Does this represent failure?
     */
    fun isFailure(): Boolean {
        return code != 0
    }

    @Suppress("ReturnCount", "TooGenericExceptionThrown")
    fun intoException(): FxaException {
        if (!isFailure()) {
            // It's probably a bad idea to throw here! We're probably leaking something if this is
            // ever hit! (But we shouldn't ever hit it?)
            throw RuntimeException("[Bug] intoException called on non-failure!")
        }
        val message = this.consumeErrorMessage()
        when (code) {
            3 -> return FxaException.Network(message)
            2 -> return FxaException.Unauthorized(message)
            -1 -> return FxaException.Panic(message)
            // Note: `1` is used as a generic catch all, but we
            // might as well handle the others the same way.
            else -> return FxaException.Unspecified(message)
        }
    }

    /**
     * Get and consume the error message, or null if there is none.
     */
    @Synchronized
    fun consumeErrorMessage(): String {
        val result = this.getMessage()
        if (this.message != null) {
            LibFxAFFI.INSTANCE.fxa_str_free(this.message!!)
            this.message = null
        }
        if (result == null) {
            throw NullPointerException("consumeErrorMessage called with null message!")
        }
        return result
    }

    @Synchronized
    fun ensureConsumed() {
        this.message?.getAndConsumeRustString()
        this.message = null
    }

    /**
     * Get the error message or null if there is none.
     */
    fun getMessage(): String? {
        return this.message?.getString(0, "utf8")
    }
}
