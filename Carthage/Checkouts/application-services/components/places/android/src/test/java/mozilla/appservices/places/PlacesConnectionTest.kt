/* Any copyright is dedicated to the Public Domain.
   http://creativecommons.org/publicdomain/zero/1.0/ */

package mozilla.appservices.places

import androidx.test.core.app.ApplicationProvider
import mozilla.appservices.Megazord
import mozilla.components.service.glean.testing.GleanTestRule
import org.junit.After
import org.junit.rules.TemporaryFolder
import org.junit.Rule
import org.junit.runner.RunWith
import org.mozilla.appservices.places.GleanMetrics.PlacesManager as PlacesManagerMetrics
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.junit.Test
import org.junit.Assert.assertEquals
import org.junit.Assert.fail
import org.junit.Before

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE)
class PlacesConnectionTest {
    @Rule
    @JvmField
    val dbFolder = TemporaryFolder()

    @get:Rule
    val gleanRule = GleanTestRule(ApplicationProvider.getApplicationContext())

    lateinit var api: PlacesApi
    lateinit var db: PlacesWriterConnection

    @Before
    fun initAPI() {
        Megazord.init()
        api = PlacesApi(path = dbFolder.newFile().absolutePath)
        db = api.getWriter()
    }

    @After
    fun closeAPI() {
        db.close()
        api.close()
    }

    // Basically equivalent to test_get_visited in rust, but exercises the FFI,
    // as well as the handling of invalid urls.
    @Test
    fun testGetVisited() {

        val unicodeInPath = "http://www.example.com/tëst😀abc"
        val escapedUnicodeInPath = "http://www.example.com/t%C3%ABst%F0%9F%98%80abc"

        val unicodeInDomain = "http://www.exämple😀123.com"
        val escapedUnicodeInDomain = "http://www.xn--exmple123-w2a24222l.com"

        val toAdd = listOf(
                "https://www.example.com/1",
                "https://www.example.com/12",
                "https://www.example.com/123",
                "https://www.example.com/1234",
                "https://www.mozilla.com",
                "https://www.firefox.com",
                "$unicodeInPath/1",
                "$escapedUnicodeInPath/2",
                "$unicodeInDomain/1",
                "$escapedUnicodeInDomain/2"
        )

        for (url in toAdd) {
            db.noteObservation(VisitObservation(url = url, visitType = VisitType.LINK))
        }

        val toSearch = listOf(
                Pair("https://www.example.com", false),
                Pair("https://www.example.com/1", true),
                Pair("https://www.example.com/12", true),
                Pair("https://www.example.com/123", true),
                Pair("https://www.example.com/1234", true),
                Pair("https://www.example.com/12345", false),
                // Bad URLs should still work without.
                Pair("https://www.example.com:badurl", false),

                Pair("https://www.mozilla.com", true),
                Pair("https://www.firefox.com", true),
                Pair("https://www.mozilla.org", false),

                // Dupes should still work
                Pair("https://www.example.com/1234", true),
                Pair("https://www.example.com/12345", false),

                // The unicode URLs should work when escaped the way we
                // encountered them
                Pair("$unicodeInPath/1", true),
                Pair("$escapedUnicodeInPath/2", true),
                Pair("$unicodeInDomain/1", true),
                Pair("$escapedUnicodeInDomain/2", true),

                // But also the other way.
                Pair("$unicodeInPath/2", true),
                Pair("$escapedUnicodeInPath/1", true),
                Pair("$unicodeInDomain/2", true),
                Pair("$escapedUnicodeInDomain/1", true)
        )

        val visited = db.getVisited(toSearch.map { it.first }.toList())

        assertEquals(visited.size, toSearch.size)

        for (i in 0 until visited.size) {
            assert(visited[i] == toSearch[i].second) {
                "Test $i failed for url ${toSearch[i].first} (got ${visited[i]}, want ${toSearch[i].second})"
            }
        }
    }

