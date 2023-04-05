// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Shared
import Storage

class LegacyTabMetadataManager {
    let metadataObserver: HistoryMetadataObserver

    // Tab Groups
    var tabGroupData = LegacyTabGroupData()
    var tabGroupsTimerHelper = StopWatchTimer()
    var shouldResetTabGroupData = false
    let minViewTimeInSeconds = 7

    private var shouldUpdateObservationTitle: Bool {
        tabGroupData.tabHistoryCurrentState == LegacyTabGroupTimerState.navSearchLoaded.rawValue ||
        tabGroupData.tabHistoryCurrentState == LegacyTabGroupTimerState.tabNavigatedToDifferentUrl.rawValue ||
        tabGroupData.tabHistoryCurrentState == LegacyTabGroupTimerState.openURLOnly.rawValue
    }

    init(metadataObserver: HistoryMetadataObserver) {
        self.metadataObserver = metadataObserver
    }

    // Only update search term data with valid search term data
    func shouldUpdateSearchTermData(webViewUrl: String?) -> Bool {
        guard let nextUrl = webViewUrl, !nextUrl.isEmpty else { return false }

        return !tabGroupData.tabAssociatedSearchTerm.isEmpty &&
        !tabGroupData.tabAssociatedSearchUrl.isEmpty &&
        nextUrl != tabGroupData.tabAssociatedSearchUrl &&
        nextUrl != tabGroupData.tabAssociatedNextUrl
    }

    func updateTimerAndObserving(state: LegacyTabGroupTimerState,
                                 searchData: LegacyTabGroupData = LegacyTabGroupData(),
                                 tabTitle: String? = nil, isPrivate: Bool) {
        guard !isPrivate else { return }

        switch state {
        case .navSearchLoaded:
            updateNavSearchLoadedState(searchData: searchData)
        case .newTab:
            updateNewTabState(searchData: searchData)
        case .tabNavigatedToDifferentUrl:
            updateNavigatedToDifferentUrl(searchData: searchData)
        case .tabSelected:
            updateTabSelected(searchData: searchData)
        case .tabSwitched:
            updateTabSwitched(searchData: searchData)
        case .openInNewTab:
            updateOpenInNewTab(searchData: searchData)
        case .openURLOnly:
            updateOpenURLOnlyState(searchData: searchData, title: tabTitle)
        case .none:
            tabGroupData.tabHistoryCurrentState = state.rawValue
        }
    }

    /// Update existing or new observation with title once it changes for certain tab states title becomes available
    /// - Parameters:
    ///   - title: Title to be saved
    ///   - completion: Completion handler that gets called once the recording is done. Initially used only for Unit test
    func updateObservationTitle(_ title: String, completion: (() -> Void)? = nil) {
        guard shouldUpdateObservationTitle else {
            completion?()
            return
        }

        let key = tabGroupData.tabHistoryMetadatakey()
        let observation = HistoryMetadataObservation(url: key.url,
                                                     referrerUrl: key.referrerUrl,
                                                     searchTerm: key.searchTerm,
                                                     viewTime: nil,
                                                     documentType: nil,
                                                     title: title)
        updateObservationForKey(key: key, observation: observation, completion: completion)
    }

    func updateObservationViewTime(completion: (() -> Void)? = nil) {
        let key = tabGroupData.tabHistoryMetadatakey()
        let observation = HistoryMetadataObservation(url: key.url,
                                                     referrerUrl: key.referrerUrl,
                                                     searchTerm: key.searchTerm,
                                                     viewTime: tabGroupsTimerHelper.elapsedTime,
                                                     documentType: nil,
                                                     title: nil)
        updateObservationForKey(key: key, observation: observation, completion: completion)
    }

    // MARK: - Private

