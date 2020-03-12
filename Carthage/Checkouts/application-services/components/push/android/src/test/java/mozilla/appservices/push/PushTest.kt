package mozilla.appservices.push

import mozilla.appservices.Megazord
import org.junit.rules.TemporaryFolder
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.Assert.assertEquals
import java.nio.charset.Charset

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE)
class PushTest {
    @Rule
    @JvmField
    val tmpFolder = TemporaryFolder()

    lateinit var dbFile: String

    @Before
    fun initDB() {
        Megazord.init()
        dbFile = tmpFolder.newFile().toString()
    }

    protected val private_key_raw = "MHcCAQEEIKiZMcVhlVccuwSr62jWN4YPBrPmPKotJUWl1id0d2ifoAoGCCq" +
            "GSM49AwEHoUQDQgAEFwl1-zUa0zLKYVO23LqUgZZEVesS0k_jQN_SA69ENHgPwIpWCoTq-VhHu0JiSwhF0o" +
            "PUzEM-FBWYoufO6J97nQ"
    protected val auth_raw = "LsuUOBKVQRY6-l7_Ajo-Ag"
    protected val public_key_raw = "BBcJdfs1GtMyymFTtty6lIGWRFXrEtJP40Df0gOvRDR4D8CKVgqE6vlYR7tC" +
            "YksIRdKD1MxDPhQVmKLnzuife50"

    // This is the older, but still used message encryption format.
    // this does not use mock calls.
    protected val aesgcmBlock = hashMapOf(
            "body" to "BNKu5uTFhjyS-06eECU9-6O61int3Rr7ARbm-xPhFuyDO5sfxVs-HywGaVonvzkarvfvXE9IR" +
                    "T_YNA81Og2uSqDasdMuwqm1zd0O3f7049IkQep3RJ2pEZTy5DqvI7kwMLDLzea9nroq3EMH5hYh" +
                    "vQtQgtKXeWieEL_3yVDQVg",
            "dh" to "dh=BMOebOMWSRisAhWpRK9ZPszJC8BL9MiWvLZBoBU6pG6Kh6vUFSW4BHFMh0b83xCg3_7IgfQZ" +
                    "XwmVuyu27vwiv5c",
            "salt" to "salt=tSf2qu43C9BD0zkvRW5eUg",
            "enc" to "aesgcm"
    )

    // This is the offical WebPush encryption format.
    // this does not use mock calls.
    protected val aes128gcmBlock = hashMapOf(
            "body" to "Ek7iQgliMqS9kjFoiVOqRgAAEABBBFirfBtF6XTeHVPABFDveb1iu7uO1XVA_MYJeAo-4ih8W" +
                    "YUsXSTIYmkKMv5_UB3tZuQI7BQ2EVpYYQfvOCrWZVMRL8fJCuB5wVXcoRoTaFJwTlJ5hnw6IMSi" +
                    "aMqGVlc8drX7Hzy-ugzzAKRhGPV2x-gdsp58DZh9Ww5vHpHyT1xwVkXzx3KTyeBZu4gl_zR0Q00" +
                    "li17g0xGsE6Dg3xlkKEmaalgyUyObl6_a8RA6Ko1Rc6RhAy2jdyY1LQbBUnA",
            "dh" to "",
            "salt" to "",
            "enc" to "aes128gcm"
    )
    protected val plaintext = "Amidst the mists and coldest frosts I thrust my fists against the" +
            "\nposts and still demand to see the ghosts.\n\n"

    protected val testChannelid = "deadbeef00000000decafbad00000000"

    /* Due to the nature of webpush (the fact that it uses systems outside of our control) it may
    not be possible to do actual tests using the remote systems. Any test using the following "mock"
    senderId will trigger 'hard wired' returns. These will exercise the Kotlin calling code.
    The Rust Cargo tests for the various push subcomponents do a more thorough test of the push
    code. I'd love to find a way to set a 'test' flag that rust can pick up, and be able to inline
    some of the mocking calls those use.
     */
    protected val mockSenderId = "test"

    protected val vapidPubKey = "BBCcCWavxjfIyW6NRhqclO9IZj9oW1gFKUBSgwcigfNcpXSfRk5JQTOcahMLjzO" +
            "1bkHMoiw4b6L7YTyF8foLEEU"

    protected fun getPushManager(): PushManager {
        return PushManager(
                senderId = mockSenderId,
                bridgeType = BridgeType.TEST,
                registrationId = "TestRegistrationId",
                databasePath = dbFile
        )
    }

    /* Usage:

        The push component is designed to be as light weight as possible. The "Push Manager"
        handles subscription management and message decryption.

        In general, usage would consist of calling:

        ```kotlin
        val manager = PushManager(
            senderId = "SomeSenderIDValue",
            bridgeType = BridgeType.FCM,
            registrationId = systemProvidedRegistrationValue,
            databasePath = "/path/to/database.sql"
        )
        val newEndpoints = manager.verifyConnection()
        if newEndpoints.length() > 0 {
            for (channelId in newEndpoints.keys()) {
                // send the endpoint (newEndpoint[channelId]) to the process tied to channelId
            }
        }

        // On new message:
        // A new incoming message generally has the following format:
        // {"chid": ChannelID, "body": Body, "con": Encoding, "enc": Salt, "crypto_key": DH}
        val decryptedMessage = manager.decrypt(
            channelID=message["chid"],
            body=message["body"],
            encoding=message["con"],
            salt=message.getOrElse("enc", ""),
            dh=message.getOrElse("crypto-key", "")
        )

        // On new subscription:
        val subscriptionInfo = manager.subscribe(channelID, scope)
            // the subscription info matches what is usually passed on to
            // the requesting application. This could be JSON encoded and returned.

        // On deleting a subscription:
        manger.unsubscribe(channelID)
            // returns true/false on server unsubscribe request. A False may cause a
            // verifyConnection() failure and new endpoints generation

        // On a new native OS registration ID change:
        manager.update(newSubscriptionID)
            // sets the new registration ID (sender ID) on the server. Returns a false if this
            // operation fails. A failure may prevent future messages from being received.

      ```
    */

