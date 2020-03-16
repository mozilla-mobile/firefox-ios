/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.places

import com.sun.jna.Native
import com.sun.jna.Pointer
import com.sun.jna.StringArray
import mozilla.appservices.support.native.toNioDirectBuffer
import mozilla.appservices.sync15.SyncTelemetryPing
import org.json.JSONArray
import org.json.JSONObject
import org.json.JSONException
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicReference
import java.lang.ref.WeakReference
import org.mozilla.appservices.places.GleanMetrics.PlacesManager as PlacesManagerMetrics

/**
 * Import some private Glean types, so that we can use them in type declarations.
 *
 * By agreement with the Glean team, we must not
 * instantiate anything from these classes, and it's on us to fix any bustage
 * on version updates.
 */
import mozilla.components.service.glean.private.CounterMetricType
import mozilla.components.service.glean.private.TimingDistributionMetricType
import mozilla.components.service.glean.private.LabeledMetricType

/**
 * An implementation of a [PlacesManager] backed by a Rust Places library.
 *
 * This type, as well as all connection types, are thread safe (they perform locking internally
 * where necessary).
 *
 * @param path an absolute path to a file that will be used for the internal database.
 */
class PlacesApi(path: String) : PlacesManager, AutoCloseable {
    private var handle: AtomicLong = AtomicLong(0)
    private var writeConn: PlacesWriterConnection

    init {
        handle.set(rustCall(this) { error ->
            LibPlacesFFI.INSTANCE.places_api_new(path, error)
        })
        writeConn = PlacesWriterConnection(rustCall(this) { error ->
            LibPlacesFFI.INSTANCE.places_connection_new(handle.get(), READ_WRITE, error)
        }, this)
    }

    companion object {
        // These numbers come from `places::db::ConnectionType`
        private const val READ_ONLY: Int = 1
        private const val READ_WRITE: Int = 2
    }

    /**
     * Return the raw handle used to reference this PlacesApi.
     *
     * Generally should only be used to pass the handle into `SyncManager.setPlaces`
     */
    fun getHandle(): Long {
        return this.handle.get()
    }

    override fun openReader(): PlacesReaderConnection {
        val connHandle = rustCall(this) { error ->
            LibPlacesFFI.INSTANCE.places_connection_new(handle.get(), READ_ONLY, error)
        }
        return PlacesReaderConnection(connHandle)
    }

    override fun getWriter(): PlacesWriterConnection {
        return writeConn
    }

    @Synchronized
    override fun close() {
        // Take the write connection's handle and clear its reference to us.
        val writeHandle = this.writeConn.takeHandle()
        this.writeConn.apiRef.clear()
        val handle = this.handle.getAndSet(0L)
        if (handle != 0L) {
            if (writeHandle != 0L) {
                try {
                    rustCall(this) { err ->
                        LibPlacesFFI.INSTANCE.places_api_return_write_conn(handle, writeHandle, err)
                    }
                } catch (e: PlacesException) {
                    // Ignore it.
                }
            }
            rustCall(this) { error ->
                LibPlacesFFI.INSTANCE.places_api_destroy(handle, error)
            }
        }
    }

    override fun syncHistory(syncInfo: SyncAuthInfo): SyncTelemetryPing {
        val pingJSONString = rustCallForString(this) { error ->
            LibPlacesFFI.INSTANCE.sync15_history_sync(
                    this.handle.get(),
                    syncInfo.kid,
                    syncInfo.fxaAccessToken,
                    syncInfo.syncKey,
                    syncInfo.tokenserverURL,
                    error
            )
        }
        return SyncTelemetryPing.fromJSONString(pingJSONString)
    }

    override fun syncBookmarks(syncInfo: SyncAuthInfo): SyncTelemetryPing {
        val pingJSONString = rustCallForString(this) { error ->
            LibPlacesFFI.INSTANCE.sync15_bookmarks_sync(
                    this.handle.get(),
                    syncInfo.kid,
                    syncInfo.fxaAccessToken,
                    syncInfo.syncKey,
                    syncInfo.tokenserverURL,
                    error
            )
        }
        return SyncTelemetryPing.fromJSONString(pingJSONString)
    }

    override fun importBookmarksFromFennec(path: String): JSONObject {
        val json = rustCallForString(this) { error ->
            LibPlacesFFI.INSTANCE.places_bookmarks_import_from_fennec(this.handle.get(), path, error)
        }
        return JSONObject(json)
    }

    override fun importPinnedSitesFromFennec(path: String): List<BookmarkItem> {
        val rustBuf = rustCall(this) { error ->
            LibPlacesFFI.INSTANCE.places_pinned_sites_import_from_fennec(
                this.handle.get(), path, error)
        }

        try {
            val message = MsgTypes.BookmarkNodeList.parseFrom(rustBuf.asCodedInputStream()!!)
            return unpackProtobufItemList(message)
        } finally {
            LibPlacesFFI.INSTANCE.places_destroy_bytebuffer(rustBuf)
        }
    }

    override fun importVisitsFromFennec(path: String): JSONObject {
        val json = rustCallForString(this) { error ->
            LibPlacesFFI.INSTANCE.places_history_import_from_fennec(this.handle.get(), path, error)
        }
        return JSONObject(json)
    }

    override fun resetHistorySyncMetadata() {
        rustCall(this) { error ->
            LibPlacesFFI.INSTANCE.places_reset(this.handle.get(), error)
        }
    }

