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

    func updateTimerAndObserving(state: TabGroupTimerState, searchTerm: String? = nil, searchProviderUrl: String? = nil, nextUrl: String = "", tabTitle: String? = "") {
        switch state {
        case .navSearchLoaded:
            shouldResetTabGroupData = false
            tabGroupsTimerHelper.startOrResume()
            tabGroupData.tabAssociatedSearchUrl = searchProviderUrl ?? ""
            tabGroupData.tabAssociatedSearchTerm = searchTerm ?? ""
            tabGroupData.tabAssociatedNextUrl = nextUrl
            tabGroupData.tabHistoryCurrentState = state.rawValue
        case .newTab:
            shouldResetTabGroupData = false
            tabGroupsTimerHelper.resetTimer()
            tabGroupsTimerHelper.startOrResume()
            tabGroupData.tabHistoryCurrentState = state.rawValue
        case .tabNavigatedToDifferentUrl:
            if !tabGroupData.tabAssociatedNextUrl.isEmpty && tabGroupData.tabAssociatedSearchUrl.isEmpty || shouldResetTabGroupData {
                // reset tab group
                tabGroupData = TabGroupData()
                shouldResetTabGroupData = true
            // To also capture any server redirects we check if user spent less than 7 sec on the same website before moving to another one
            } else if tabGroupData.tabAssociatedNextUrl.isEmpty || tabGroupsTimerHelper.elapsedTime < 7 {
                let key = tabGroupData.tabHistoryMetadatakey()
                if key.referrerUrl != nextUrl {
                    let observation = HistoryMetadataObservation(url: key.url, referrerUrl: key.referrerUrl, searchTerm: key.searchTerm, viewTime: tabGroupsTimerHelper.elapsedTime, documentType: nil, title: nil)
                    updateObservationForKey(key: key, observation: observation)
                    tabGroupData.tabAssociatedNextUrl = nextUrl
                }
                tabGroupsTimerHelper.resetTimer()
                tabGroupsTimerHelper.startOrResume()
                tabGroupData.tabHistoryCurrentState = state.rawValue
            }
        case .tabSelected:
            if !shouldResetTabGroupData {
                if tabGroupsTimerHelper.isPaused {
                    tabGroupsTimerHelper.startOrResume()
                }
                tabGroupData.tabHistoryCurrentState = state.rawValue
            }
        case .tabSwitched:
            if !shouldResetTabGroupData {
                let key = tabGroupData.tabHistoryMetadatakey()
                let observation = HistoryMetadataObservation(url: key.url, referrerUrl: key.referrerUrl, searchTerm: key.searchTerm, viewTime: tabGroupsTimerHelper.elapsedTime, documentType: nil, title: nil)
                updateObservationForKey(key: key, observation: observation)
                tabGroupsTimerHelper.pauseOrStop()
                tabGroupData.tabHistoryCurrentState = state.rawValue
            }
        case .openInNewTab:
            shouldResetTabGroupData = false
            if let searchUrl = searchProviderUrl {
                tabGroupData.tabAssociatedSearchUrl = searchUrl
                tabGroupData.tabAssociatedSearchTerm = searchTerm ?? ""
                tabGroupData.tabAssociatedNextUrl = nextUrl
            }
            tabGroupData.tabHistoryCurrentState = state.rawValue
        case .openURLOnly:
            tabGroupData.tabAssociatedSearchUrl = searchProviderUrl ?? ""
            tabGroupData.tabAssociatedSearchTerm = tabTitle ?? ""
            tabGroupData.tabHistoryCurrentState = state.rawValue
            tabGroupsTimerHelper.startOrResume()
            updateRegularSiteObservation(url: searchProviderUrl, title: tabTitle)
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
    
    // MARK: - Private
    
    private func updateObservationForKey(key: HistoryMetadataKey, observation: HistoryMetadataObservation) {
        if let profile = profile {
            _ = profile.places.noteHistoryMetadataObservation(key: key, observation: observation)
        }
    }
    
    
    /// Called update observation for Regular sites
    /// if the title isEmpty we abort recording because it can't be overriden
    /// - Parameters:
    ///   - url: Site URL from webview
    ///   - title: Site title from webview can be empty for slow loading pages
    private func updateRegularSiteObservation(url: String?, title: String?) {
        guard let url = url, let title = title,
              !title.isEmpty else { return }
        
        let key = HistoryMetadataKey(url: url, searchTerm: "", referrerUrl: "")
        let observation = HistoryMetadataObservation(url: url,
                                                     referrerUrl: nil,
                                                     searchTerm: nil,
                                                     viewTime: nil,
                                                     documentType: nil,
                                                     title: title)
        updateObservationForKey(key: key, observation: observation)
    }
}
