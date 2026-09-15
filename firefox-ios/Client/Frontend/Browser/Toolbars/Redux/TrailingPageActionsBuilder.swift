// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit

/// Builds the address bar's trailing page actions (reader mode/summarizer, reload/stop), shown
/// on real websites, not the homepage, and not while editing.
enum TrailingPageActionsBuilder {
    @MainActor
    static func getActions(isEditing: Bool,
                           isEmptySearch: Bool,
                           readerModeState: ReaderModeState?,
                           canSummarize: Bool,
                           isLoading: Bool?,
                           hasAlternativeLocationColor: Bool) -> [ToolbarActionConfiguration] {
        var actions = [ToolbarActionConfiguration]()

        // When the search field is empty or isEditing we show no actions
        guard !isEmptySearch, !isEditing else { return actions }

        let summarizerNimbusUtils = DefaultSummarizerNimbusUtils()
        let isSummarizeFeatureForToolbarOn = summarizerNimbusUtils.isToolbarButtonEnabled
        let isReaderModeWithSummarizerEnabled = summarizerNimbusUtils.isLanguageExpansionEnabled && canSummarize
            && readerModeState?.isEnabled == true
        if isReaderModeWithSummarizerEnabled {
            actions.append(readerModeWithSummarizerAction(isSelected: readerModeState == .active,
                                                          hasAlternativeLocationColor: hasAlternativeLocationColor))
        } else if isSummarizeFeatureForToolbarOn, canSummarize, readerModeState == .available, !UIWindow.isLandscape {
            actions.append(summaryAction(hasAlternativeLocationColor: hasAlternativeLocationColor))
        } else if readerModeState?.isEnabled == true {
            actions.append(readerModeAction(isSelected: readerModeState == .active,
                                            hasAlternativeLocationColor: hasAlternativeLocationColor))
        }

        if isLoading == true {
            actions.append(stopLoadingAction(hasAlternativeLocationColor: hasAlternativeLocationColor))
        } else if isLoading == false {
            actions.append(reloadAction(hasAlternativeLocationColor: hasAlternativeLocationColor))
        }

        return actions
    }

    private static func reloadAction(hasAlternativeLocationColor: Bool) -> ToolbarActionConfiguration {
        return ToolbarActionConfiguration(
            actionType: .reload,
            iconName: StandardImageIdentifiers.Medium.arrowClockwise,
            isEnabled: true,
            hasCustomColor: !hasAlternativeLocationColor,
            a11yLabel: .TabLocationReloadAccessibilityLabel,
            a11yHint: .TabLocationReloadAccessibilityHint,
            a11yId: AccessibilityIdentifiers.Toolbar.reloadButton)
    }

    private static func stopLoadingAction(hasAlternativeLocationColor: Bool) -> ToolbarActionConfiguration {
        return ToolbarActionConfiguration(
            actionType: .stopLoading,
            iconName: StandardImageIdentifiers.Medium.cross,
            isEnabled: true,
            hasCustomColor: !hasAlternativeLocationColor,
            a11yLabel: .TabToolbarStopAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.stopButton)
    }

    private static func summaryAction(hasAlternativeLocationColor: Bool) -> ToolbarActionConfiguration {
        return ToolbarActionConfiguration(
            actionType: .summarizer,
            iconName: StandardImageIdentifiers.Medium.lightning,
            isEnabled: true,
            hasCustomColor: !hasAlternativeLocationColor,
            contextualHintType: ContextualHintType.summarizeToolbarEntry.rawValue,
            a11yLabel: .Toolbars.SummarizeButtonAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.summarizeButton)
    }

    private static func readerModeAction(isSelected: Bool,
                                         hasAlternativeLocationColor: Bool) -> ToolbarActionConfiguration {
        return ToolbarActionConfiguration(
            actionType: .readerMode,
            iconName: StandardImageIdentifiers.Medium.readerView,
            isEnabled: true,
            isSelected: isSelected,
            hasCustomColor: !hasAlternativeLocationColor,
            a11yLabel: .TabLocationReaderModeAccessibilityLabel,
            a11yHint: .TabLocationReloadAccessibilityHint,
            a11yId: AccessibilityIdentifiers.Toolbar.readerModeButton,
            a11yCustomActionName: .TabLocationReaderModeAddToReadingListAccessibilityLabel)
    }

    private static func readerModeWithSummarizerAction(isSelected: Bool,
                                                       hasAlternativeLocationColor: Bool) -> ToolbarActionConfiguration {
        return ToolbarActionConfiguration(
            actionType: .readerModeWithSummarizer,
            iconName: StandardImageIdentifiers.Medium.readerSummarize,
            isEnabled: true,
            isSelected: isSelected,
            hasCustomColor: !hasAlternativeLocationColor,
            a11yLabel: .Toolbars.ReaderModeWithSummarizerButtonAccessibilityLabel,
            a11yHint: .TabLocationReloadAccessibilityHint,
            a11yId: AccessibilityIdentifiers.Toolbar.readerModeWithSummarizerButton
        )
    }
}
