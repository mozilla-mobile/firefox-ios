// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import QuickAnswersKit
import TestKit
import XCTest

@MainActor
final class QuickAnswersSourceViewTests: XCTestCase {
    private var menuActions: [QuickAnswersCitationMenuAction]!
    private var pasteboardURLs: [URL]!
    private let sourceURL = URL(string: "https://example.com/article")!
    private let sourceTitle = "Article"

    override func setUp() async throws {
        try await super.setUp()
        menuActions = []
        pasteboardURLs = []
    }

    override func tearDown() async throws {
        menuActions = nil
        pasteboardURLs = nil
        try await super.tearDown()
    }

    // MARK: - contextMenuInteraction
    func test_contextMenuInteraction_returnsFiveActionsInOrderWithConfiguredTitles() throws {
        let subject = createSubject()

        let actions = try makeActions(from: subject)

        let strings = QuickAnswersViewConfiguration.CitationMenuStrings.mock
        XCTAssertEqual(
            actions.map(\.title),
            [strings.openInNewTab, strings.openInNewPrivateTab, strings.bookmarkLink, strings.copyLink, strings.shareLink]
        )
    }

    func test_contextMenuInteraction_menuTitleIsSourceHost() throws {
        let subject = createSubject()

        let menu = try makeMenu(from: subject)

        XCTAssertEqual(menu.title, "example.com")
    }

    func test_contextMenuInteraction_stashesSourceURLOnIdentifier() throws {
        let subject = createSubject()

        let configuration = try makeConfiguration(from: subject)

        XCTAssertEqual(configuration.identifier as? NSURL, sourceURL as NSURL)
    }

    func test_contextMenuInteraction_withSourceWithoutURL_returnsNil() throws {
        let subject = createSubject(sources: [makeSource(url: nil)])
        let row = try XCTUnwrap(findSubview(of: QuickAnswersSourceRow.self, in: subject))
        let interaction = try XCTUnwrap(row.interactions.first as? UIContextMenuInteraction)

        let configuration = subject.contextMenuInteraction(interaction, configurationForMenuAtLocation: .zero)

        XCTAssertNil(configuration)
    }

    // MARK: - Menu actions
    func test_openInNewTabAction_reportsOpenInNewTab() throws {
        let subject = createSubject()

        try makeActions(from: subject)[0].trigger()

        XCTAssertEqual(menuActions, [.openInNewTab(sourceURL)])
    }

    func test_openInNewPrivateTabAction_reportsOpenInNewPrivateTab() throws {
        let subject = createSubject()

        try makeActions(from: subject)[1].trigger()

        XCTAssertEqual(menuActions, [.openInNewPrivateTab(sourceURL)])
    }

    func test_bookmarkAction_reportsBookmarkWithSourceTitle() throws {
        let subject = createSubject()

        try makeActions(from: subject)[2].trigger()

        XCTAssertEqual(menuActions, [.bookmark(url: sourceURL, title: sourceTitle)])
    }

    func test_copyLinkAction_writesURLToPasteboardAndReportsLinkCopied() throws {
        let subject = createSubject()

        try makeActions(from: subject)[3].trigger()

        XCTAssertEqual(pasteboardURLs, [sourceURL])
        XCTAssertEqual(menuActions, [.linkCopied])
    }

    func test_shareLinkAction_reportsShareLinkAnchoredToRow() throws {
        let subject = createSubject()
        let row = try XCTUnwrap(findSubview(of: QuickAnswersSourceRow.self, in: subject))

        try makeActions(from: subject)[4].trigger()

        XCTAssertEqual(menuActions, [.shareLink(sourceURL, sourceView: row)])
    }

    // MARK: - Helpers
    private func createSubject(
        sources: [SearchResult.Source]? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> QuickAnswersSourceView {
        let subject = QuickAnswersSourceView()
        subject.configureStrings(sourcesHeader: "Sources", citationMenu: .mock)
        subject.writeToPasteboard = { [weak self] in
            self?.pasteboardURLs.append($0)
        }
        subject.configure(
            with: sources ?? [makeSource(url: sourceURL)],
            onMenuAction: { [weak self] in
                self?.menuActions.append($0)
            }
        )
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func makeSource(url: URL?) -> SearchResult.Source {
        return SearchResult.Source(title: sourceTitle, url: url, thumbnailURL: nil, faviconURL: nil)
    }

    private func makeConfiguration(from subject: QuickAnswersSourceView) throws -> UIContextMenuConfiguration {
        let row = try XCTUnwrap(findSubview(of: QuickAnswersSourceRow.self, in: subject))
        let interaction = try XCTUnwrap(row.interactions.first as? UIContextMenuInteraction)
        return try XCTUnwrap(subject.contextMenuInteraction(interaction, configurationForMenuAtLocation: .zero))
    }

    private func makeMenu(from subject: QuickAnswersSourceView) throws -> UIMenu {
        let actionProvider = try XCTUnwrap(makeConfiguration(from: subject).actionProvider)
        return try XCTUnwrap(actionProvider([]))
    }

    private func makeActions(from subject: QuickAnswersSourceView) throws -> [UIAction] {
        return try makeMenu(from: subject).children.compactMap { $0 as? UIAction }
    }

    private func findSubview<T: UIView>(of type: T.Type, in view: UIView) -> T? {
        if let match = view as? T { return match }
        for subview in view.subviews {
            if let match = findSubview(of: type, in: subview) { return match }
        }
        return nil
    }
}
