// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
@testable import Client

final class DefaultRecentSearchProviderTests: XCTestCase {
    var mockProfile: MockProfile!

    override func setUp() {
        super.setUp()
        mockProfile = MockProfile()
    }

    override func tearDown() {
        mockProfile = nil
        super.tearDown()
    }

    func test_addRecentSearch_withMultipleCalls_returnsExpectedRecentSearches() {
        let sut = createSubject(for: "engineA")

        sut.addRecentSearch("swift enums")
        sut.addRecentSearch("combine")
        sut.addRecentSearch("async await")

        XCTAssertEqual(sut.recentSearches, ["async await", "combine", "swift enums"])
    }

    func test_addRecentSearch_withTwoDifferentEngines_areIsolatedAndDoNotOverlap() {
        let subjectA = createSubject(for: "engineA")
        let subjectB = createSubject(for: "engineB")

        subjectA.addRecentSearch("swift")
        subjectB.addRecentSearch("kotlin")

        XCTAssertEqual(subjectA.recentSearches, ["swift"])
        XCTAssertEqual(subjectB.recentSearches, ["kotlin"])
    }

    func test_addRecentSearch_withWhitespaces_trimsAndReturnsValidSearchTerm() {
        let sut = createSubject(for: "engineA")

        sut.addRecentSearch("   swift  ")
        sut.addRecentSearch("   ")
        sut.addRecentSearch("")

        XCTAssertEqual(sut.recentSearches, ["swift"])
    }

    func test_addRecentSearch_withCaseSensitivity_returnsSingleSearchTerm() {
        let sut = createSubject(for: "engineA")

        sut.addRecentSearch("Swift")
        sut.addRecentSearch("swift")
        sut.addRecentSearch("SWIFT")

        XCTAssertEqual(sut.recentSearches, ["SWIFT"])
    }

    func test_addRecentSearch_movesExistingValueToFront_doesNotReturnDuplicateSearchTerm() {
        let sut = createSubject(for: "engineA")

        sut.addRecentSearch("a")
        sut.addRecentSearch("b")
        sut.addRecentSearch("c")
        sut.addRecentSearch("b")

        XCTAssertEqual(sut.recentSearches, ["b", "c", "a"])
    }

    func test_addRecentSearch_withMoreThanMax10_returnsOnlyMostRecentSearchTerm() {
        let sut = createSubject(for: "engineA")

        for i in 1...15 { sut.addRecentSearch("search term \(i)") }

        let result = sut.recentSearches
        XCTAssertEqual(result.count, 5)
        XCTAssertEqual(result.first, "search term 15")
        XCTAssertEqual(result.last, "search term 11")
    }

    func test_clearRecentSearches_returnsEmptyArray() {
        let sut = createSubject(for: "engineA")

        sut.addRecentSearch("one")
        sut.addRecentSearch("two")
        XCTAssertFalse(sut.recentSearches.isEmpty)

        sut.clearRecentSearches()
        XCTAssertTrue(sut.recentSearches.isEmpty)
    }

    func test_recentSearches_persistAcrossInstances() {
        var a: RecentSearchProvider? = createSubject(for: "engineA")
        a?.addRecentSearch("first")
        a = nil

        let b = createSubject(for: "engineA")
        XCTAssertEqual(b.recentSearches, ["first"])
    }

    func test_addRecentSearch_usesCorrectNameSpacedKey() {
        let engineID = "engineA"
        let sut = createSubject(for: "engineA")

        sut.addRecentSearch("swift")
        let expectedKey = "\(PrefsKeys.Search.recentSearchesCache).\(engineID)"

        XCTAssertEqual(mockProfile.prefs.objectForKey(expectedKey), ["swift"])
    }

    func createSubject(for searchEngineID: String) -> RecentSearchProvider {
        let subject = DefaultRecentSearchProvider(
            profile: mockProfile,
            searchEngineID: searchEngineID,
        )
        return subject
    }
}
