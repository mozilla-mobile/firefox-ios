/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/// Describes the main views of the Library Panel using an enum with
/// an associated value as each main state may have different substates.
enum LibraryPanelMainState: Equatable {
    case bookmarks(state: LibraryPanelSubState)
    case history(state: LibraryPanelSubState)
    case downloads(state: LibraryPanelSubState)
    case readingList(state: LibraryPanelSubState)
    
    static func ==(lhs: LibraryPanelMainState, rhs: LibraryPanelMainState) -> Bool {
        switch (lhs, rhs) {
        case (let .bookmarks(subState1), let .bookmarks(subState2)):
            return subState1 == subState2
        case (let .history(subState1), let .history(subState2)):
            return subState1 == subState2
        case (let .downloads(subState1), let .downloads(subState2)):
            return subState1 == subState2
        case (let .readingList(subState1), let .readingList(subState2)):
            return subState1 == subState2
        default:
            return false
        }
    }

    func panelIsDifferentFrom(_ newState: LibraryPanelMainState) -> Bool {
        switch (self, newState) {
        case (.bookmarks(_), .bookmarks(_)),
             (.history(_), .history(_)),
             (.downloads(_), .downloads(_)),
             (.readingList(_), .readingList(_)):
            return false
        default:
            return true
        }
    }
}

/// Describes the available substates for LibaryPanel states. These are universal
/// and thus can be used on each particular panel to describe it's current state.
enum LibraryPanelSubState {
    case mainView
    case inFolder
    case inFolderEditMode
    case itemEditMode

    func isParentState(of oldState: LibraryPanelSubState) -> Bool {
        switch self {
        case .mainView:
            if oldState == .inFolder { return true }
        case .inFolder:
            if oldState == .inFolderEditMode { return true }
        case .inFolderEditMode:
            if oldState == .itemEditMode { return true }
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
        case .itemEditMode:
            if oldState == .inFolderEditMode { return true }
        default:
            return false
        }
        return false
    }
}

/// The `LibraryPanelViewState` class is a state machine that will keep track of the
/// current state of each panel of the Library Panel. The current state is accessed/updated
/// through the `currentState` variable, which will ensure that specific substates for each
/// are preserved.
class LibraryPanelViewState {
    private var state: LibraryPanelMainState = .bookmarks(state: .mainView)
    var currentState: LibraryPanelMainState {
        get { return state }
        set {
            updateState(to: newValue)
        }
    }

    private var bookmarksState: LibraryPanelMainState = .bookmarks(state: .mainView)
    private var historyState: LibraryPanelMainState = .history(state: .mainView)
    private var downloadsState: LibraryPanelMainState = .downloads(state: .mainView)
    private var readingListState: LibraryPanelMainState = .readingList(state: .mainView)

    private func updateState(to newState: LibraryPanelMainState) {
        let changingPanels = state.panelIsDifferentFrom(newState)
        storeCurrentState()
        switch newState {
        case .bookmarks(let newSubviewState):
            guard case .bookmarks(let oldSubviewState) = bookmarksState else { return }
            updateStateVariables(for: newState,
                                 andCategory: bookmarksState,
                                 with: newSubviewState,
                                 and: oldSubviewState,
                                 isChangingPanels: changingPanels)

        case .history(let newSubviewState):
            guard case .history(let oldSubviewState) = historyState else { return }
            updateStateVariables(for: newState,
                                 andCategory: historyState,
                                 with: newSubviewState,
                                 and: oldSubviewState,
                                 isChangingPanels: changingPanels)

        case .downloads(let newSubviewState):
            guard case .downloads(let oldSubviewState) = downloadsState else { return }
            updateStateVariables(for: newState,
                                 andCategory: downloadsState,
                                 with: newSubviewState,
                                 and: oldSubviewState,
                                 isChangingPanels: changingPanels)

        case .readingList(let newSubviewState):
            guard case .readingList(let oldSubviewState) = readingListState else { return }
            updateStateVariables(for: newState,
                                 andCategory: readingListState,
                                 with: newSubviewState,
                                 and: oldSubviewState,
                                 isChangingPanels: changingPanels)
        }
    }

    private func storeCurrentState() {
        switch state {
        case .bookmarks(_):
            bookmarksState = state
        case .history(_):
            historyState = state
        case .downloads(_):
            downloadsState = state
        case .readingList(_):
            readingListState = state
        }
    }

    private func updateStateVariables(for newState: LibraryPanelMainState, andCategory category: LibraryPanelMainState, with newSubviewState: LibraryPanelSubState, and oldSubviewState: LibraryPanelSubState, isChangingPanels: Bool) {
        if isChangingPanels {
            self.state = category
        } else if newSubviewState.isChildState(of: oldSubviewState) || newSubviewState.isParentState(of: oldSubviewState) || oldSubviewState == newSubviewState {
            self.state = newState
        }

    }
}