    @Test
    fun testNoteObservationBadUrl() {
        try {
            db.noteObservation(VisitObservation(url = "http://www.[].com", visitType = VisitType.LINK))
        } catch (e: PlacesException) {
            assert(e is UrlParseFailed)
        }
    }
    // Basically equivalent to test_get_visited in rust, but exercises the FFI,
    // as well as the handling of invalid urls.
    @Test
    fun testMatchUrl() {

        val toAdd = listOf(
                // add twice to ensure its frecency is higher
                "https://www.example.com/123",
                "https://www.example.com/123",
                "https://www.example.com/12345",
                "https://www.mozilla.com/foo/bar/baz",
                "https://www.mozilla.com/foo/bar/baz",
                "https://mozilla.com/a1/b2/c3",
                "https://news.ycombinator.com/"
        )

        for (url in toAdd) {
            db.noteObservation(VisitObservation(url = url, visitType = VisitType.LINK))
        }
        // Should use the origin search
        assertEquals("https://www.example.com/", db.matchUrl("example.com"))
        assertEquals("https://www.example.com/", db.matchUrl("www.example.com"))
        assertEquals("https://www.example.com/", db.matchUrl("https://www.example.com"))

        // Not an origin.
        assertEquals("https://www.example.com/123", db.matchUrl("example.com/"))
        assertEquals("https://www.example.com/123", db.matchUrl("www.example.com/"))
        assertEquals("https://www.example.com/123", db.matchUrl("https://www.example.com/"))

        assertEquals("https://www.example.com/123", db.matchUrl("example.com/1"))
        assertEquals("https://www.example.com/123", db.matchUrl("www.example.com/1"))
        assertEquals("https://www.example.com/123", db.matchUrl("https://www.example.com/1"))

        assertEquals("https://www.example.com/12345", db.matchUrl("example.com/1234"))
        assertEquals("https://www.example.com/12345", db.matchUrl("www.example.com/1234"))
        assertEquals("https://www.example.com/12345", db.matchUrl("https://www.example.com/1234"))

        assertEquals("https://www.mozilla.com/foo/", db.matchUrl("mozilla.com/"))
        assertEquals("https://www.mozilla.com/foo/", db.matchUrl("mozilla.com/foo"))
        assertEquals("https://www.mozilla.com/foo/bar/", db.matchUrl("mozilla.com/foo/"))
        assertEquals("https://www.mozilla.com/foo/bar/", db.matchUrl("mozilla.com/foo/bar"))
        assertEquals("https://www.mozilla.com/foo/bar/baz", db.matchUrl("mozilla.com/foo/bar/"))
        assertEquals("https://www.mozilla.com/foo/bar/baz", db.matchUrl("mozilla.com/foo/bar/baz"))
        // Make sure the www/non-www doesn't confuse it
        assertEquals("https://mozilla.com/a1/b2/", db.matchUrl("mozilla.com/a1/"))

        // Actual visit had no www
        assertEquals(null, db.matchUrl("www.mozilla.com/a1"))
        assertEquals("https://news.ycombinator.com/", db.matchUrl("news"))
    }

    // Basically equivalent to test_get_visited in rust, but exercises the FFI,
    // as well as the handling of invalid urls.
    @Test
    fun testGetVisitInfos() {
        db.noteObservation(VisitObservation(url = "https://www.example.com/1", visitType = VisitType.LINK, at = 100000))
        db.noteObservation(VisitObservation(url = "https://www.example.com/2a", visitType = VisitType.REDIRECT_TEMPORARY, at = 130000))
        db.noteObservation(VisitObservation(url = "https://www.example.com/2b", visitType = VisitType.LINK, at = 150000))
        db.noteObservation(VisitObservation(url = "https://www.example.com/3", visitType = VisitType.LINK, at = 200000))
        db.noteObservation(VisitObservation(url = "https://www.example.com/4", visitType = VisitType.LINK, at = 250000))
        var infos = db.getVisitInfos(125000, 225000, excludeTypes = listOf(VisitType.REDIRECT_TEMPORARY))
        assertEquals(2, infos.size)
        assertEquals("https://www.example.com/2b", infos[0].url)
        assertEquals("https://www.example.com/3", infos[1].url)
        infos = db.getVisitInfos(125000, 225000)
        assertEquals(3, infos.size)
        assertEquals("https://www.example.com/2a", infos[0].url)
        assertEquals("https://www.example.com/2b", infos[1].url)
        assertEquals("https://www.example.com/3", infos[2].url)
    }

