/* Any copyright is dedicated to the Public Domain.
   http://creativecommons.org/publicdomain/zero/1.0/ */

package mozilla.appservices.rustlog

import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import mozilla.appservices.Megazord
import org.junit.Test
import org.junit.Assert.assertEquals
import java.lang.RuntimeException
import java.util.WeakHashMap

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE)
class LogTest {

    fun writeTestLog(m: String) {
        LibRustLogAdapter.INSTANCE.rc_log_adapter_test__log_msg(m)
        Thread.sleep(100) // Wait for it to arrive...
    }

    // This should be split up now that we can re-enable after disabling
    // (note that it will still need to run sequentially!)
    @Test
    fun testLogging() {
        Megazord.init()
        val logs: MutableList<String> = mutableListOf()
        val threadIds = mutableSetOf<Long>()
        val threads = WeakHashMap<Thread, Long>()
        fun handler(level: Int, tag: String?, msg: String) {
            val threadId = Thread.currentThread().id
            threads.set(Thread.currentThread(), threadId)
            threadIds.add(threadId)
            val info = "Rust log from $threadId | Level: $level | tag: $tag| message: $msg"
            println(info)
            logs += info
        }

        assert(!RustLogAdapter.isEnabled)

        RustLogAdapter.enable { level, tagStr, msgStr ->
            handler(level, tagStr, msgStr)
            true
        }

        // We log an informational message after initializing (but it's processed asynchronously).
        Thread.sleep(100)
        assertEquals(logs.size, 1)
        writeTestLog("Test1")
        assertEquals(logs.size, 2)
        assert(RustLogAdapter.isEnabled)

        // Check that trying to enable again throws
        try {
            RustLogAdapter.enable { _, _, _ -> true }
        } catch (e: LogAdapterCannotEnable) {
        }

        var wasCalled = false

        val didEnable = RustLogAdapter.tryEnable { _, _, _ ->
            wasCalled = true
            true
        }

        assert(!didEnable)
        writeTestLog("Test2")

        assertEquals(logs.size, 3)
        assert(!wasCalled)

        for (i in 0..15) {
            Thread.sleep(10)
            System.gc()
        }
        // Make sure GC can't collect our background thread (we're still using it)
        assertEquals(threads.size, 1)

        // Adjust the max level so that the test log (which is logged at info level)
        // will not be present.
        RustLogAdapter.setMaxLevel(LogLevelFilter.WARN)

        writeTestLog("Test3")

        assertEquals(logs.size, 3)

        // Make sure we can re-enable it
        RustLogAdapter.setMaxLevel(LogLevelFilter.INFO)
        writeTestLog("Test4")

        assertEquals(logs.size, 4)
        // All the previous calls should have been run on the same background thread
        assertEquals(threadIds.size, 1)

        RustLogAdapter.disable()
        assert(!RustLogAdapter.isEnabled)

        // Shouldn't do anything, we disabled the log.
        writeTestLog("Test5")

        assertEquals(logs.size, 4)
        assert(!wasCalled)

        val didEnable2 = RustLogAdapter.tryEnable { level, tagStr, msgStr ->
            handler(level, tagStr, msgStr)
            wasCalled = true
            true
        }
        Thread.sleep(100)
        assert(didEnable2)
        assertEquals(logs.size, 5)

        writeTestLog("Test6")
        assert(wasCalled)
        assertEquals(logs.size, 6)

        // We called `enable` again, so we expect to have used another thread

        // TODO: changing to indirect binding has chnged how JNA allocates threads
        // for our callbacks, and has this next line fail. We should change it back
        // once things are back to normal. Ditto for commented out lines below labeled
        // assertEquals(threadIds.size, 2) // INDIRECT

        RustLogAdapter.disable()

        // Check behavior of 'disable by returning false'
        RustLogAdapter.enable { level, tagStr, msgStr ->
            handler(level, tagStr, msgStr)
            // Stop after we log twice
            logs.size < 8
        }
        Thread.sleep(100)
        // Initial log emitted when we set the adapter.
        assertEquals(logs.size, 7)
        writeTestLog("Test7")
        assertEquals(logs.size, 8)
        assert(!RustLogAdapter.isEnabled)

        // new log callback, new thread.
        // assertEquals(threadIds.size, 3) // INDIRECT

        // Check behavior of 'disable by throw'
        RustLogAdapter.enable { level, tagStr, msgStr ->
            handler(level, tagStr, msgStr)
            if (logs.size >= 10) {
                throw RuntimeException("Throw an exception to stop logging")
            }
            true
        }
        Thread.sleep(100)
        // Initial log emitted when we set the adapter.
        assertEquals(logs.size, 9)

        writeTestLog("Test8")
        assertEquals(logs.size, 10)
        assert(!RustLogAdapter.isEnabled)

        // new log callback, new thread.
        // assertEquals(threadIds.size, 4) // INDIRECT

        // Clean up
        RustLogAdapter.disable()

        // Make sure the GC can now collect the background threads.
        for (i in 0..15) {
            Thread.sleep(10)
            System.gc()
        }
        // assertEquals(threads.size, 0) // INDIRECT
        assertEquals(threads.size, 1)
    }
}