    override fun resetBookmarkSyncMetadata() {
        rustCall(this) { error ->
            LibPlacesFFI.INSTANCE.bookmarks_reset(this.handle.get(), error)
        }
    }
}

internal inline fun <U> rustCall(syncOn: Any, callback: (RustError.ByReference) -> U): U {
    synchronized(syncOn) {
        val e = RustError.ByReference()
        val ret: U = callback(e)
        if (e.isFailure()) {
            throw e.intoException()
        } else {
            return ret
        }
    }
}

@Suppress("TooGenericExceptionThrown")
internal inline fun rustCallForString(syncOn: Any, callback: (RustError.ByReference) -> Pointer?): String {
    val cstring = rustCall(syncOn, callback)
            ?: throw RuntimeException("Bug: Don't use this function when you can return" +
                    " null on success.")
    try {
        return cstring.getString(0, "utf8")
    } finally {
        LibPlacesFFI.INSTANCE.places_destroy_string(cstring)
    }
}

internal inline fun rustCallForOptString(syncOn: Any, callback: (RustError.ByReference) -> Pointer?): String? {
    val cstring = rustCall(syncOn, callback)
    try {
        return cstring?.getString(0, "utf8")
    } finally {
        cstring?.let { LibPlacesFFI.INSTANCE.places_destroy_string(it) }
    }
}

@Suppress("TooGenericExceptionCaught")
open class PlacesConnection internal constructor(connHandle: Long) : InterruptibleConnection, AutoCloseable {
    protected var handle: AtomicLong = AtomicLong(0)
    protected var interruptHandle: InterruptHandle

    init {
        handle.set(connHandle)
        try {
            interruptHandle = InterruptHandle(rustCall { err ->
                LibPlacesFFI.INSTANCE.places_new_interrupt_handle(connHandle, err)
            }!!)
        } catch (e: Throwable) {
            rustCall { error ->
                LibPlacesFFI.INSTANCE.places_connection_destroy(this.handle.getAndSet(0), error)
            }
            throw e
        }
    }

    @Synchronized
    protected fun destroy() {
        val handle = this.handle.getAndSet(0L)
        if (handle != 0L) {
            rustCall { error ->
                LibPlacesFFI.INSTANCE.places_connection_destroy(handle, error)
            }
        }
        interruptHandle.close()
    }

    @Synchronized
    override fun close() {
        destroy()
    }

    override fun interrupt() {
        this.interruptHandle.interrupt()
    }

    internal inline fun <U> rustCall(callback: (RustError.ByReference) -> U): U {
        return rustCall(this, callback)
    }

    internal inline fun rustCallForString(callback: (RustError.ByReference) -> Pointer?): String {
        return rustCallForString(this, callback)
    }

    internal inline fun rustCallForOptString(callback: (RustError.ByReference) -> Pointer?): String? {
        return rustCallForOptString(this, callback)
    }
}

/**
 * An implementation of a [ReadableHistoryConnection], used for read-only
 * access to places APIs.
 *
 * This class is thread safe.
 */
