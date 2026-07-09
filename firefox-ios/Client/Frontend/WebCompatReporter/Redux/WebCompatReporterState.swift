// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ModifiedCopy
import Redux

/// The in-progress "Report a Website Issue" report, held as Redux screen state.
@Copyable
struct WebCompatReporterState: ScreenState, Equatable {
    var windowUUID: WindowUUID
    var url: String
    var selectedCategory: WebCompatIssueCategory?
    var selectedSubOptionID: String?
    var additionalDetails: String
    var includeScreenshot: Bool
    var includeBlockedList: Bool

    /// Preview and Send stay disabled until the user picks a category.
    var canSubmit: Bool { selectedCategory != nil }
    var canPreview: Bool { selectedCategory != nil }

    init(appState: AppState, uuid: WindowUUID) {
        guard let state = appState.componentState(
            WebCompatReporterState.self,
            for: .webCompatReporter,
            window: uuid
        ) else {
            self.init(windowUUID: uuid)
            return
        }
        self.init(
            windowUUID: state.windowUUID,
            url: state.url,
            selectedCategory: state.selectedCategory,
            selectedSubOptionID: state.selectedSubOptionID,
            additionalDetails: state.additionalDetails,
            includeScreenshot: state.includeScreenshot,
            includeBlockedList: state.includeBlockedList
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            url: "",
            selectedCategory: nil,
            selectedSubOptionID: nil,
            additionalDetails: "",
            includeScreenshot: true,
            includeBlockedList: false
        )
    }

    init(windowUUID: WindowUUID,
         url: String,
         selectedCategory: WebCompatIssueCategory? = nil,
         selectedSubOptionID: String? = nil,
         additionalDetails: String = "",
         includeScreenshot: Bool = true,
         includeBlockedList: Bool = false) {
        self.windowUUID = windowUUID
        self.url = url
        self.selectedCategory = selectedCategory
        self.selectedSubOptionID = selectedSubOptionID
        self.additionalDetails = additionalDetails
        self.includeScreenshot = includeScreenshot
        self.includeBlockedList = includeBlockedList
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else {
            return defaultState(from: state)
        }

        switch action {
        case let action as WebCompatReporterMiddlewareAction:
            return reduceMiddlewareAction(state: state, action: action)

        case let action as WebCompatReporterViewAction:
            return reduceViewAction(state: state, action: action)

        default:
            return defaultState(from: state)
        }
    }

    private static func reduceMiddlewareAction(
        state: WebCompatReporterState,
        action: WebCompatReporterMiddlewareAction
    ) -> WebCompatReporterState {
        switch action.actionType {
        case WebCompatReporterMiddlewareActionType.didLoadInitialDraft:
            return state.copy(url: action.url ?? state.url)
        default:
            return defaultState(from: state)
        }
    }

    private static func reduceViewAction(
        state: WebCompatReporterState,
        action: WebCompatReporterViewAction
    ) -> WebCompatReporterState {
        switch action.actionType {
        case WebCompatReporterViewActionType.editURL:
            return state.copy(url: action.url ?? state.url)

        case WebCompatReporterViewActionType.selectCategory:
            guard let category = action.category, category != state.selectedCategory else {
                return defaultState(from: state)
            }
            // A new category clears the previous sub-option.
            return state
                .copy(selectedCategory: category)
                .copy(selectedSubOptionID: nil)

        case WebCompatReporterViewActionType.selectSubOption:
            return state.copy(selectedSubOptionID: action.subOptionID)

        case WebCompatReporterViewActionType.setAdditionalDetails:
            return state.copy(additionalDetails: action.additionalDetails ?? state.additionalDetails)

        case WebCompatReporterViewActionType.toggleScreenshot:
            return state.copy(includeScreenshot: action.includeScreenshot ?? !state.includeScreenshot)

        case WebCompatReporterViewActionType.toggleBlockedList:
            return state.copy(includeBlockedList: action.includeBlockedList ?? !state.includeBlockedList)

        default:
            return defaultState(from: state)
        }
    }

    static func defaultState(from state: WebCompatReporterState) -> WebCompatReporterState {
        return WebCompatReporterState(
            windowUUID: state.windowUUID,
            url: state.url,
            selectedCategory: state.selectedCategory,
            selectedSubOptionID: state.selectedSubOptionID,
            additionalDetails: state.additionalDetails,
            includeScreenshot: state.includeScreenshot,
            includeBlockedList: state.includeBlockedList
        )
    }

    static func == (lhs: WebCompatReporterState, rhs: WebCompatReporterState) -> Bool {
        return lhs.url == rhs.url
            && lhs.selectedCategory == rhs.selectedCategory
            && lhs.selectedSubOptionID == rhs.selectedSubOptionID
            && lhs.additionalDetails == rhs.additionalDetails
            && lhs.includeScreenshot == rhs.includeScreenshot
            && lhs.includeBlockedList == rhs.includeBlockedList
    }
}
