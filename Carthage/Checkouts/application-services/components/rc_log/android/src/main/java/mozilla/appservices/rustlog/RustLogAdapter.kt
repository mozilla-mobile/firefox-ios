/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.rustlog

import com.sun.jna.CallbackThreadInitializer
import com.sun.jna.Native
import com.sun.jna.Pointer
import java.util.concurrent.atomic.AtomicBoolean

typealias OnLog = (Int, String?, String) -> Boolean
class RustLogAdapter private constructor(
    // IMPORTANT: This must not be GCed while the adapter is alive!
    @Suppress("Unused")
    private val callbackImpl: RawLogCallbackImpl,
    private val adapter: RawLogAdapter
) {
    companion object {
        @Volatile
        private var instance: RustLogAdapter? = null

        /**
         * true if the log is enabled.
         */
        val isEnabled get() = getEnabled()

        // Used to signal from the log callback that we should disable
        // the adapter because the callback returned false. Note that
        // Rust handles this too.
        internal val disabledRemotely = AtomicBoolean(false)

        @Synchronized
        private fun getEnabled(): Boolean {
            if (instance == null) {
                return false
            }
            if (disabledRemotely.getAndSet(false)) {
                this.disable()
            }
            return instance != null
        }

        /**
         * Enable the logger and use the provided logging callback.
         *
         * @throws [LogAdapterCannotEnable] if it is already enabled.
         */
        @Synchronized
        fun enable(onLog: OnLog) {
            if (isEnabled) {
                throw LogAdapterCannotEnable("Adapter is already enabled")
            }
            // Tell JNA to reuse the callback thread.
            val initializer = CallbackThreadInitializer(
                    // Don't block JVM shutdown waiting for this thread to exit.
                    /* daemon */ true,
                    // Don't detach the JVM from this thread after invoking the callback.
                    /* detach */ false,
                    /* name */ "RustLogThread"
            )
            val callbackImpl = RawLogCallbackImpl(onLog)
            Native.setCallbackThreadInitializer(callbackImpl, initializer)
            // Hopefully there is no way to half-initialize the logger such that where the callback
            // could still get called despite an error/null being returned? If there is, we need to
            // make callbackImpl isn't GCed here, or very bad things will happen. (Should the logger
            // init code abort on panic?)
            val adapter = rustCall { err ->
                LibRustLogAdapter.INSTANCE.rc_log_adapter_create(callbackImpl, err)
            }
            // For example, it would be *extremely bad* if somehow adapter were actually null here.
            instance = RustLogAdapter(callbackImpl, adapter!!)
        }

        /**
         * Helper to enable the logger if it can be enabled. Returns true if
         * the logger was enabled by this call.
         */
        @Synchronized
        fun tryEnable(onLog: OnLog): Boolean {
            if (isEnabled) {
                return false
            }
            enable(onLog)
            return true
        }

        /**
         * Disable the logger, allowing the logging callback to be garbage collected.
         */
        @Synchronized
        fun disable() {
            val state = instance ?: return
            LibRustLogAdapter.INSTANCE.rc_log_adapter_destroy(state.adapter)
            // XXX Letting that callback get GCed still makes me extremely uneasy...
            // Maybe we should just null out the callback provided by the user so that
            // it can be GCed (while letting the RawLogCallbackImpl which actually is
            // called by Rust live on).
            instance = null
            disabledRemotely.set(false)
        }

        @Synchronized
        fun setMaxLevel(level: LogLevelFilter) {
            if (isEnabled) {
                rustCall { e ->
                    LibRustLogAdapter.INSTANCE.rc_log_adapter_set_max_level(
                            level.value,
                            e
                    )
                }
            }
        }

        private inline fun <U> rustCall(callback: (RustError.ByReference) -> U): U {
            val e = RustError.ByReference()
            val ret: U = callback(e)
            if (e.isFailure()) {
                val msg = e.consumeErrorMessage()
                throw LogAdapterUnexpectedError(msg)
            } else {
                return ret
            }
        }
    }
}

/**
 * All errors emitted by the LogAdapter will subclass this.
 */
sealed class LogAdapterError(msg: String) : Exception(msg)

/**
 * Error indicating that the log adapter cannot be enabled because it is already enabled.
 */
class LogAdapterCannotEnable(msg: String) : LogAdapterError("Log adapter may not be enabled: $msg")

/**
 * Thrown for unexpected log adapter errors (generally rust panics).
 */
class LogAdapterUnexpectedError(msg: String) : LogAdapterError("Unexpected log adapter error: $msg")

// Note: keep values in sync with level_filter_from_i32 in rust.
/** Level filters, for use with setMaxLevel. */
enum class LogLevelFilter(internal val value: Int) {
    /** Disable all logging */
    OFF(0),
    /** Only allow ERROR logs. */
    ERROR(1),
    /** Allow WARN and ERROR logs. */
    WARN(2),
    /** Allow WARN, ERROR, and INFO logs. The default. */
    INFO(3),
    /** Allow WARN, ERROR, INFO, and DEBUG logs. */
    DEBUG(4),
    /** Allow all logs, including those that may contain PII. */
    TRACE(5),
}

internal class RawLogCallbackImpl(private val onLog: OnLog) : RawLogCallback {
    @Suppress("TooGenericExceptionCaught")
    override fun invoke(level: Int, tag: Pointer?, message: Pointer): Byte {
        // We can't safely throw here!
        val result = try {
            val tagStr = tag?.getString(0, "utf8")
            val msgStr = message.getString(0, "utf8")
            onLog(level, tagStr, msgStr)
        } catch (e: Throwable) {
            try {
                println("Exception when logging: $e")
            } catch (e: Throwable) {
                // :(
            }
            false
        }
        return if (result) {
            1
        } else {
            RustLogAdapter.disabledRemotely.set(true)
            0
        }
    }
}

internal fun Pointer.getAndConsumeRustString(): String {
    try {
        return this.getString(0, "utf8")
    } finally {
        LibRustLogAdapter.INSTANCE.rc_log_adapter_destroy_string(this)
    }
}
