/* Any copyright is dedicated to the Public Domain.
   http://creativecommons.org/publicdomain/zero/1.0/ */

package mozilla.appservices.logins

import org.junit.Test
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail

abstract class LoginsStorageTest {

    abstract fun createTestStore(): LoginsStorage

    protected val encryptionKey = "testEncryptionKey"

    protected fun getTestStore(): LoginsStorage {
        val store = createTestStore()

        store.unlock(encryptionKey)

        store.add(ServerPassword(
                id = "aaaaaaaaaaaa",
                hostname = "https://www.example.com",
                httpRealm = "Something",
                username = "Foobar2000",
                password = "hunter2",
                usernameField = "users_name",
                passwordField = "users_password"
        ))

        store.add(ServerPassword(
                id = "bbbbbbbbbbbb",
                username = "Foobar2000",
                hostname = "https://www.example.org",
                formSubmitURL = "https://www.example.org/login",
                password = "MyVeryCoolPassword",
                usernameField = "users_name",
                passwordField = "users_password"
        ))

        store.lock()
        return store
    }

    protected fun finishAndClose(store: LoginsStorage) {
        store.ensureLocked()
        assertEquals(store.isLocked(), true)
        store.close()
    }

    protected inline fun <T : Any?, reified E : Throwable> expectException(klass: Class<E>, callback: () -> T) {
        try {
            callback()
            fail("Expected exception!")
        } catch (e: Throwable) {
            assert(klass.isInstance(e), { "Expected $klass but got exception of type ${e.javaClass}: $e" })
        }
    }

    @Test
    fun testLockedOperations() {
        val test = getTestStore()
        assertEquals(test.isLocked(), true)

        expectException(LoginsStorageException::class.java) { test.get("aaaaaaaaaaaa") }
        expectException(LoginsStorageException::class.java) { test.list() }
        expectException(LoginsStorageException::class.java) { test.delete("aaaaaaaaaaaa") }
        expectException(LoginsStorageException::class.java) { test.touch("bbbbbbbbbbbb") }
        expectException(LoginsStorageException::class.java) { test.wipe() }
        expectException(LoginsStorageException::class.java) { test.sync(SyncUnlockInfo("", "", "", "")) }
        expectException(LoginsStorageException::class.java) {
            @Suppress("DEPRECATION")
            test.reset()
        }

        test.unlock(encryptionKey)
        assertEquals(test.isLocked(), false)
        // Make sure things didn't change despite being locked
        assertNotNull(test.get("aaaaaaaaaaaa"))
        // "bbbbbbbbbbbb" has a single use (from insertion)
        assertEquals(1, test.get("bbbbbbbbbbbb")!!.timesUsed)
        finishAndClose(test)
    }

    @Test
    fun testEnsureLockUnlock() {
        val test = getTestStore()
        assertEquals(test.isLocked(), true)

        test.ensureUnlocked(encryptionKey)
        assertEquals(test.isLocked(), false)
        test.ensureUnlocked(encryptionKey)
        assertEquals(test.isLocked(), false)

        test.ensureLocked()
        assertEquals(test.isLocked(), true)
        test.ensureLocked()
        assertEquals(test.isLocked(), true)

        finishAndClose(test)
    }

    @Test
    fun testTouch() {
        val test = getTestStore()
        test.unlock(encryptionKey)
        assertEquals(test.list().size, 2)
        val b = test.get("bbbbbbbbbbbb")!!

        // Wait 100ms so that touch is certain to change timeLastUsed.
        Thread.sleep(100)
        test.touch("bbbbbbbbbbbb")

        val newB = test.get("bbbbbbbbbbbb")

        assertNotNull(newB)
        assertEquals(b.timesUsed + 1, newB!!.timesUsed)
        assert(newB.timeLastUsed > b.timeLastUsed)

        expectException(NoSuchRecordException::class.java) { test.touch("abcdabcdabcd") }

        finishAndClose(test)
    }