    @Test
    fun testGetVisitPage() {
        db.noteObservation(VisitObservation(url = "https://www.example.com/1", visitType = VisitType.LINK, at = 100000))
        db.noteObservation(VisitObservation(url = "https://www.example.com/2", visitType = VisitType.LINK, at = 110000))
        db.noteObservation(VisitObservation(url = "https://www.example.com/3a", visitType = VisitType.REDIRECT_TEMPORARY, at = 120000))
        db.noteObservation(VisitObservation(url = "https://www.example.com/3b", visitType = VisitType.REDIRECT_TEMPORARY, at = 130000))
        db.noteObservation(VisitObservation(url = "https://www.example.com/4", visitType = VisitType.LINK, at = 140000))
        db.noteObservation(VisitObservation(url = "https://www.example.com/5", visitType = VisitType.LINK, at = 150000))
        db.noteObservation(VisitObservation(url = "https://www.example.com/6", visitType = VisitType.LINK, at = 160000))
        db.noteObservation(VisitObservation(url = "https://www.example.com/7", visitType = VisitType.LINK, at = 170000))
        db.noteObservation(VisitObservation(url = "https://www.example.com/8", visitType = VisitType.LINK, at = 180000))

        assertEquals(9, db.getVisitCount())
        assertEquals(7, db.getVisitCount(excludeTypes = listOf(VisitType.REDIRECT_TEMPORARY)))

        val want = listOf(
                listOf("https://www.example.com/8", "https://www.example.com/7", "https://www.example.com/6"),
                listOf("https://www.example.com/5", "https://www.example.com/4", "https://www.example.com/2"),
                listOf("https://www.example.com/1")
        )

        var offset = 0L
        for (expect in want) {
            val page = db.getVisitPage(
                    offset = offset,
                    count = 3,
                    excludeTypes = listOf(VisitType.REDIRECT_TEMPORARY))
            assertEquals(expect.size, page.size)
            for (i in 0..(expect.size - 1)) {
                assertEquals(expect[i], page[i].url)
            }
            offset += page.size
        }
        val empty = db.getVisitPage(
                offset = offset,
                count = 3,
                excludeTypes = listOf(VisitType.REDIRECT_TEMPORARY))
        assertEquals(0, empty.size)
    }

    @Test
    fun testCreateBookmark() {
        val itemGUID = db.createBookmarkItem(
                parentGUID = BookmarkRoot.Unfiled.id,
                url = "https://www.example.com/",
                title = "example")

        val sepGUID = db.createSeparator(
                parentGUID = BookmarkRoot.Unfiled.id,
                position = 0)

        val folderGUID = db.createFolder(
                parentGUID = BookmarkRoot.Unfiled.id,
                title = "example folder")

        val item = db.getBookmark(itemGUID)!! as BookmarkItem
        val sep = db.getBookmark(sepGUID)!! as BookmarkSeparator
        val folder = db.getBookmark(folderGUID)!! as BookmarkFolder

        assertEquals(item.type, BookmarkType.Bookmark)
        assertEquals(sep.type, BookmarkType.Separator)
        assertEquals(folder.type, BookmarkType.Folder)

        assertEquals(item.title, "example")
        assertEquals(item.url, "https://www.example.com/")
        assertEquals(item.position, 1)
        assertEquals(item.parentGUID, BookmarkRoot.Unfiled.id)

        assertEquals(sep.position, 0)
        assertEquals(sep.parentGUID, BookmarkRoot.Unfiled.id)

        assertEquals(folder.title, "example folder")
        assertEquals(folder.position, 2)
        assertEquals(folder.parentGUID, BookmarkRoot.Unfiled.id)
    }