open class PlacesReaderConnection internal constructor(connHandle: Long) :
        PlacesConnection(connHandle),
        ReadableHistoryConnection,
        ReadableBookmarksConnection {
    override fun queryAutocomplete(query: String, limit: Int): List<SearchResult> {
        val resultBuffer = rustCall { error ->
            LibPlacesFFI.INSTANCE.places_query_autocomplete(this.handle.get(), query, limit, error)
        }
        try {
            val results = MsgTypes.SearchResultList.parseFrom(resultBuffer.asCodedInputStream()!!)
            return SearchResult.fromCollectionMessage(results)
        } finally {
            LibPlacesFFI.INSTANCE.places_destroy_bytebuffer(resultBuffer)
        }
    }

    override fun matchUrl(query: String): String? {
        return rustCallForOptString { error ->
            LibPlacesFFI.INSTANCE.places_match_url(this.handle.get(), query, error)
        }
    }

    override fun getVisited(urls: List<String>): List<Boolean> {
        // Note urlStrings has a potential footgun in that StringArray has a `size()` method
        // which returns the size *in bytes*. Hence us using urls.size (which is an element count)
        // for the actual number of urls!
        val urlStrings = StringArray(urls.toTypedArray(), "utf8")
        val byteBuffer = ByteBuffer.allocateDirect(urls.size)
        byteBuffer.order(ByteOrder.nativeOrder())
        readQueryCounters.measure {
            rustCall { error ->
                val bufferPtr = Native.getDirectBufferPointer(byteBuffer)
                PlacesManagerMetrics.readQueryTime.measure {
                    LibPlacesFFI.INSTANCE.places_get_visited(
                            this.handle.get(),
                            urlStrings, urls.size,
                            bufferPtr, urls.size,
                            error
                    )
                }
            }
        }
        val result = ArrayList<Boolean>(urls.size)
        for (index in 0 until urls.size) {
            val wasVisited = byteBuffer.get(index)
            if (wasVisited != 0.toByte() && wasVisited != 1.toByte()) {
                throw java.lang.RuntimeException(
                        "Places bug! Memory corruption possible! Report me!")
            }
            result.add(wasVisited == 1.toByte())
        }
        return result
    }

    override fun getVisitedUrlsInRange(start: Long, end: Long, includeRemote: Boolean): List<String> {
        val urlsJson = rustCallForString { error ->
            val incRemoteArg: Byte = if (includeRemote) { 1 } else { 0 }
            LibPlacesFFI.INSTANCE.places_get_visited_urls_in_range(
                    this.handle.get(), start, end, incRemoteArg, error)
        }
        val arr = JSONArray(urlsJson)
        val result = mutableListOf<String>()
        for (idx in 0 until arr.length()) {
            result.add(arr.getString(idx))
        }
        return result
    }

    override fun getVisitInfos(start: Long, end: Long, excludeTypes: List<VisitType>): List<VisitInfo> {
        readQueryCounters.measure {
            val infoBuffer = rustCall { error ->
                PlacesManagerMetrics.readQueryTime.measure {
                    LibPlacesFFI.INSTANCE.places_get_visit_infos(
                            this.handle.get(), start, end, visitTransitionSet(excludeTypes), error)
                }
            }
            try {
                val infos = MsgTypes.HistoryVisitInfos.parseFrom(infoBuffer.asCodedInputStream()!!)
                return VisitInfo.fromMessage(infos)
            } finally {
                LibPlacesFFI.INSTANCE.places_destroy_bytebuffer(infoBuffer)
            }
        }
    }

    override fun getVisitPage(offset: Long, count: Long, excludeTypes: List<VisitType>): List<VisitInfo> {
        val infoBuffer = rustCall { error ->
            LibPlacesFFI.INSTANCE.places_get_visit_page(
                    this.handle.get(), offset, count, visitTransitionSet(excludeTypes), error)
        }
        try {
            val infos = MsgTypes.HistoryVisitInfos.parseFrom(infoBuffer.asCodedInputStream()!!)
            return VisitInfo.fromMessage(infos)
        } finally {
            LibPlacesFFI.INSTANCE.places_destroy_bytebuffer(infoBuffer)
        }
    }

    override fun getVisitPageWithBound(
        bound: Long,
        offset: Long,
        count: Long,
        excludeTypes: List<VisitType>
    ): VisitInfosWithBound {
        val infoBuffer = rustCall { error ->
            LibPlacesFFI.INSTANCE.places_get_visit_page_with_bound(
                    this.handle.get(), offset, bound, count, visitTransitionSet(excludeTypes), error)
        }
        try {
            val infos = MsgTypes.HistoryVisitInfosWithBound.parseFrom(infoBuffer.asCodedInputStream()!!)
            return VisitInfosWithBound.fromMessage(infos)
        } finally {
            LibPlacesFFI.INSTANCE.places_destroy_bytebuffer(infoBuffer)
        }
    }

    override fun getVisitCount(excludeTypes: List<VisitType>): Long {
        return rustCall { error ->
            LibPlacesFFI.INSTANCE.places_get_visit_count(
                    this.handle.get(), visitTransitionSet(excludeTypes), error)
        }
    }

    override fun getBookmark(guid: String): BookmarkTreeNode? {
        readQueryCounters.measure {
            val rustBuf = rustCall { err ->
                PlacesManagerMetrics.readQueryTime.measure {
                    LibPlacesFFI.INSTANCE.bookmarks_get_by_guid(this.handle.get(), guid, 0.toByte(), err)
                }
            }
            try {
                return rustBuf.asCodedInputStream()?.let { stream ->
                    unpackProtobuf(MsgTypes.BookmarkNode.parseFrom(stream))
                }
            } finally {
                LibPlacesFFI.INSTANCE.places_destroy_bytebuffer(rustBuf)
            }
        }
    }

    override fun getBookmarksTree(rootGUID: String, recursive: Boolean): BookmarkTreeNode? {
        val rustBuf = rustCall { err ->
            PlacesManagerMetrics.scanQueryTime.measure {
                if (recursive) {
                    LibPlacesFFI.INSTANCE.bookmarks_get_tree(this.handle.get(), rootGUID, err)
                } else {
                    LibPlacesFFI.INSTANCE.bookmarks_get_by_guid(this.handle.get(), rootGUID, 1.toByte(), err)
                }
            }
        }
        try {
            return rustBuf.asCodedInputStream()?.let { stream ->
                unpackProtobuf(MsgTypes.BookmarkNode.parseFrom(stream))
            }
        } finally {
            LibPlacesFFI.INSTANCE.places_destroy_bytebuffer(rustBuf)
        }
    }

    override fun getBookmarksWithURL(url: String): List<BookmarkItem> {
        readQueryCounters.measure {
            val rustBuf = rustCall { err ->
                PlacesManagerMetrics.readQueryTime.measure {
                    LibPlacesFFI.INSTANCE.bookmarks_get_all_with_url(this.handle.get(), url, err)
                }
            }

            try {
                val message = MsgTypes.BookmarkNodeList.parseFrom(rustBuf.asCodedInputStream()!!)
                return unpackProtobufItemList(message)
            } finally {
                LibPlacesFFI.INSTANCE.places_destroy_bytebuffer(rustBuf)
            }
        }
    }

    override fun getBookmarkUrlForKeyword(keyword: String): String? {
        return rustCallForOptString { error ->
            LibPlacesFFI.INSTANCE.bookmarks_get_url_for_keyword(this.handle.get(), keyword, error)
        }
    }

    override fun searchBookmarks(query: String, limit: Int): List<BookmarkItem> {
        readQueryCounters.measure {
            val rustBuf = rustCall { err ->
                PlacesManagerMetrics.readQueryTime.measure {
                    LibPlacesFFI.INSTANCE.bookmarks_search(this.handle.get(), query, limit, err)
                }
            }

            try {
                val message = MsgTypes.BookmarkNodeList.parseFrom(rustBuf.asCodedInputStream()!!)
                return unpackProtobufItemList(message)
            } finally {
                LibPlacesFFI.INSTANCE.places_destroy_bytebuffer(rustBuf)
            }
        }
    }

    override fun getRecentBookmarks(limit: Int): List<BookmarkItem> {
        readQueryCounters.measure {
            val rustBuf = rustCall { err ->
                PlacesManagerMetrics.readQueryTime.measure {
                    LibPlacesFFI.INSTANCE.bookmarks_get_recent(this.handle.get(), limit, err)
                }
            }

            try {
                val message = MsgTypes.BookmarkNodeList.parseFrom(rustBuf.asCodedInputStream()!!)
                return unpackProtobufItemList(message)
            } finally {
                LibPlacesFFI.INSTANCE.places_destroy_bytebuffer(rustBuf)
            }
        }
    }

    private val readQueryCounters: PlacesManagerCounterMetrics by lazy {
        PlacesManagerCounterMetrics(
            PlacesManagerMetrics.readQueryCount,
            PlacesManagerMetrics.readQueryErrorCount
        )
    }
}

