// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Describes the main views of the Library Panel using an enum with
/// an associated value as each main state may have different substates.
enum LibraryPanelMainState: Equatable {
    case bookmarks(state: LibraryPanelSubState)
    case history(state: LibraryPanelSubState)
    case downloads
    case readingList

    // When comparing states, we must also ensure we're comparing substates,
    // in the cases where they are present.
    static func == (lhs: LibraryPanelMainState, rhs: LibraryPanelMainState) -> Bool {
        switch (lhs, rhs) {
        case (let .bookmarks(subState1), let .bookmarks(subState2)),
             (let .history(subState1), let .history(subState2)):
            return subState1 == subState2
        case (.downloads, .downloads),
             (.readingList, .readingList):
            return true
        default:
            return false
        }
    }

    // Allows detecting whether we're changing main panels or not
    func panelIsDifferentFrom(_ newState: LibraryPanelMainState) -> Bool {
        switch (self, newState) {
        case (.bookmarks, .bookmarks),
             (.history, .history),
             (.downloads, .downloads),
             (.readingList, .readingList):
            return false
        default:
            return true
        }
    }
}

/// Describes the available substates for LibraryPanel states. These are universal
/// and thus can be used on each particular panel to describe it's current state.
enum LibraryPanelSubState {
    case mainView
    case inFolder
    case inFolderEditMode
    case itemEditMode
    case itemEditModeInvalidField
    case search

    // The following two functions enable checking that substate moves are legal.
    // For example, you can move from .mainView to .inFolder, but not from
    // .mainView to .inFolderEditMode

    func isParentState(of oldState: LibraryPanelSubState) -> Bool {
        switch self {
        case .mainView:
            if oldState == .inFolder { return true }
        case .inFolder:
            if oldState == .inFolderEditMode { return true }
        case .inFolderEditMode:
            if oldState == .itemEditMode || oldState == .itemEditModeInvalidField { return true }
        default:
            return false
        }
        return false
    }

    func isChildState(of oldState: LibraryPanelSubState) -> Bool {
        switch self {
        case .inFolder:
            if oldState == .mainView { return true }
        case .inFolderEditMode:
            if oldState == .inFolder { return true }
        case .itemEditMode, .itemEditModeInvalidField:
            if oldState == .inFolderEditMode { return true }
        default:
            return false
        }
        return false
    }
}
