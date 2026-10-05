// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import UIKit
import XCTest

@testable import Client

@MainActor
final class WebContextMenuTabGroupActionsTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        FxNimbus.shared.features.tabGroupsFeature.with { _ in TabGroupsFeature(enabled: true) }
    }

    override func tearDown() async throws {
        FxNimbus.shared.features.tabGroupsFeature.with { variables in TabGroupsFeature(variables) }
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testNoGroupsOffersDirectCreation() throws {
        let subject = WebContextMenuActionsProvider(menuType: .web)
        let tab = MockTab(profile: makeProfile(), windowUUID: .XCTestDefaultUUID)
        addGroupActions(to: subject, tab: tab, groups: [])

        let actions = subject.build()
        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual((actions.first as? UIAction)?.title, String.TabGroups.OpenInNewTabGroup)
    }

    func testGroupsOfferUngroupedAndNamedDestinationsWithoutPrivateTabs() throws {
        let subject = WebContextMenuActionsProvider(menuType: .web)
        let tab = MockTab(profile: makeProfile(), windowUUID: .XCTestDefaultUUID)
        let group = TabGroup(title: "Houses", icon: .sfSymbol("house.fill"))
        addGroupActions(to: subject, tab: tab, groups: [group], ungroupedTabCount: 1)

        let menu = try XCTUnwrap(subject.build().first as? UIMenu)
        let sections = menu.children.compactMap { $0 as? UIMenu }
        let actions = sections.flatMap { $0.children.compactMap { $0 as? UIAction } }
        XCTAssertEqual(menu.title, String.TabGroups.OpenInTabGroup)
        XCTAssertEqual(sections.map(\.children.count), [1, 1, 1])
        XCTAssertEqual(actions.map(\.title),
                       ["1 Tab", "Houses", String.TabGroups.NewTabGroupMenu])
        XCTAssertNotNil(actions[1].image)
    }

    func testFlagOffPreservesExistingActions() {
        FxNimbus.shared.features.tabGroupsFeature.with { _ in TabGroupsFeature(enabled: false) }
        let subject = WebContextMenuActionsProvider(menuType: .web)
        let tab = MockTab(profile: makeProfile(), windowUUID: .XCTestDefaultUUID)
        let url = URL(string: "https://example.com")!
        subject.addOpenInNewTab(url: url, currentTab: tab, addTab: { _, _, _ in })
        addGroupActions(to: subject, tab: tab, groups: [TabGroup(title: "Houses")])

        XCTAssertEqual(subject.build().compactMap { ($0 as? UIAction)?.title }, [String.ContextMenuOpenInNewTab])
    }

    func testPrivateAndImageMenusDoNotOfferGrouping() {
        let privateTab = MockTab(profile: makeProfile(), isPrivate: true, windowUUID: .XCTestDefaultUUID)
        let normalTab = MockTab(profile: makeProfile(), windowUUID: .XCTestDefaultUUID)
        let web = WebContextMenuActionsProvider(menuType: .web)
        let image = WebContextMenuActionsProvider(menuType: .image)
        addGroupActions(to: web, tab: privateTab, groups: [TabGroup(title: "Houses")])
        addGroupActions(to: image, tab: normalTab, groups: [TabGroup(title: "Houses")])

        XCTAssertTrue(web.build().isEmpty)
        XCTAssertTrue(image.build().isEmpty)
    }

    func testJavascriptLinksDoNotOfferGrouping() {
        let subject = WebContextMenuActionsProvider(menuType: .web)
        let tab = MockTab(profile: makeProfile(), windowUUID: .XCTestDefaultUUID)
        subject.addOpenInTabGroup(url: URL(string: "javascript:void(0)")!,
                                  currentTab: tab,
                                  groups: [],
                                  ungroupedTabCount: 0,
                                  openInGroup: { _, _ in XCTFail("Unexpected destination") },
                                  openInNewGroup: { _ in XCTFail("Unexpected group creation") })

        XCTAssertTrue(subject.build().isEmpty)
    }

    @available(iOS 16.0, *)
    func testDirectCreationOpensOriginalLink() throws {
        let subject = WebContextMenuActionsProvider(menuType: .web)
        let tab = MockTab(profile: makeProfile(), windowUUID: .XCTestDefaultUUID)
        let url = URL(string: "https://example.com/linked-page")!
        var openedURL: URL?
        subject.addOpenInTabGroup(url: url,
                                  currentTab: tab,
                                  groups: [],
                                  ungroupedTabCount: 0,
                                  openInGroup: { _, _ in XCTFail("Unexpected destination") },
                                  openInNewGroup: { openedURL = $0 })

        let action = try XCTUnwrap(subject.build().first as? UIAction)
        action.performWithSender(nil, target: nil)

        XCTAssertEqual(openedURL, url)
    }

    @available(iOS 16.0, *)
    func testDestinationHandlerSurvivesProviderAndRechecksFeatureFlag() throws {
        let tab = MockTab(profile: makeProfile(), windowUUID: .XCTestDefaultUUID)
        let group = TabGroup(title: "Houses")
        let url = URL(string: "https://example.com")!
        var openedURL: URL?
        var openedGroupID: TabGroupID?
        let menu: UIMenu
        do {
            let subject = WebContextMenuActionsProvider(menuType: .web)
            subject.addOpenInTabGroup(url: url,
                                      currentTab: tab,
                                      groups: [group],
                                      ungroupedTabCount: 2,
                                      openInGroup: { openedURL = $0; openedGroupID = $1 },
                                      openInNewGroup: { _ in XCTFail("Unexpected group creation") })
            menu = try XCTUnwrap(subject.build().first as? UIMenu)
        }
        let groupSection = try XCTUnwrap(menu.children[1] as? UIMenu)
        let action = try XCTUnwrap(groupSection.children.first as? UIAction)
        action.performWithSender(nil, target: nil)
        XCTAssertEqual(openedURL, url)
        XCTAssertEqual(openedGroupID, group.id)

        openedURL = nil
        FxNimbus.shared.features.tabGroupsFeature.with { _ in TabGroupsFeature(enabled: false) }
        action.performWithSender(nil, target: nil)
        XCTAssertNil(openedURL)
    }

    private func addGroupActions(to subject: WebContextMenuActionsProvider,
                                 tab: Tab,
                                 groups: [TabGroup],
                                 ungroupedTabCount: Int = 0) {
        subject.addOpenInTabGroup(url: URL(string: "https://example.com")!,
                                  currentTab: tab,
                                  groups: groups,
                                  ungroupedTabCount: ungroupedTabCount,
                                  openInGroup: { _, _ in },
                                  openInNewGroup: { _ in })
    }
}