fun visitTransitionSet(l: List<VisitType>): Int {
    var res = 0
    for (ty in l) {
        res = res or (1 shl ty.type)
    }
    return res
}

/**
 * An implementation of a [WritableHistoryConnection], use for read or write
 * access to the Places APIs.
 *
 * This class is thread safe.
 */
class PlacesWriterConnection internal constructor(connHandle: Long, api: PlacesApi) :
        PlacesReaderConnection(connHandle),
        WritableHistoryConnection,
        WritableBookmarksConnection {
    // The reference to our PlacesAPI. Mostly used to know how to handle getting closed.
    val apiRef = WeakReference(api)
    override fun noteObservation(data: VisitObservation) {
        val json = data.toJSON().toString()
        return writeQueryCounters.measure {
            rustCall { error ->
                PlacesManagerMetrics.writeQueryTime.measure {
                    LibPlacesFFI.INSTANCE.places_note_observation(this.handle.get(), json, error)
                }
            }
        }
    }

    override fun deletePlace(url: String) {
        return writeQueryCounters.measure {
            rustCall { error ->
                PlacesManagerMetrics.writeQueryTime.measure {
                    LibPlacesFFI.INSTANCE.places_delete_place(
                        this.handle.get(), url, error)
                }
            }
        }
    }

    override fun deleteVisit(url: String, visitTimestamp: Long) {
        return writeQueryCounters.measure {
            rustCall { error ->
                PlacesManagerMetrics.writeQueryTime.measure {
                    LibPlacesFFI.INSTANCE.places_delete_visit(
                            this.handle.get(), url, visitTimestamp, error)
                }
            }
        }
    }

    override fun deleteVisitsSince(since: Long) {
        deleteVisitsBetween(since, Long.MAX_VALUE)
    }

    override fun deleteVisitsBetween(startTime: Long, endTime: Long) {
        return writeQueryCounters.measure {
            rustCall { error ->
                PlacesManagerMetrics.writeQueryTime.measure {
                    LibPlacesFFI.INSTANCE.places_delete_visits_between(
                        this.handle.get(), startTime, endTime, error)
                }
            }
        }
    }

    override fun wipeLocal() {
        rustCall { error ->
            LibPlacesFFI.INSTANCE.places_wipe_local(this.handle.get(), error)
        }
    }

    override fun runMaintenance() {
        rustCall { error ->
            LibPlacesFFI.INSTANCE.places_run_maintenance(this.handle.get(), error)
        }
    }

    override fun pruneDestructively() {
        rustCall { error ->
            LibPlacesFFI.INSTANCE.places_prune_destructively(this.handle.get(), error)
        }
    }

    override fun deleteEverything() {
        return writeQueryCounters.measure {
            rustCall { error ->
                PlacesManagerMetrics.writeQueryTime.measure {
                    LibPlacesFFI.INSTANCE.places_delete_everything(this.handle.get(), error)
                }
            }
        }
    }

    override fun deleteAllBookmarks() {
        return writeQueryCounters.measure {
            rustCall { error ->
                PlacesManagerMetrics.writeQueryTime.measure {
                    LibPlacesFFI.INSTANCE.bookmarks_delete_everything(this.handle.get(), error)
                }
            }
        }
    }

    override fun deleteBookmarkNode(guid: String): Boolean {
        return writeQueryCounters.measure {
            rustCall { error ->
                val existedByte = PlacesManagerMetrics.writeQueryTime.measure {
                    LibPlacesFFI.INSTANCE.bookmarks_delete(this.handle.get(), guid, error)
                }
                existedByte.toInt() != 0
            }
        }
    }

    // Does the shared insert work, takes the position just because
    // its a little tedious to type out setting it
    private fun doInsert(builder: MsgTypes.BookmarkNode.Builder, position: Int?): String {
        position?.let { builder.setPosition(position) }
        val buf = builder.build()
        val (nioBuf, len) = buf.toNioDirectBuffer()
        writeQueryCounters.measure {
            return rustCallForString { err ->
                val ptr = Native.getDirectBufferPointer(nioBuf)
                PlacesManagerMetrics.writeQueryTime.measure {
                    LibPlacesFFI.INSTANCE.bookmarks_insert(this.handle.get(), ptr, len, err)
                }
            }
        }
    }

    override fun createFolder(parentGUID: String, title: String, position: Int?): String {
        val builder = MsgTypes.BookmarkNode.newBuilder()
                .setNodeType(BookmarkType.Folder.value)
                .setParentGuid(parentGUID)
                .setTitle(title)
        return this.doInsert(builder, position)
    }

    override fun createSeparator(parentGUID: String, position: Int?): String {
        val builder = MsgTypes.BookmarkNode.newBuilder()
                .setNodeType(BookmarkType.Separator.value)
                .setParentGuid(parentGUID)
        return this.doInsert(builder, position)
    }

    override fun createBookmarkItem(parentGUID: String, url: String, title: String, position: Int?): String {
        val builder = MsgTypes.BookmarkNode.newBuilder()
                .setNodeType(BookmarkType.Bookmark.value)
                .setParentGuid(parentGUID)
                .setUrl(url)
                .setTitle(title)
        return this.doInsert(builder, position)
    }

    override fun updateBookmark(guid: String, info: BookmarkUpdateInfo) {
        val buf = info.toProtobuf(guid)
        val (nioBuf, len) = buf.toNioDirectBuffer()
        return writeQueryCounters.measure {
            rustCall { err ->
                val ptr = Native.getDirectBufferPointer(nioBuf)
                PlacesManagerMetrics.writeQueryTime.measure {
                    LibPlacesFFI.INSTANCE.bookmarks_update(this.handle.get(), ptr, len, err)
                }
            }
        }
    }

    override fun acceptResult(searchString: String, url: String) {
        rustCall { error ->
            LibPlacesFFI.INSTANCE.places_accept_result(
                    this.handle.get(), searchString, url, error)
        }
    }

    @Synchronized
    override fun close() {
        // If our API is still around, do nothing.
        if (apiRef.get() == null) {
            // Otherwise, it must have gotten GCed without calling close() :(
            // So we go through the non-writer connection destructor.
            destroy()
        }
    }

    @Synchronized
    internal fun takeHandle(): PlacesConnectionHandle {
        val handle = this.handle.getAndSet(0L)
        interruptHandle.close()
        return handle
    }

    private val writeQueryCounters: PlacesManagerCounterMetrics by lazy {
        PlacesManagerCounterMetrics(
            PlacesManagerMetrics.writeQueryCount,
            PlacesManagerMetrics.writeQueryErrorCount
        )
    }
}