    @Test
    fun testAesgcmDecryption() {
        val manager = getPushManager()
        // call this to set the (hardcoded) test key and auth
        manager.subscribe(testChannelid, "foo")

        // These values should come from the delivered message content.
        val result = manager.decrypt(
                channelID = testChannelid,
                body = aesgcmBlock["body"].toString(),
                encoding = aesgcmBlock["enc"].toString(),
                salt = aesgcmBlock["salt"].toString(),
                dh = aesgcmBlock["dh"].toString()
        )
        val sresult = result.toString(Charset.forName("UTF-8"))
        assertEquals("Result", plaintext, sresult)
    }

    @Test
    fun testAesgcmDecryption_bad() {
        val manager = getPushManager()
        // call this to set the (hardcoded) test key and auth
        manager.subscribe(testChannelid, "foo")

        // These values should come from the delivered message content.
        val result = manager.decrypt(
            channelID = testChannelid,
            body = aesgcmBlock["body"].toString(),
            encoding = aesgcmBlock["enc"].toString(),
            salt = aesgcmBlock["salt"].toString(),
            dh = aesgcmBlock["dh"].toString()
        )
        val sresult = result.toString(Charset.forName("UTF-8"))
        assertEquals("Result", plaintext, sresult)
    }

    @Test
    fun testAes128gcmDecryption() {
        val manager = getPushManager()
        // call this to set the (hardcoded) test key and auth
        manager.subscribe(testChannelid, "foo")
        val result = manager.decrypt(
                channelID = testChannelid,
                body = aes128gcmBlock["body"].toString(),
                encoding = aes128gcmBlock["enc"].toString(),
                salt = aes128gcmBlock["salt"].toString(),
                dh = aes128gcmBlock["dh"].toString()
        )
        val sresult = result.toString(Charset.forName("UTF-8"))
        assertEquals("Result", plaintext, sresult)
    }

    @Test
    fun testNewSubscription() {
        val manager = getPushManager()

        val subscriptionResponse = manager.subscribe(testChannelid, "foo")
        // These are mock values, but it's important that they exist.
        assertEquals("ChannelID Check", testChannelid, subscriptionResponse.channelID)
        assertEquals("Auth Check", auth_raw, subscriptionResponse.subscriptionInfo.keys.auth)
        assertEquals("p256 Check", public_key_raw, subscriptionResponse.subscriptionInfo.keys.p256dh)
        assertEquals("endpoint Check", "http://push.example.com/test/opaque",
            subscriptionResponse.subscriptionInfo.endpoint)
    }

    @Test
    fun testUnsubscribe() {
        val manager = getPushManager()
        manager.subscribe(testChannelid, "foo", vapidPubKey)
        val result = manager.unsubscribe(testChannelid)
        assertEquals("Unsubscription check", true, result)
    }

    @Test
    fun testUpdate() {
        val manager = getPushManager()
        // subscribe to at least one channel.
        manager.subscribe(testChannelid, "foo")
        val result = manager.update("test-2")
        assertEquals("SenderID update", true, result)
    }

    @Test
    fun testVerifyConnection() {
        val manager = getPushManager()
        // Register a subscription
        manager.subscribe(testChannelid, "foo")
        // and call verifyConnection again to emulate a set value.
        val result = manager.verifyConnection()
        assertEquals("Endpoints updated", true, result.isNotEmpty())
        assertEquals("Endpoints updated", "foo", result.first().scope)
    }

    @Test
    fun testDispatchInfoForChid() {
        val manager = getPushManager()

        manager.subscribe(testChannelid, "foo", vapidPubKey)
        val dispatch = manager.dispatchInfoForChid(testChannelid)!!
        assertEquals("uaid", "abad1d3a00000000aabbccdd00000000", dispatch.uaid)
        assertEquals("scope", "foo", dispatch.scope)
        assert(dispatch.endpoint.length > 0)
        assertEquals(dispatch.appServerKey, vapidPubKey)
    }

    @Test
    fun testValidPath() {
        try {
            PushManager(
                senderId = mockSenderId,
                bridgeType = BridgeType.TEST,
                registrationId = "TestRegistrationId",
                databasePath = "/dev/false"
            )
        } catch (e: PushError) {
            assert(e is StorageError)
        }
    }

    @Test
    fun testDuplicateSubscription() {
        val manager = getPushManager()

        val response1 = manager.subscribe(testChannelid, "foo")
        val response2 = manager.subscribe(testChannelid, "foo")
        assertEquals(response1.channelID, response2.channelID)
        assertEquals(response1.subscriptionInfo.endpoint, response2.subscriptionInfo.endpoint)
        assertEquals(response1.subscriptionInfo.keys.auth, response2.subscriptionInfo.keys.auth)
        assertEquals(response1.subscriptionInfo.keys.p256dh, response2.subscriptionInfo.keys.p256dh)
    }
}
