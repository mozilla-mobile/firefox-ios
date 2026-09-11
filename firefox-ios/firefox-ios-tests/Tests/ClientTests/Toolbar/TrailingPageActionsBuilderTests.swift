// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest
import Common
@testable import Client

@MainActor
final class TrailingPageActionsBuilderTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies(injectedTabManager: MockTabManager())
        setIsHostedSummarizerFeatureEnabled(enabled: false)
        setIsSummarizerLanguageExpansionEnabled(enabled: false)
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - Guard: editing / empty search

    func testGetActions_whenEditing_returnsNoActions() {
        let actions = subject(isEditing: true, isEmptySearch: false)

        XCTAssertTrue(actions.isEmpty)
    }

    func testGetActions_whenEmptySearch_returnsNoActions() {
        let actions = subject(isEditing: false, isEmptySearch: true)

        XCTAssertTrue(actions.isEmpty)
    }

    // MARK: - Reader mode

    func testGetActions_whenReaderModeActive_returnsSelectedReaderModeAction() {
        let actions = subject(readerModeState: .active)

        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(actions[0].actionType, .readerMode)
        XCTAssertEqual(actions[0].isSelected, true)
    }

    func testGetActions_whenReaderModeAvailable_returnsUnselectedReaderModeAction() {
        let actions = subject(readerModeState: .available)

        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(actions[0].actionType, .readerMode)
        XCTAssertEqual(actions[0].isSelected, false)
    }

    func testGetActions_whenReaderModeStateIsNil_returnsNoReaderModeAction() {
        let actions = subject(readerModeState: nil, canSummarize: false, isLoading: nil)

        XCTAssertTrue(actions.isEmpty)
    }

    // MARK: - Summarizer

    func testGetActions_whenReaderModeWithSummarizerEnabled_returnsReaderModeWithSummarizerAction() {
        setIsSummarizerLanguageExpansionEnabled(enabled: true)

        let actions = subject(readerModeState: .active, canSummarize: true)

        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(actions[0].actionType, .readerModeWithSummarizer)
    }

    func testGetActions_whenReaderModeWithSummarizerEnabled_takesPriorityOverPlainReaderMode() {
        setIsSummarizerLanguageExpansionEnabled(enabled: true)

        let actions = subject(readerModeState: .active, canSummarize: true)

        XCTAssertFalse(actions.contains { $0.actionType == .readerMode })
    }

    // Assumes the test runs in portrait (isSummarizeFeatureForToolbarOn's branch also checks
    // `!UIWindow.isLandscape`); CI simulators default to portrait.
    func testGetActions_whenSummarizeToolbarButtonEnabled_returnsSummaryAction() {
        setIsHostedSummarizerFeatureEnabled(enabled: true)

        let actions = subject(readerModeState: .available, canSummarize: true)

        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(actions[0].actionType, .summarizer)
    }

    func testGetActions_whenCanSummarizeFalse_doesNotReturnSummaryAction() {
        setIsHostedSummarizerFeatureEnabled(enabled: true)

        let actions = subject(readerModeState: .available, canSummarize: false)

        XCTAssertFalse(actions.contains { $0.actionType == .summarizer })
    }

    // MARK: - Loading

    func testGetActions_whenLoadingTrue_appendsStopLoadingAction() {
        let actions = subject(readerModeState: nil, canSummarize: false, isLoading: true)

        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(actions[0].actionType, .stopLoading)
    }

    func testGetActions_whenLoadingFalse_appendsReloadAction() {
        let actions = subject(readerModeState: nil, canSummarize: false, isLoading: false)

        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(actions[0].actionType, .reload)
    }

    func testGetActions_whenLoadingNil_appendsNeitherReloadNorStopAction() {
        let actions = subject(readerModeState: nil, canSummarize: false, isLoading: nil)

        XCTAssertTrue(actions.isEmpty)
    }

    func testGetActions_combinesReaderModeAndLoadingActions() {
        let actions = subject(readerModeState: .available, canSummarize: false, isLoading: false)

        XCTAssertEqual(actions.count, 2)
        XCTAssertEqual(actions[0].actionType, .readerMode)
        XCTAssertEqual(actions[1].actionType, .reload)
    }

    // MARK: - Alternative location color

    func testGetActions_whenHasAlternativeLocationColorTrue_disablesCustomColor() {
        let actions = subject(readerModeState: nil,
                              canSummarize: false,
                              isLoading: false,
                              hasAlternativeLocationColor: true)

        XCTAssertEqual(actions[0].hasCustomColor, false)
    }

    func testGetActions_whenHasAlternativeLocationColorFalse_enablesCustomColor() {
        let actions = subject(readerModeState: nil,
                              canSummarize: false,
                              isLoading: false,
                              hasAlternativeLocationColor: false)

        XCTAssertEqual(actions[0].hasCustomColor, true)
    }

    // MARK: - Helpers

    @MainActor
    private func subject(
        isEditing: Bool = false,
        isEmptySearch: Bool = false,
        readerModeState: ReaderModeState? = nil,
        canSummarize: Bool = false,
        isLoading: Bool? = nil,
        hasAlternativeLocationColor: Bool = false
    ) -> [ToolbarActionConfiguration] {
        TrailingPageActionsBuilder.getActions(
            isEditing: isEditing,
            isEmptySearch: isEmptySearch,
            readerModeState: readerModeState,
            canSummarize: canSummarize,
            isLoading: isLoading,
            hasAlternativeLocationColor: hasAlternativeLocationColor
        )
    }

    private func setIsHostedSummarizerFeatureEnabled(enabled: Bool) {
        FxNimbus.shared.features.hostedSummarizerFeature.with { _, _ in
            return HostedSummarizerFeature(enabled: enabled, toolbarEntrypoint: enabled)
        }
    }

    private func setIsSummarizerLanguageExpansionEnabled(enabled: Bool) {
        FxNimbus.shared.features.summarizerLanguageExpansionFeature.with { _, _ in
            return SummarizerLanguageExpansionFeature(enabled: enabled)
        }
    }
}