    @Test
    fun testHistoryMetricsGathering() {
        assert(!PlacesManagerMetrics.writeQueryTime.testHasValue())
        assert(!PlacesManagerMetrics.writeQueryCount.testHasValue())
        assert(!PlacesManagerMetrics.writeQueryErrorCount["url_parse_failed"].testHasValue())

        db.noteObservation(VisitObservation(url = "https://www.example.com/2a", visitType = VisitType.REDIRECT_TEMPORARY, at = 130000))
        db.noteObservation(VisitObservation(url = "https://www.example.com/2b", visitType = VisitType.LINK, at = 150000))
        db.noteObservation(VisitObservation(url = "https://www.example.com/3", visitType = VisitType.LINK, at = 200000))

        assert(PlacesManagerMetrics.writeQueryTime.testHasValue())
        assertEquals(3, PlacesManagerMetrics.writeQueryCount.testGetValue())
        assert(!PlacesManagerMetrics.writeQueryErrorCount["__other__"].testHasValue())

        try {
            db.noteObservation(VisitObservation(url = "4", visitType = VisitType.REDIRECT_TEMPORARY, at = 160000))
            fail("Should have thrown")
        } catch (e: UrlParseFailed) {
            // nothing to do here
        }

        assert(PlacesManagerMetrics.writeQueryTime.testHasValue())
        assertEquals(4, PlacesManagerMetrics.writeQueryCount.testGetValue())
        assert(PlacesManagerMetrics.writeQueryErrorCount["url_parse_failed"].testHasValue())
        assertEquals(1, PlacesManagerMetrics.writeQueryErrorCount["url_parse_failed"].testGetValue())

        assert(!PlacesManagerMetrics.readQueryTime.testHasValue())
        assert(!PlacesManagerMetrics.readQueryCount.testHasValue())
        assert(!PlacesManagerMetrics.readQueryErrorCount["__other__"].testHasValue())

        db.getVisitInfos(125000, 225000)

        assert(PlacesManagerMetrics.readQueryTime.testHasValue())
        assertEquals(1, PlacesManagerMetrics.readQueryCount.testGetValue())
        assert(!PlacesManagerMetrics.readQueryErrorCount["__other__"].testHasValue())

        db.deleteVisit("https://www.example.com/2a", 130000)

        val infos = db.getVisitInfos(130000, 200000)
        assertEquals(2, infos.size)

        assert(PlacesManagerMetrics.writeQueryTime.testHasValue())
        assertEquals(5, PlacesManagerMetrics.writeQueryCount.testGetValue())
        assert(!PlacesManagerMetrics.writeQueryErrorCount["_other_"].testHasValue())
    }

    @Test
    fun testBookmarksMetricsGathering() {
        assert(!PlacesManagerMetrics.writeQueryTime.testHasValue())
        assert(!PlacesManagerMetrics.writeQueryCount.testHasValue())
        assert(!PlacesManagerMetrics.writeQueryErrorCount["unknown_bookmark_item"].testHasValue())

        val itemGUID = db.createBookmarkItem(
                parentGUID = BookmarkRoot.Unfiled.id,
                url = "https://www.example.com/",
                title = "example")

        assert(PlacesManagerMetrics.writeQueryTime.testHasValue())
        assertEquals(1, PlacesManagerMetrics.writeQueryCount.testGetValue())
        assert(!PlacesManagerMetrics.writeQueryErrorCount["unknown_bookmark_item"].testHasValue())

        try {
            db.createBookmarkItem(
                parentGUID = BookmarkRoot.Unfiled.id,
                url = "3",
                title = "example")
            fail("Should have thrown")
        } catch (e: UrlParseFailed) {
            // nothing to do here
        }

        assert(PlacesManagerMetrics.writeQueryTime.testHasValue())
        assertEquals(2, PlacesManagerMetrics.writeQueryCount.testGetValue())
        assert(PlacesManagerMetrics.writeQueryErrorCount["url_parse_failed"].testHasValue())
        assertEquals(1, PlacesManagerMetrics.writeQueryErrorCount["url_parse_failed"].testGetValue())

        assert(!PlacesManagerMetrics.readQueryTime.testHasValue())
        assert(!PlacesManagerMetrics.readQueryCount.testHasValue())
        assert(!PlacesManagerMetrics.readQueryErrorCount["__other__"].testHasValue())

        db.getBookmark(itemGUID)

        assert(PlacesManagerMetrics.readQueryTime.testHasValue())
        assertEquals(1, PlacesManagerMetrics.readQueryCount.testGetValue())
        assert(!PlacesManagerMetrics.readQueryErrorCount["__other__"].testHasValue())

        assert(!PlacesManagerMetrics.scanQueryTime.testHasValue())

        val folderGUID = db.createFolder(
                parentGUID = BookmarkRoot.Unfiled.id,
                title = "example folder")

        db.createBookmarkItem(
                parentGUID = folderGUID,
                url = "https://www.example2.com/",
                title = "example2")

        db.createBookmarkItem(
                parentGUID = folderGUID,
                url = "https://www.example3.com/",
                title = "example3")

        db.createBookmarkItem(
                parentGUID = BookmarkRoot.Unfiled.id,
                url = "https://www.example4.com/",
                title = "example4")

        db.getBookmarksTree(folderGUID, false)

        assert(PlacesManagerMetrics.scanQueryTime.testHasValue())
    }
}
