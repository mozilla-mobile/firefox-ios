// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage
import XCTest

@testable import Client

final class SearchViewModelTests: XCTestCase {
    var profile: MockProfile!
    var engines: SearchEngines!
    var remoteClient: RemoteClient!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile(firefoxSuggest: MockRustFirefoxSuggest())
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        LegacyFeatureFlagsManager.shared.set(feature: .firefoxSuggestFeature, to: true)

        let mockSearchEngineProvider = MockSearchEngineProvider()
        engines = SearchEngines(
            prefs: profile.prefs,
            files: profile.files,
            engineProvider: mockSearchEngineProvider
        )

        remoteClient = RemoteClient(
            guid: nil,
            name: "Fake client",
            modified: 1,
            type: nil,
            formfactor: nil,
            os: nil,
            version: nil,
            fxaDeviceId: nil
        )
    }

    override func tearDown() {
        super.tearDown()
        profile = nil
    }

    func testFirefoxSuggestionReturnsNoSuggestions() async throws {
        FxNimbus.shared.features.firefoxSuggestFeature.with(initializer: { _, _ in
            FirefoxSuggestFeature(availableSuggestionsTypes:
                                    [.amp: false, .ampMobile: false, .wikipedia: false])
       })

        engines.shouldShowFirefoxSuggestions = false
        engines.shouldShowSponsoredSuggestions = false

        let subject = createSubject()
        await subject.loadFirefoxSuggestions()?.value
        XCTAssertEqual(subject.firefoxSuggestions.count, 0)

        // Providers set to false, so regardless of the prefs, we shouldn't see anything
        engines.shouldShowFirefoxSuggestions = true
        engines.shouldShowSponsoredSuggestions = true
        await subject.loadFirefoxSuggestions()?.value
        XCTAssertEqual(subject.firefoxSuggestions.count, 0)
    }

    func testFirefoxSuggestionReturnsNoSuggestionsWhenSuggestionSettingsFalse() async throws {
        FxNimbus.shared.features.firefoxSuggestFeature.with(initializer: { _, _ in
            FirefoxSuggestFeature(availableSuggestionsTypes:
                                    [.amp: false, .ampMobile: true, .wikipedia: true])
       })

        engines.shouldShowFirefoxSuggestions = false
        engines.shouldShowSponsoredSuggestions = false

        let subject = createSubject()

        await subject.loadFirefoxSuggestions()?.value
        XCTAssertEqual(subject.firefoxSuggestions.count, 0)
    }

    func testFirefoxSuggestionReturnsSponsoredAndNonSponsored() async throws {
        FxNimbus.shared.features.firefoxSuggestFeature.with(initializer: { _, _ in
            FirefoxSuggestFeature(availableSuggestionsTypes:
                                    [.amp: false, .ampMobile: true, .wikipedia: true])
       })

        engines.shouldShowFirefoxSuggestions = true
        engines.shouldShowSponsoredSuggestions = true
        let subject = createSubject()
        await subject.loadFirefoxSuggestions()?.value

        XCTAssertEqual(subject.firefoxSuggestions.count, 2)
    }

    func testSyncedTabsAreFilteredWhenShowSponsoredSuggestionsIsTrue() {
        engines.shouldShowSponsoredSuggestions = true
        let remoteTab1 = RemoteTab(
            clientGUID: "1",
            URL: URL(string: "www.mozilla.org?mfadid=adm")!,
            title: "Mozilla 1",
            history: [],
            lastUsed: UInt64(1),
            icon: nil,
            inactive: false
        )
        let remoteTab2 = RemoteTab(
            clientGUID: "2",
            URL: URL(string: "www.mozilla.org")!,
            title: "Mozilla 2",
            history: [],
            lastUsed: UInt64(2),
            icon: nil,
            inactive: false
        )
        let remoteTab3 = RemoteTab(
            clientGUID: "3",
            URL: URL(string: "www.mozilla.org?a=b")!,
            title: "Mozilla 3",
            history: [],
            lastUsed: UInt64(3),
            icon: nil,
            inactive: false
        )
        let subject = createSubject()
        subject.remoteClientTabs = [ClientTabsSearchWrapper(client: remoteClient, tab: remoteTab1),
                                                 ClientTabsSearchWrapper(client: remoteClient, tab: remoteTab2),
                                                 ClientTabsSearchWrapper(client: remoteClient, tab: remoteTab3)]
        subject.searchRemoteTabs(for: "Mozilla")
        XCTAssertEqual(subject.filteredRemoteClientTabs.count, 2)
    }

    func testSyncedTabsAreNotFilteredWhenShowSponsoredSuggestionsIsFalse() {
        engines.shouldShowSponsoredSuggestions = false

        let remoteTab1 = RemoteTab(
            clientGUID: "1",
            URL: URL(string: "www.mozilla.org?mfadid=adm")!,
            title: "Mozilla 1",
            history: [],
            lastUsed: UInt64(1),
            icon: nil,
            inactive: false
        )
        let remoteTab2 = RemoteTab(
            clientGUID: "2",
            URL: URL(string: "www.mozilla.org")!,
            title: "Mozilla 2",
            history: [],
            lastUsed: UInt64(2),
            icon: nil,
            inactive: false
        )
        let remoteTab3 = RemoteTab(
            clientGUID: "3",
            URL: URL(string: "www.mozilla.org?a=b")!,
            title: "Mozilla 3",
            history: [],
            lastUsed: UInt64(3),
            icon: nil,
            inactive: false
        )
        let subject = createSubject()
        subject.remoteClientTabs = [ClientTabsSearchWrapper(client: remoteClient, tab: remoteTab1),
                                                 ClientTabsSearchWrapper(client: remoteClient, tab: remoteTab2),
                                                 ClientTabsSearchWrapper(client: remoteClient, tab: remoteTab3)]
        subject.searchRemoteTabs(for: "Mozilla")
        XCTAssertEqual(subject.filteredRemoteClientTabs.count, 3)
    }

    func testSponsoredSuggestionsAreNotShownInPrivateBrowsingMode() async throws {
        let subject = createSubject(isPrivate: true, isBottomSearchBar: false)
        engines.shouldShowFirefoxSuggestions = true
        engines.shouldShowSponsoredSuggestions = true

        await subject.loadFirefoxSuggestions()?.value
        XCTAssertTrue(subject.firefoxSuggestions.isEmpty)
    }

    func testNonSponsoredSuggestionsAreNotShownInPrivateBrowsingMode() async throws {
        let subject = createSubject(isPrivate: true, isBottomSearchBar: false)

        engines.shouldShowFirefoxSuggestions = true
        engines.shouldShowSponsoredSuggestions = true

        await subject.loadFirefoxSuggestions()?.value

        XCTAssertTrue(subject.firefoxSuggestions.isEmpty)
    }

    func testNonSponsoredAndSponsoredSuggestionsInPrivateModeWithPrivateSuggestionsOn() async throws {
        let subject = createSubject(isPrivate: true, isBottomSearchBar: false)

        engines.shouldShowFirefoxSuggestions = true
        engines.shouldShowSponsoredSuggestions = true
        engines.shouldShowPrivateModeFirefoxSuggestions = true
        await subject.loadFirefoxSuggestions()?.value

        XCTAssertTrue(subject.firefoxSuggestions.isEmpty)
    }

    func testNonSponsoredInPrivateModeWithPrivateSuggestionsOn() async throws {
        let subject = createSubject(isPrivate: true, isBottomSearchBar: false)
        engines.shouldShowFirefoxSuggestions = true
        engines.shouldShowSponsoredSuggestions = false
        engines.shouldShowPrivateModeFirefoxSuggestions = true
        await subject.loadFirefoxSuggestions()?.value

        XCTAssertTrue(subject.firefoxSuggestions.isEmpty)
    }

    func testNonSponsoredAndSponsoredSuggestionsAreNotShownInPrivateBrowsingMode() async throws {
        let subject = createSubject(isPrivate: true, isBottomSearchBar: false)

        engines.shouldShowPrivateModeFirefoxSuggestions = false
        await subject.loadFirefoxSuggestions()?.value

        XCTAssertTrue(subject.firefoxSuggestions.isEmpty)
    }

    private func createSubject(
        isPrivate: Bool = false,
        isBottomSearchBar: Bool = false,
        file: StaticString = #file,
        line: UInt = #line
    ) -> SearchViewModel {
        let subject = SearchViewModel(
            isPrivate: isPrivate,
            isBottomSearchBar: isBottomSearchBar,
            profile: profile,
            model: engines,
            tabManager: MockTabManager()
        )

        return subject
    }
}