/**
 * A class for providing the auth-related information needed to sync.
 * Note that this has the same shape as `SyncUnlockInfo` from logins - we
 * probably want a way of sharing these.
 */
class SyncAuthInfo(
    val kid: String,
    val fxaAccessToken: String,
    val syncKey: String,
    val tokenserverURL: String
)

/**
 * An API for interacting with Places. This is the top-level entry-point, and
 * exposes functions which return lower-level objects with the core
 * functionality.
 */
interface PlacesManager {
    /**
     * Open a reader connection.
     */
    fun openReader(): ReadableHistoryConnection

    /**
     * Get a reference to the writer connection.
     *
     * This should always return the same object.
     */
    fun getWriter(): WritableHistoryConnection

    /**
     * Syncs the places history store, returning a telemetry ping.
     *
     * Note that this function blocks until the sync is complete, which may
     * take some time due to the network etc. Because only 1 thread can be
     * using a PlacesAPI at a time, it is recommended, but not enforced, that
     * you have all connections you intend using open before calling this.
     */
    fun syncHistory(syncInfo: SyncAuthInfo): SyncTelemetryPing

    /**
     * Syncs the places bookmarks store, returning a telemetry ping.
     *
     * Note that this function blocks until the sync is complete, which may
     * take some time due to the network etc. Because only 1 thread can be
     * using a PlacesAPI at a time, it is recommended, but not enforced, that
     * you have all connections you intend using open before calling this.
     */
    fun syncBookmarks(syncInfo: SyncAuthInfo): SyncTelemetryPing

    /**
     * Imports bookmarks from a Fennec `browser.db` database.
     *
     * It has been designed exclusively for non-sync users.
     *
     * @param path Path to the `browser.db` file database.
     * @return JSONObject with import metrics.
     */
    fun importBookmarksFromFennec(path: String): JSONObject

    /**
     * Imports visits from a Fennec `browser.db` database.
     *
     * It has been designed exclusively for non-sync users and should
     * be called before bookmarks import.
     *
     * @param path Path to the `browser.db` file database.
     * @return JSONObject with import metrics.
     */
    fun importVisitsFromFennec(path: String): JSONObject

    /**
     * Returns pinned sites from a Fennec `browser.db` bookmark database.
     *
     * Fennec used to store "pinned websites" as normal bookmarks
     * under an invisible root.
     * During import, this un-syncable root and its children are ignored,
     * so we return the pinned websites separately as a list so
     * Fenix can store them in a collection.
     *
     * @param path Path to the `browser.db` file database.
     * @return A list of pinned websites.
     */
    fun importPinnedSitesFromFennec(path: String): List<BookmarkItem>