    @Test
    fun testDelete() {
        val test = getTestStore()

        test.unlock(encryptionKey)
        assertNotNull(test.get("aaaaaaaaaaaa"))
        assertTrue(test.delete("aaaaaaaaaaaa"))
        assertNull(test.get("aaaaaaaaaaaa"))
        assertFalse(test.delete("aaaaaaaaaaaa"))
        assertNull(test.get("aaaaaaaaaaaa"))

        finishAndClose(test)
    }

    @Test
    fun testListWipe() {
        val test = getTestStore()
        test.unlock(encryptionKey)
        assertEquals(2, test.list().size)

        test.wipe()
        assertEquals(0, test.list().size)

        assertNull(test.get("aaaaaaaaaaaa"))
        assertNull(test.get("bbbbbbbbbbbb"))

        finishAndClose(test)
    }

    @Test
    fun testWipeLocal() {
        val test = getTestStore()
        test.unlock(encryptionKey)
        assertEquals(2, test.list().size)

        test.wipeLocal()
        assertEquals(0, test.list().size)

        assertNull(test.get("aaaaaaaaaaaa"))
        assertNull(test.get("bbbbbbbbbbbb"))

        finishAndClose(test)
    }

    @Test
    fun testAdd() {
        val test = getTestStore()
        test.unlock(encryptionKey)

        expectException(IdCollisionException::class.java) {
            test.add(ServerPassword(
                    id = "aaaaaaaaaaaa",
                    hostname = "https://www.foo.org",
                    httpRealm = "Some Realm",
                    password = "MyPassword",
                    username = "MyUsername",
                    usernameField = "",
                    passwordField = ""
            ))
        }

        for (record in INVALID_RECORDS) {
            expectException(InvalidRecordException::class.java) {
                test.add(record)
            }
        }

        val toInsert = ServerPassword(
                id = "",
                hostname = "https://www.foo.org",
                httpRealm = "Some Realm",
                password = "MyPassword",
                username = "Foobar2000",
                usernameField = "",
                passwordField = ""
        )

        val generatedID = test.add(toInsert)

        val record = test.get(generatedID)!!
        assertEquals(generatedID, record.id)
        assertEquals(toInsert.hostname, record.hostname)
        assertEquals(toInsert.httpRealm, record.httpRealm)
        assertEquals(toInsert.password, record.password)
        assertEquals(toInsert.username, record.username)
        assertEquals(toInsert.passwordField, record.passwordField)
        assertEquals(toInsert.usernameField, record.usernameField)
        assertEquals(toInsert.formSubmitURL, record.formSubmitURL)
        assertEquals(1, record.timesUsed)

        assertNotEquals(0L, record.timeLastUsed)
        assertNotEquals(0L, record.timeCreated)
        assertNotEquals(0L, record.timePasswordChanged)

        val specificID = test.add(ServerPassword(
                id = "123412341234",
                hostname = "http://www.bar.com",
                formSubmitURL = "http://login.bar.com",
                password = "DummyPassword",
                username = "DummyUsername",
                usernameField = "users_name",
                passwordField = "users_password"
        ))

        assertEquals("123412341234", specificID)

        finishAndClose(test)
    }

    @Test
    fun testEnsureValid() {
        val test = getTestStore()
        test.unlock(encryptionKey)

        test.add(ServerPassword(
                id = "bbbbb",
                hostname = "https://www.foo.org",
                httpRealm = "Some Realm",
                password = "MyPassword",
                username = "MyUsername",
                usernameField = "",
                passwordField = ""
        ))

        val dupeLogin = ServerPassword(
                id = "",
                hostname = "https://www.foo.org",
                httpRealm = "Some Realm",
                password = "MyPassword",
                username = "MyUsername",
                usernameField = "",
                passwordField = ""
        )

        val nullValueLogin = ServerPassword(
                id = "",
                hostname = "https://www.test.org",
                httpRealm = "Some Other Realm",
                password = "MyPassword",
                username = "\u0000MyUsername2",
                usernameField = "",
                passwordField = ""
        )

        expectException(InvalidRecordException::class.java) {
            test.ensureValid(dupeLogin)
        }

        expectException(InvalidRecordException::class.java) {
            test.ensureValid(nullValueLogin)
        }

        test.delete("bbbbb")
    }

