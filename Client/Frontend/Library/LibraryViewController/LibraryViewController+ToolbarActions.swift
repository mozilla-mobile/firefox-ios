// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// MARK: - Toolbar Button Actions
extension LibraryViewController {
    @objc func bottomLeftButtonAction() {
        guard let panel = children.first as? UINavigationController else { return }
        switch viewModel.currentPanelState {
        case .bookmarks(state: let state):
            leftButtonBookmarkActions(for: state, onPanel: panel)
        default:
            return
        }
        updateViewWithState()
    }

    func leftButtonBookmarkActions(for state: LibraryPanelSubState, onPanel panel: UINavigationController) {

        switch state {
        case .inFolder:
            if panel.viewControllers.count > 1 {
                viewModel.currentPanelState = .bookmarks(state: .mainView)
                panel.popViewController(animated: true)
            }

        case .inFolderEditMode:
            guard let bookmarksPanel = panel.viewControllers.last as? BookmarksPanel else { return }
            bookmarksPanel.presentInFolderActions()

        case .itemEditMode:
            viewModel.currentPanelState = .bookmarks(state: .inFolderEditMode)
            panel.popViewController(animated: true)

        default:
            return
        }
    }

    @objc func bottomRightButtonAction() {
        switch viewModel.currentPanelState {
        case .bookmarks(state: let state):
            rightButtonBookmarkActions(for: state)
        default:
            return
        }
        updateViewWithState()
    }

    func rightButtonBookmarkActions(for state: LibraryPanelSubState) {
        guard let panel = children.first as? UINavigationController else { return }
        switch state {
        case .inFolder:
            guard let bookmarksPanel = panel.viewControllers.last as? BookmarksPanel else { return }
            viewModel.currentPanelState = .bookmarks(state: .inFolderEditMode)
            bookmarksPanel.enableEditMode()

        case .inFolderEditMode:
            guard let bookmarksPanel = panel.viewControllers.last as? BookmarksPanel else { return }
            viewModel.currentPanelState = .bookmarks(state: .inFolder)
            bookmarksPanel.disableEditMode()

        case .itemEditMode:
            guard let bookmarkEditView = panel.viewControllers.last as? BookmarkDetailPanel else { return }
            bookmarkEditView.save().uponQueue(.main) { _ in
                self.viewModel.currentPanelState = .bookmarks(state: .inFolderEditMode)
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

    func rightButtonHistoryActions(for state: LibraryPanelSubState) {
        guard let panel = children.first as? UINavigationController,
              let historyPanel = panel.viewControllers.last as? HistoryPanel else { return }

        historyPanel.exitSearchState()
        viewModel.currentPanelState = .history(state: .mainView)
    }

    @objc func bottomSearchButtonAction() {
        guard let panel = children.first as? UINavigationController,
              let historyPanel = panel.viewControllers.last as? HistoryPanel else { return }

        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .searchHistory)

        viewModel.currentPanelState = .history(state: .search)
        historyPanel.startSearchState()
    }

    @objc func bottomDeleteButtonAction() {
        // Leave search mode when clearing history
        viewModel.currentPanelState = .history(state: .mainView)

        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .deleteHistory)
        NotificationCenter.default.post(name: .OpenClearRecentHistory, object: nil)
    }
}