    /**
     * Resets all sync metadata for history, including change flags,
     * sync statuses, and last sync time. The next sync after reset
     * will behave the same way as a first sync when connecting a new
     * device.
     *
     * This method only needs to be called when the user disconnects
     * from Sync. There are other times when Places resets sync metadata,
     * but those are handled internally in the Rust code.
     */
    fun resetHistorySyncMetadata()

    /**
     * Resets all sync metadata for bookmarks, including change flags,
     * sync statuses, and last sync time. The next sync after reset
     * will behave the same way as a first sync when connecting a new
     * device.
     *
     * This method only needs to be called when the user disconnects
     * from Sync. There are other times when Places resets sync metadata,
     * but those are handled internally in the Rust code.
     */
    fun resetBookmarkSyncMetadata()
}

interface InterruptibleConnection : AutoCloseable {
    /**
     * Interrupt ongoing operations running on a separate thread.
     */
    fun interrupt()
}

interface ReadableHistoryConnection : InterruptibleConnection {
    /**
     * A way to search the internal database tailored for autocompletion purposes.
     *
     * @param query a string to match results against.
     * @param limit a maximum number of results to retrieve.
     * @return a list of [SearchResult] matching the [query], in arbitrary order.
     */
    fun queryAutocomplete(query: String, limit: Int): List<SearchResult>

    /**
     * See if a url that's sufficiently close to `search` exists in
     * the database.
     *
     * @param query the search string
     * @return If no url exists, returns null. If one exists, it returns the next
     *         portion of it that definitely matches (where portion is defined
     *         something like 'complete origin or path segment')
     */
    fun matchUrl(query: String): String?

    /**
     * Maps a list of page URLs to a list of booleans indicating if each URL was visited.
     * @param urls a list of page URLs about which "visited" information is being requested.
     * @return a list of booleans indicating visited status of each
     * corresponding page URI from [urls].
     */
    fun getVisited(urls: List<String>): List<Boolean>

    /**
     * Returns a list of visited URLs for a given time range.
     *
     * @param start beginning of the range, unix timestamp in milliseconds.
     * @param end end of the range, unix timestamp in milliseconds.
     * @param includeRemote boolean flag indicating whether or not to include remote visits. A visit
     *  is (roughly) considered remote if it didn't originate on the current device.
     */
    fun getVisitedUrlsInRange(start: Long, end: Long = Long.MAX_VALUE, includeRemote: Boolean = true): List<String>

    /**
     * Get detailed information about all visits that occurred in the
     * given time range.
     *
     * @param start The (inclusive) start time to bound the query.
     * @param end The (inclusive) end time to bound the query.
     */
    fun getVisitInfos(
        start: Long,
        end: Long = Long.MAX_VALUE,
        excludeTypes: List<VisitType> = listOf()
    ): List<VisitInfo>

    /**
     * Return a "page" of history results. Each page will have visits in descending order
     * with respect to their visit timestamps. In the case of ties, their row id will
     * be used.
     *
     * Note that you may get surprising results if the items in the database change
     * while you are paging through records.
     *
     * @param offset The offset where the page begins.
     * @param count The number of items to return in the page.
     * @param excludeTypes List of visit types to exclude.
     */
    fun getVisitPage(offset: Long, count: Long, excludeTypes: List<VisitType> = listOf()): List<VisitInfo>

    /**
     * Page more efficiently than using simple numeric offset. We first figure out
     * a visited timestamp upper bound, then do a smaller numeric offset relative to
     * the bound.
     *
     * @param bound The upper bound of already visited items.
     * @param offset The offset between first item that has visit date equal to bound
     *  and last visited item.
     * @param count The number eof items to return in the page.
     * @param excludeTypes List of visit types to exclude.
     */
    fun getVisitPageWithBound(
        bound: Long,
        offset: Long,
        count: Long,
        excludeTypes: List<VisitType> = listOf()
    ): VisitInfosWithBound

    /**
     * Get the number of history visits.
     *
     * It is intended that this be used with `getVisitPage` to allow pagination
     * through records, however be aware that (unless you hold the only
     * reference to the write connection, and know a sync may not occur at this
     * time), the number of items in the database may change between when you
     * call `getVisitCount` and `getVisitPage`.
     *
     *
     * @param excludeTypes List of visit types to exclude.
     */
    fun getVisitCount(excludeTypes: List<VisitType> = listOf()): Long
}

interface WritableHistoryConnection : ReadableHistoryConnection {
    /**
     * Record a visit to a URL, or update meta information about page URL. See [VisitObservation].
     */
    fun noteObservation(data: VisitObservation)

    /**
     * Deletes all history visits, without recording tombstones.
     *
     * That is, these deletions will not be synced. Any changes which were
     * pending upload on the next sync are discarded and will be lost.
     */
    fun wipeLocal()

    /**
     * Run periodic database maintenance. This might include, but is not limited
     * to:
     *
     * - `VACUUM`ing.
     * - Requesting that the indices in our tables be optimized.
     * - Expiring irrelevant history visits.
     * - Periodic repair or deletion of corrupted records.
     * - etc.
     *
     * It should be called at least once a day, but this is merely a
     * recommendation and nothing too dire should happen if it is not
     * called.
     */
    fun runMaintenance()

    /**
     * Aggressively prune history visits. These deletions are not intended
     * to be synced, however due to the way history sync works, this can
     * still cause data loss.
     *
     * As a result, this should only be called if a low disk space
     * notification is received from the OS, and things like the network
     * cache have already been cleared.
     */
    fun pruneDestructively()

