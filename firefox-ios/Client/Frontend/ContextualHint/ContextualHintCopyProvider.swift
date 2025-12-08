// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common

enum ContextualHintCopyType {
    case action, title, description
}

/// `ContextualHintCopyProvider` exists to provide the requested description or action strings back
/// for the specified `ContextualHintType`.
struct ContextualHintCopyProvider: FeatureFlaggable {
    typealias CFRStrings = String.ContextualHints

    /// Arrow direction infuences toolbar copy, so it exists here.
    private var arrowDirection: UIPopoverArrowDirection?
    private let prefs: Prefs

    init(profile: Profile = AppContainer.shared.resolve(),
         arrowDirecton: UIPopoverArrowDirection? = nil) {
        self.arrowDirection = arrowDirecton
        self.prefs = profile.prefs
    }

    // MARK: - Public interface

    /// Returns the copy for the requested part of the CFR (`ContextualHintCopyType`) for the specified
    /// hint.
    ///
    /// - Parameters:
    ///   - copyType: The requested part of the CFR copy to return.
    ///   - hint: The `ContextualHintType` for which a consumer wants copy for.
    /// - Returns: The requested copy.
    func getCopyFor(_ copyType: ContextualHintCopyType, of hint: ContextualHintType) -> String {
        var copyToReturn: String

        switch copyType {
        case .action:
            copyToReturn = getActionCopyFor(hint)
        case .title:
            copyToReturn = getTitleCopyFor(hint)
        case .description:
            copyToReturn = getDescriptionCopyFor(hint)
        }

        return copyToReturn
    }

    // MARK: - Private helpers
    private func getTitleCopyFor(_ hint: ContextualHintType) -> String {
        switch hint {
        case .mainMenu:
            return CFRStrings.MainMenu.MenuRedesign.Title

        case .toolbarUpdate:
            return CFRStrings.Toolbar.ToolbarUpdateTitle

        case .translation:
            return String(format: CFRStrings.Translations.Title, AppName.shortName.rawValue)

        default: return ""
        }
    }

    private func getDescriptionCopyFor(_ hint: ContextualHintType) -> String {
        var descriptionCopy = ""

        switch hint {
        case .dataClearance:
            descriptionCopy = CFRStrings.FeltDeletion.Body

        case .jumpBackIn:
                descriptionCopy = CFRStrings.FirefoxHomepage.JumpBackIn.PersonalizedHome

        case .jumpBackInSyncedTab:
            descriptionCopy = CFRStrings.FirefoxHomepage.JumpBackIn.SyncedTab

        case .mainMenu:
            descriptionCopy = CFRStrings.MainMenu.MenuRedesign.Body

        case .navigation:
            descriptionCopy = CFRStrings.Toolbar.NavigationButtonsBody

        case .relay:
            descriptionCopy = String(format: String.RelayMask.RelayEmailMaskAvailableCFR, AppName.shortName.rawValue)

        case .toolbarUpdate:
            descriptionCopy = CFRStrings.Toolbar.ToolbarUpdateBody

        case .translation:
            descriptionCopy = CFRStrings.Translations.Body

        case .summarizeToolbarEntry:
            descriptionCopy = CFRStrings.Summarize.Description
        }

        return descriptionCopy
    }

    private func getActionCopyFor(_ hint: ContextualHintType) -> String {
        var actionCopy: String

        switch hint {
        case .dataClearance:
            actionCopy = ""
        case .mainMenu:
            actionCopy = ""
        case .jumpBackIn,
                .jumpBackInSyncedTab:
            actionCopy = ""
        case .navigation:
            actionCopy = ""
        case .relay:
            actionCopy = ""
        case .toolbarUpdate:
            actionCopy = ""
        case .translation:
            actionCopy = ""
        case .summarizeToolbarEntry:
            actionCopy = ""
        }

        return actionCopy
    }
}