    private func updateObservationForKey(key: HistoryMetadataKey,
                                         observation: HistoryMetadataObservation,
                                         completion: (() -> Void)?) {
        // If URL is empty or a session restore URL, do not record in metadata observation
        let sessionRestoreURL = "\(InternalURL.baseUrl)/\(SessionRestoreHandler.path)"
        guard !key.url.isEmpty, !key.url.contains(sessionRestoreURL) else {
            completion?()
            return
        }

        metadataObserver.noteHistoryMetadataObservation(key: key, observation: observation) {
            completion?()
        }
    }

    private func updateNavSearchLoadedState(searchData: LegacyTabGroupData) {
        shouldResetTabGroupData = false
        tabGroupsTimerHelper.startOrResume()
        tabGroupData = searchData
        tabGroupData.tabHistoryCurrentState = LegacyTabGroupTimerState.navSearchLoaded.rawValue
    }

    private func updateNewTabState(searchData: LegacyTabGroupData) {
        shouldResetTabGroupData = false
        tabGroupsTimerHelper.resetTimer()
        tabGroupsTimerHelper.startOrResume()
        tabGroupData.tabHistoryCurrentState = LegacyTabGroupTimerState.newTab.rawValue
    }

    private func updateNavigatedToDifferentUrl(searchData: LegacyTabGroupData) {
        if !tabGroupData.tabAssociatedNextUrl.isEmpty && tabGroupData.tabAssociatedSearchUrl.isEmpty || shouldResetTabGroupData {
            // reset tab group
            tabGroupData = LegacyTabGroupData()
            shouldResetTabGroupData = true
        // To also capture any server redirects we check if user spent less than 7 sec on the same website before moving to another one
        } else if tabGroupData.tabAssociatedNextUrl.isEmpty || tabGroupsTimerHelper.elapsedTime < minViewTimeInSeconds {
            let key = tabGroupData.tabHistoryMetadatakey()
            if key.referrerUrl != searchData.tabAssociatedNextUrl {
                updateObservationViewTime()
                tabGroupData.tabAssociatedNextUrl = searchData.tabAssociatedNextUrl
            }
            tabGroupsTimerHelper.resetTimer()
            tabGroupsTimerHelper.startOrResume()
            tabGroupData.tabHistoryCurrentState = LegacyTabGroupTimerState.tabNavigatedToDifferentUrl.rawValue
        }
    }

    private func updateTabSelected(searchData: LegacyTabGroupData) {
        if !shouldResetTabGroupData {
            if tabGroupsTimerHelper.isPaused {
                tabGroupsTimerHelper.startOrResume()
            }
            tabGroupData.tabHistoryCurrentState = LegacyTabGroupTimerState.tabSelected.rawValue
        }
    }

    private func updateTabSwitched(searchData: LegacyTabGroupData) {
        if !shouldResetTabGroupData {
            updateObservationViewTime()
            tabGroupsTimerHelper.pauseOrStop()
            tabGroupData.tabHistoryCurrentState = LegacyTabGroupTimerState.tabSwitched.rawValue
        }
    }

    private func updateOpenInNewTab(searchData: LegacyTabGroupData) {
        shouldResetTabGroupData = false
        if !searchData.tabAssociatedSearchUrl.isEmpty {
            tabGroupData = searchData
        }
        tabGroupData.tabHistoryCurrentState = LegacyTabGroupTimerState.openInNewTab.rawValue
    }

    /// Update observation for Regular sites (not search term)
    /// if the title isEmpty we don't record because title can be overriden
    /// - Parameters:
    ///   - searchData: Tab Group Data
    ///   - title: Site title from webview can be empty for slow loading pages
    private func updateOpenURLOnlyState(searchData: LegacyTabGroupData, title: String?) {
        tabGroupData = searchData
        tabGroupData.tabHistoryCurrentState = LegacyTabGroupTimerState.openURLOnly.rawValue
        tabGroupsTimerHelper.startOrResume()

        guard let title = title, !title.isEmpty else { return }

        updateObservationTitle(title)
    }
}