    /**
     * Delete everything locally.
     *
     * This will not delete visits from remote devices, however it will
     * prevent them from trickling in over time when future syncs occur.
     *
     * The difference between this and wipeLocal is that wipeLocal does
     * not prevent the deleted visits from returning. For wipeLocal,
     * the visits will return on the next full sync (which may be
     * arbitrarially far in the future), wheras items which were
     * deleted by deleteEverything (or potentially could have been)
     * should not return.
     */
    fun deleteEverything()

    /**
     * Deletes all information about the given URL. If the place has previously
     * been synced, a tombstone will be written to the sync server, meaning
     * the place should be deleted on all synced devices.
     *
     * The exception to this is if the place is duplicated on the sync server
     * (duplicate server-side places are a form of corruption), in which case
     * only the place whose GUID corresponds to the local GUID will be
     * deleted. This is (hopefully) rare, and sadly there is not much we can
     * do about it. It indicates a client-side bug that occurred at some
     * point in the past.
     *
     * @param url the url to be removed.
     */
    fun deletePlace(url: String)

    /**
     * Deletes all visits which occurred since the specified time. If the
     * deletion removes the last visit for a place, the place itself will also
     * be removed (and if the place has been synced, the deletion of the
     * place will also be synced)
     *
     * @param start time for the deletion, unix timestamp in milliseconds.
     */
    fun deleteVisitsSince(since: Long)

    /**
     * Equivalent to deleteVisitsSince, but takes an `endTime` as well.
     *
     * Timestamps are in milliseconds since the unix epoch.
     *
     * See documentation for deleteVisitsSince for caveats.
     *
     * @param startTime Inclusive beginning of the time range to delete.
     * @param endTime Inclusive end of the time range to delete.
     */
    fun deleteVisitsBetween(startTime: Long, endTime: Long)

    /**
     * Delete the single visit that occurred at the provided timestamp.
     *
     * Note that this will not delete the visit on another device, unless this is the last
     * remaining visit of that URL that this device is aware of.
     *
     * However, it should prevent this visit from being inserted again.
     *
     * @param url The URL of the place to delete.
     * @param visitTimestamp The timestamp of the visit to delete, in MS since the unix epoch
     */
    fun deleteVisit(url: String, visitTimestamp: Long)

    /**
     * Records an accepted autocomplete match, recording the query string,
     * and chosen URL for subsequent matches.
     *
     * @param searchString The query string
     * @param url The chosen URL string
     */
    fun acceptResult(searchString: String, url: String)
}

class InterruptHandle internal constructor(raw: RawPlacesInterruptHandle) : AutoCloseable {
    // We synchronize all accesses, so this probably doesn't need AtomicReference.
    private val handle: AtomicReference<RawPlacesInterruptHandle?> = AtomicReference(raw)

    @Synchronized
    override fun close() {
        val toFree = handle.getAndSet(null)
        if (toFree != null) {
            LibPlacesFFI.INSTANCE.places_interrupt_handle_destroy(toFree)
        }
    }

    @Synchronized
    fun interrupt() {
        handle.get()?.let {
            val e = RustError.ByReference()
            LibPlacesFFI.INSTANCE.places_interrupt(it, e)
            if (e.isFailure()) {
                throw e.intoException()
            }
        }
    }
}

open class PlacesException(msg: String) : Exception(msg)
open class InternalPanic(msg: String) : PlacesException(msg)
open class UrlParseFailed(msg: String) : PlacesException(msg)
open class PlacesConnectionBusy(msg: String) : PlacesException(msg)
open class OperationInterrupted(msg: String) : PlacesException(msg)

enum class VisitType(val type: Int) {
    /** This isn't a visit, but a request to update meta data about a page */
    UPDATE_PLACE(-1),
    /** This transition type means the user followed a link. */
    LINK(1),
    /** This transition type means that the user typed the page's URL in the
     *  URL bar or selected it from UI (URL bar autocomplete results, etc).
     */
    TYPED(2),
    // TODO: rest of docs
    BOOKMARK(3),
    EMBED(4),
    REDIRECT_PERMANENT(5),
    REDIRECT_TEMPORARY(6),
    DOWNLOAD(7),
    FRAMED_LINK(8),
    RELOAD(9)
}

private val intToVisitType: Map<Int, VisitType> = VisitType.values().associateBy(VisitType::type)

/**
 * Encapsulates either information about a visit to a page, or meta information about the page,
 * or both. Use [VisitType.UPDATE_PLACE] to differentiate an update from a visit.
 */
data class VisitObservation(
    val url: String,
    val visitType: VisitType,
    val title: String? = null,
    val isError: Boolean? = null,
    val isRedirectSource: Boolean? = null,
    val isPermanentRedirectSource: Boolean? = null,
    /** Milliseconds */
    val at: Long? = null,
    val referrer: String? = null,
    val isRemote: Boolean? = null
) {
    fun toJSON(): JSONObject {
        val o = JSONObject()
        o.put("url", this.url)
        // Absence of visit_type indicates that this is an update.
        if (this.visitType != VisitType.UPDATE_PLACE) {
            o.put("visit_type", this.visitType.type)
        }
        this.title?.let { o.put("title", it) }
        this.isError?.let { o.put("is_error", it) }
        this.isRedirectSource?.let { o.put("is_redirect_source", it) }
        this.isPermanentRedirectSource?.let { o.put("is_permanent_redirect_source", it) }
        this.at?.let { o.put("at", it) }
        this.referrer?.let { o.put("referrer", it) }
        this.isRemote?.let { o.put("is_remote", it) }
        return o
    }
}