    @Test
    fun testUpdate() {
        val test = getTestStore()
        test.unlock(encryptionKey)

        expectException(NoSuchRecordException::class.java) {
            test.update(ServerPassword(
                    id = "123412341234",
                    hostname = "https://www.foo.org",
                    httpRealm = "Some Realm",
                    password = "MyPassword",
                    username = "MyUsername",
                    usernameField = "",
                    passwordField = ""
            ))
        }

        for (record in INVALID_RECORDS) {
            val updateArg = record.copy(id = "aaaaaaaaaaaa")
            expectException(InvalidRecordException::class.java) {
                test.update(updateArg)
            }
        }

        val toUpdate = test.get("aaaaaaaaaaaa")!!.copy(
                password = "myNewPassword"
        )

        // Sleep so that the current time for test.update is guaranteed to be
        // different.
        Thread.sleep(100)

        test.update(toUpdate)

        val record = test.get(toUpdate.id)!!
        assertEquals(toUpdate.hostname, record.hostname)
        assertEquals(toUpdate.httpRealm, record.httpRealm)
        assertEquals(toUpdate.password, record.password)
        assertEquals(toUpdate.username, record.username)
        assertEquals(toUpdate.passwordField, record.passwordField)
        assertEquals(toUpdate.usernameField, record.usernameField)
        assertEquals(toUpdate.formSubmitURL, record.formSubmitURL)
        assertEquals(toUpdate.timesUsed + 1, record.timesUsed)
        assertEquals(toUpdate.timeCreated, record.timeCreated)

        assert(toUpdate.timeLastUsed < record.timeLastUsed)

        assert(toUpdate.timeLastUsed < record.timeLastUsed)
        assert(toUpdate.timeLastUsed < record.timePasswordChanged)

        val specificID = test.add(ServerPassword(
                id = "123412341234",
                hostname = "http://www.bar.com",
                formSubmitURL = "http://login.bar.com",
                password = "DummyPassword",
                username = "DummyUsername",
                usernameField = "users_name",
                passwordField = "users_password"
        ))

        assertEquals("123412341234", specificID)

        finishAndClose(test)
    }

    @Test
    @Suppress("DEPRECATION")
    fun testUnlockAfterError() {
        val test = getTestStore()

        expectException(LoginsStorageException::class.java) {
            test.reset()
        }

        test.unlock(encryptionKey)

        test.reset()

        finishAndClose(test)
    }

    companion object {
        val INVALID_RECORDS: List<ServerPassword> = listOf(
                // Invalid formSubmitURL
                ServerPassword(
                        id = "",
                        hostname = "https://www.foo.org",
                        formSubmitURL = "invalid\u0000value",
                        password = "MyPassword",
                        username = "MyUsername",
                        usernameField = "users_name",
                        passwordField = "users_password"
                ),
                // Neither formSubmitURL nor httpRealm
                ServerPassword(
                        id = "",
                        hostname = "https://www.foo.org",
                        password = "MyPassword",
                        username = "MyUsername",
                        usernameField = "",
                        passwordField = ""
                ),
                // Empty password
                ServerPassword(
                        id = "",
                        hostname = "https://www.foo.org",
                        httpRealm = "Some Realm",
                        password = "",
                        username = "MyUsername",
                        usernameField = "",
                        passwordField = ""
                ),
                // Empty hostname
                ServerPassword(
                        id = "",
                        hostname = "",
                        httpRealm = "Some Realm",
                        password = "MyPassword",
                        username = "MyUsername",
                        usernameField = "",
                        passwordField = ""
                )
        )
    }
}
