// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


import MozillaAppServices

class TabMetadataManager {
    
    let profile: Profile?
    
    // Tab Groups
    var tabGroupData = TabGroupData()
    var tabGroupsTimerHelper = StopWatchTimer()
    var shouldResetTabGroupData = false
    
    private var shouldUpdateObservationForState: Bool {
        tabGroupData.tabHistoryCurrentState == TabGroupTimerState.navSearchLoaded.rawValue ||
        tabGroupData.tabHistoryCurrentState == TabGroupTimerState.tabNavigatedToDifferentUrl.rawValue ||
        tabGroupData.tabHistoryCurrentState == TabGroupTimerState.openInNewTab.rawValue ||
        tabGroupData.tabHistoryCurrentState == TabGroupTimerState.openURLOnly.rawValue
    }
    
    init(profile: Profile) {
        self.profile = profile
    }
    
    // Only update search term data with valid search term data
    func shouldUpdateSearchTermData(webViewUrl: String?) -> Bool {
        guard let nextUrl = webViewUrl, !nextUrl.isEmpty else { return false }
        
        return !tabGroupData.tabAssociatedSearchTerm.isEmpty &&
        !tabGroupData.tabAssociatedSearchUrl.isEmpty &&
        nextUrl != tabGroupData.tabAssociatedSearchUrl &&
        nextUrl != tabGroupData.tabAssociatedNextUrl
    }

    func updateTimerAndObserving(state: TabGroupTimerState,
                                 searchData: TabGroupData = TabGroupData(),
                                 tabTitle: String? = nil) {
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
    /// - Parameter title: Tab title
    func updateObservationTitle(_ title: String) {
        guard shouldUpdateObservationForState else { return }
        
        let key = tabGroupData.tabHistoryMetadatakey()
        let observation = HistoryMetadataObservation(url: key.url,
                                                     referrerUrl: key.referrerUrl,
                                                     searchTerm: key.searchTerm,
                                                     viewTime: nil,
                                                     documentType: nil,
                                                     title: title)
        updateObservationForKey(key: key, observation: observation)
    }
    
    func updateObservationViewTime() {
        let key = tabGroupData.tabHistoryMetadatakey()
        let observation = HistoryMetadataObservation(url: key.url,
                                                     referrerUrl: key.referrerUrl,
                                                     searchTerm: key.searchTerm,
                                                     viewTime: tabGroupsTimerHelper.elapsedTime,
                                                     documentType: nil,
                                                     title: nil)
        updateObservationForKey(key: key, observation: observation)
    }
    
    // MARK: - Private
    
    private func updateObservationForKey(key: HistoryMetadataKey,
                                         observation: HistoryMetadataObservation) {
        if let profile = profile {
            _ = profile.places.noteHistoryMetadataObservation(key: key, observation: observation)
        }
    }
    
    private func updateNavSearchLoadedState(searchData: TabGroupData) {
        shouldResetTabGroupData = false
        tabGroupsTimerHelper.startOrResume()
        tabGroupData = searchData
        tabGroupData.tabHistoryCurrentState = TabGroupTimerState.navSearchLoaded.rawValue
    }
    
    private func updateNewTabState(searchData: TabGroupData) {
        shouldResetTabGroupData = false
        tabGroupsTimerHelper.resetTimer()
        tabGroupsTimerHelper.startOrResume()
        tabGroupData.tabHistoryCurrentState = TabGroupTimerState.newTab.rawValue
    }
    
    private func updateNavigatedToDifferentUrl(searchData: TabGroupData) {
        if !tabGroupData.tabAssociatedNextUrl.isEmpty && tabGroupData.tabAssociatedSearchUrl.isEmpty || shouldResetTabGroupData {
            // reset tab group
            tabGroupData = TabGroupData()
            shouldResetTabGroupData = true
        // To also capture any server redirects we check if user spent less than 7 sec on the same website before moving to another one
        } else if tabGroupData.tabAssociatedNextUrl.isEmpty || tabGroupsTimerHelper.elapsedTime < 7 {
            let key = tabGroupData.tabHistoryMetadatakey()
            if key.referrerUrl != searchData.tabAssociatedNextUrl {
                updateObservationViewTime()
                tabGroupData.tabAssociatedNextUrl = searchData.tabAssociatedNextUrl
            }
            tabGroupsTimerHelper.resetTimer()
            tabGroupsTimerHelper.startOrResume()
            tabGroupData.tabHistoryCurrentState = TabGroupTimerState.tabNavigatedToDifferentUrl.rawValue
        }
    }
    
    private func updateTabSelected(searchData: TabGroupData) {
        if !shouldResetTabGroupData {
            if tabGroupsTimerHelper.isPaused {
                tabGroupsTimerHelper.startOrResume()
            }
            tabGroupData.tabHistoryCurrentState = TabGroupTimerState.tabSelected.rawValue
        }
    }
    
    private func updateTabSwitched(searchData: TabGroupData) {
        if !shouldResetTabGroupData {
            updateObservationViewTime()
            tabGroupsTimerHelper.pauseOrStop()
            tabGroupData.tabHistoryCurrentState = TabGroupTimerState.tabSwitched.rawValue
        }
    }
    
    private func updateOpenInNewTab(searchData: TabGroupData) {
        shouldResetTabGroupData = false
        if !searchData.tabAssociatedSearchUrl.isEmpty {
            tabGroupData = searchData
        }
        tabGroupData.tabHistoryCurrentState = TabGroupTimerState.openInNewTab.rawValue
    }
    
    /// Called update observation for Regular sites
    /// if the title isEmpty we abort recording because it can't be overriden
    /// - Parameters:
    ///   - url: Site URL from webview
    ///   - title: Site title from webview can be empty for slow loading pages
    private func updateOpenURLOnlyState(searchData: TabGroupData, title: String?) {
        tabGroupData = searchData
        tabGroupData.tabHistoryCurrentState = TabGroupTimerState.openURLOnly.rawValue
        tabGroupsTimerHelper.startOrResume()
        
        guard let title = title, !title.isEmpty else { return }

        updateObservationTitle(title)
    }
}
