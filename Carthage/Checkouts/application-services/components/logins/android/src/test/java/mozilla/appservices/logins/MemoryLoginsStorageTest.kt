/* Any copyright is dedicated to the Public Domain.
   http://creativecommons.org/publicdomain/zero/1.0/ */

package mozilla.appservices.logins

import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE)
@Suppress("DEPRECATION")
class MemoryLoginsStorageTest : LoginsStorageTest() {

    override fun createTestStore(): LoginsStorage {
        return MemoryLoginsStorage(listOf())
    }
}
