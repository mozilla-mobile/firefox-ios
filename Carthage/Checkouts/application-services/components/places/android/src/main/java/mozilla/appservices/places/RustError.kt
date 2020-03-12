/* Copyright 2018 Mozilla
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use
 * this file except in compliance with the License. You may obtain a copy of the
 * License at http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to in writing, software distributed
 * under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License. */
package mozilla.appservices.places

import com.sun.jna.Pointer
import com.sun.jna.Structure

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

    @Suppress("ComplexMethod", "ReturnCount", "TooGenericExceptionThrown")
    fun intoException(): PlacesException {
        if (!isFailure()) {
            // It's probably a bad idea to throw here! We're probably leaking something if this is
            // ever hit! (But we shouldn't ever hit it?)
            throw RuntimeException("[Bug] intoException called on non-failure!")
        }
        val message = this.consumeErrorMessage()
        when (code) {
            2 -> return UrlParseFailed(message)
            3 -> return PlacesConnectionBusy(message)
            4 -> return OperationInterrupted(message)
            5 -> return BookmarksCorruption(message)

            64 -> return InvalidParent(message)
            65 -> return UnknownBookmarkItem(message)
            66 -> return UrlTooLong(message)
            67 -> return InvalidBookmarkUpdate(message)
            68 -> return CannotUpdateRoot(message)

            -1 -> return InternalPanic(message)
            // Note: `1` is used as a generic catch all, but we
            // might as well handle the others the same way.
            else -> return PlacesException(message)
        }
    }

    /**
     * Get and consume the error message, or null if there is none.
     */
    fun consumeErrorMessage(): String {
        val result = this.getMessage()
        if (this.message != null) {
            LibPlacesFFI.INSTANCE.places_destroy_string(this.message!!)
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
