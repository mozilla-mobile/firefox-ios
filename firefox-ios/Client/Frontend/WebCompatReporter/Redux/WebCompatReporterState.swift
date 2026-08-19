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
    var shouldDismiss: Bool
    /// The report as the middleware would send it.
    var previewPayload: WebCompatReportPayload?
    var pageContext: WebCompatPageContext?

    var showsAdditionalDetails: Bool { selectedCategory != nil }
    var isURLValid: Bool { WebCompatURLValidator.isReportable(url) }

    var canPreview: Bool { selectedCategory != nil && isURLValid }

    var showsURLError: Bool {
        return !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isURLValid
    }

    /// Send needs a reportable address and a sub-option, except for "Other", which has none.
    var canSubmit: Bool {
        guard let selectedCategory, isURLValid else { return false }
        return selectedCategory.subOptions.isEmpty || selectedSubOptionID != nil
    }

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
            includeBlockedList: state.includeBlockedList,
            shouldDismiss: state.shouldDismiss,
            previewPayload: state.previewPayload,
            pageContext: state.pageContext
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
            includeBlockedList: true,
            shouldDismiss: false,
            previewPayload: nil,
            pageContext: nil
        )
    }

    init(windowUUID: WindowUUID,
         url: String,
         selectedCategory: WebCompatIssueCategory?,
         selectedSubOptionID: String?,
         additionalDetails: String,
         includeScreenshot: Bool,
         includeBlockedList: Bool,
         shouldDismiss: Bool,
         previewPayload: WebCompatReportPayload?,
         pageContext: WebCompatPageContext?) {
        self.windowUUID = windowUUID
        self.url = url
        self.selectedCategory = selectedCategory
        self.selectedSubOptionID = selectedSubOptionID
        self.additionalDetails = additionalDetails
        self.includeScreenshot = includeScreenshot
        self.includeBlockedList = includeBlockedList
        self.shouldDismiss = shouldDismiss
        self.previewPayload = previewPayload
        self.pageContext = pageContext
    }

    static let reducer: Reducer<Self> = (legacyReducer, modernReducer)

    static let modernReducer: ReducerMethod<Self> = { state, action, actionWindowUUID in
        // Does not handle any modern actions
        return defaultState(from: state)
    }

    static let legacyReducer: LegacyReducerMethod<Self> = { state, action in
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
            return state
                .resetTransientState()
                .copy(url: action.url ?? state.url)
        case WebCompatReporterMiddlewareActionType.didReadPageContext:
            return state
                .resetTransientState()
                .copy(pageContext: action.pageContext)
        case WebCompatReporterMiddlewareActionType.didBuildPreview:
            return state
                .resetTransientState()
                .copy(previewPayload: action.previewPayload)
        case WebCompatReporterMiddlewareActionType.didSubmit:
            return state
                .resetTransientState()
                .copy(shouldDismiss: true)
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
            return state
                .resetTransientState()
                .copy(url: action.url ?? state.url)

        case WebCompatReporterViewActionType.selectCategory:
            guard let category = action.category, category != state.selectedCategory else {
                return defaultState(from: state)
            }
            // A new category clears the previous sub-option.
            return state
                .resetTransientState()
                .copy(selectedCategory: category)
                .copy(selectedSubOptionID: nil)

        case WebCompatReporterViewActionType.selectSubOption:
            return state
                .resetTransientState()
                .copy(selectedSubOptionID: action.subOptionID)

        case WebCompatReporterViewActionType.setAdditionalDetails:
            return state
                .resetTransientState()
                .copy(additionalDetails: action.additionalDetails ?? state.additionalDetails)

        case WebCompatReporterViewActionType.toggleScreenshot:
            return state
                .resetTransientState()
                .copy(includeScreenshot: action.includeScreenshot ?? !state.includeScreenshot)

        case WebCompatReporterViewActionType.toggleBlockedList:
            return state
                .resetTransientState()
                .copy(includeBlockedList: action.includeBlockedList ?? !state.includeBlockedList)

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
            includeBlockedList: state.includeBlockedList,
            shouldDismiss: false,
            previewPayload: nil,
            pageContext: state.pageContext
        )
    }
}
