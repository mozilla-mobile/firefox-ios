// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// MARK: - Toolbar Button Actions
extension LibraryViewController {

    func leftButtonBookmarkActions(for state: LibraryPanelSubState, onPanel panel: UINavigationController) {
        print("YRD LibraryViewController leftButtonBookmarkActions")

        switch state {
        case .inFolder:
            if panel.viewControllers.count > 1 {
                // TODO: Yoana update state
//                viewModel.currentPanelState = .bookmarks(state: .mainView)
                panel.popViewController(animated: true)
            }

        case .inFolderEditMode:
            guard let bookmarksPanel = panel.viewControllers.last as? BookmarksPanel else { return }
            bookmarksPanel.presentInFolderActions()

        case .itemEditMode:
            // TODO: Yoana update state
//            viewModel.currentPanelState = .bookmarks(state: .inFolderEditMode)
            panel.popViewController(animated: true)

        default:
            return
        }
    }

    func topRightButtonBookmarkActions(for state: LibraryPanelSubState) {
        print("YRD LibraryViewController rightButtonBookmarkActions")
        guard let panel = children.first as? UINavigationController else { return }
        switch state {
        case .inFolder:
            guard let bookmarksPanel = panel.viewControllers.last as? BookmarksPanel else { return }
//            viewModel.currentPanelState = .bookmarks(state: .inFolderEditMode)
            bookmarksPanel.enableEditMode()

        case .inFolderEditMode:
            guard let bookmarksPanel = panel.viewControllers.last as? BookmarksPanel else { return }
            // TODO: Yoana update state
//            viewModel.currentPanelState = .bookmarks(state: .inFolder)
            bookmarksPanel.disableEditMode()

        case .itemEditMode:
            guard let bookmarkEditView = panel.viewControllers.last as? BookmarkDetailPanel else { return }
            bookmarkEditView.save().uponQueue(.main) { _ in
                // TODO: Yoana update state
//                self.viewModel.currentPanelState = .bookmarks(state: .inFolderEditMode)
                panel.popViewController(animated: true)
                if bookmarkEditView.isNew,
                   let bookmarksPanel = panel.navigationController?.visibleViewController as? BookmarksPanel {
                    bookmarksPanel.didAddBookmarkNode()
                }
            }
        default:
            return
        }
    }

    func topRightButtonHistoryActions(for state: LibraryPanelSubState) {
        guard let panel = children.first as? UINavigationController,
              let historyPanel = panel.viewControllers.last as? HistoryPanel else { return }

        historyPanel.exitSearchState()
//        viewModel.currentPanelState = .history(state: .mainView)
        historyPanel.updatePanelState(newState: .history(state: .mainView))
    }
}
