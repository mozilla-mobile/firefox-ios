//
//  SimpleTab.swift
//  Client
//
//  Created by Nishant Bhasin on 2020-10-30.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import Shared

struct SimpleTab: Hashable, Codable {
    var title: String?
    var url: URL?
    let lastUsedTime: Timestamp? // From Session Data
    var faviconURL: String?
    var uuid: String = ""
}

static func convertedTabs(_ tabs: [SavedTab]) -> ([SimpleTab], [String: SimpleTab]) {
    var simpleTabs: [String: SimpleTab] = [:]
    for tab in tabs {
        var url:URL?
        // Set URL
        // Check if we have any url
        if tab.url != nil {
            url = tab.url
        // Check if session data urls have something
        } else if tab.sessionData?.urls != nil {
            url = tab.sessionData?.urls.last
        }
        
        // Ignore internal about urls which corresponds to Home
        if url != nil, url!.absoluteString.starts(with: "internal://local/about/") {
            continue
        }
        
        // Set Title
        var title = tab.title ?? ""
        // There is no title then use the base url
        if title.isEmpty {
            title = url?.shortDisplayString ?? ""
        }
        
        // An id for simple tab
        let uuid = UUID().uuidString
        let value = SimpleTab(title: title, url: url, lastUsedTime: tab.sessionData?.lastUsedTime ?? 0, faviconURL: tab.faviconURL, uuid: uuid)
        simpleTabs[uuid] = value
    }

    let arrayFromDic = Array(simpleTabs.values.map{ $0 })
    return (arrayFromDic, simpleTabs)
}