fun stringOrNull(jsonObject: JSONObject, key: String): String? {
    return try {
        jsonObject.getString(key)
    } catch (e: JSONException) {
        null
    }
}

enum class SearchResultReason {
    KEYWORD,
    ORIGIN,
    URL,
    PREVIOUS_USE,
    BOOKMARK,
    TAG;

    companion object {
        fun fromMessage(reason: MsgTypes.SearchResultReason): SearchResultReason {
            return when (reason) {
                MsgTypes.SearchResultReason.KEYWORD -> KEYWORD
                MsgTypes.SearchResultReason.ORIGIN -> ORIGIN
                MsgTypes.SearchResultReason.URL -> URL
                MsgTypes.SearchResultReason.PREVIOUS_USE -> PREVIOUS_USE
                MsgTypes.SearchResultReason.BOOKMARK -> BOOKMARK
                MsgTypes.SearchResultReason.TAG -> TAG
            }
        }
    }
}

data class SearchResult(
    val url: String,
    val title: String,
    val frecency: Long,
    val reasons: List<SearchResultReason>
) {
    companion object {
        internal fun fromMessage(msg: MsgTypes.SearchResultMessage): SearchResult {
            return SearchResult(
                url = msg.url,
                title = msg.title,
                frecency = msg.frecency,
                reasons = msg.reasonsList.map {
                    SearchResultReason.fromMessage(it)
                }
            )
        }
        internal fun fromCollectionMessage(msg: MsgTypes.SearchResultList): List<SearchResult> {
            return msg.resultsList.map {
                fromMessage(it)
            }
        }
    }
}

/**
 * Information about a history visit. Returned by `PlacesAPI.getVisitInfos`.
 */
data class VisitInfo(
    /**
     * The URL of the page that was visited.
     */
    val url: String,

    /**
     * The title of the page that was visited, if known.
     */
    val title: String?,

    /**
     * The time the page was visited in integer milliseconds since the unix epoch.
     */
    val visitTime: Long,

    /**
     * What the transition type of the visit is.
     */
    val visitType: VisitType,

    /**
     * Whether the page is hidden because it redirected to another page, or was
     * visited in a frame.
     */
    val isHidden: Boolean
) {
    companion object {
        internal fun fromMessage(msg: MsgTypes.HistoryVisitInfos): List<VisitInfo> {
            return msg.infosList.map {
                VisitInfo(url = it.url,
                    title = it.title,
                    visitTime = it.timestamp,
                    visitType = intToVisitType[it.visitType]!!,
                    isHidden = it.isHidden)
            }
        }
    }
}

data class VisitInfosWithBound(
    val infos: List<VisitInfo>,
    val bound: Long,
    val offset: Long
) {
    companion object {
        internal fun fromMessage(msg: MsgTypes.HistoryVisitInfosWithBound): VisitInfosWithBound {
            val infoList = msg.infosList.map {
                VisitInfo(
                    url = it.url,
                    title = it.title,
                    visitTime = it.timestamp,
                    visitType = intToVisitType[it.visitType]!!,
                    isHidden = it.isHidden
                )
            }
            return VisitInfosWithBound(
                infos = infoList,
                bound = msg.bound,
                offset = msg.offset
            )
        }
    }
}

/**
 * A helper extension method for conveniently measuring execution time of a closure.
 *
 * N.B. since we're measuring calls to Rust code here, the provided callback may be doing
 * unsafe things. It's very imporant that we always call the function exactly once here
 * and don't try to do anything tricky like stashing it for later or calling it multiple times.
 */
inline fun <U> TimingDistributionMetricType.measure(funcToMeasure: () -> U): U {
    val timerId = this.start()
    try {
        return funcToMeasure()
    } finally {
        this.stopAndAccumulate(timerId)
    }
}

/**
 * A helper class for gathering basic count metrics on different kinds of PlacesManager operations.
 *
 * For each type of operation, we want to measure:
 *    - total count of operations performed
 *    - count of operations that produced an error, labeled by type
 *
 * This is a convenince wrapper to measure the two in one shot.
 */
class PlacesManagerCounterMetrics(
    val count: CounterMetricType,
    val errCount: LabeledMetricType<CounterMetricType>
) {
    @Suppress("ComplexMethod", "TooGenericExceptionCaught")
    inline fun <U> measure(callback: () -> U): U {
        count.add()
        try {
            return callback()
        } catch (e: Exception) {
            when (e) {
                is UrlParseFailed -> {
                    errCount["url_parse_failed"].add()
                }
                is OperationInterrupted -> {
                    errCount["operation_interrupted"].add()
                }
                is InvalidParent -> {
                    errCount["invalid_parent"].add()
                }
                is UnknownBookmarkItem -> {
                    errCount["unknown_bookmark_item"].add()
                }
                is UrlTooLong -> {
                    errCount["url_too_long"].add()
                }
                is InvalidBookmarkUpdate -> {
                    errCount["invalid_bookmark_update"].add()
                }
                is CannotUpdateRoot -> {
                    errCount["cannot_update_root"].add()
                }
                else -> {
                    errCount["__other__"].add()
                }
            }
            throw e
        }
    }
}
