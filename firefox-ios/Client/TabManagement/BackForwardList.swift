// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebEngine
import TabDataStore
import WebKit

typealias BackForwardListItem = EngineSessionBackForwardListItem

/// An interface that mimic a `WKBackForwardList` from `WebKit`.
/// It allows to decouple `Tab`'s clients from `WebKit`.
protocol BackForwardList {
    var currentItem: BackForwardListItem? { get }

    var backList: [BackForwardListItem] { get }
    var forwardList: [BackForwardListItem] { get }

    /// Returns the first item in the back and forward list that matches the provided URL.
    func firstItem(with url: URL) -> BackForwardListItem?
}

/// The back and forward list managed by a `Tab`.
///
/// The object is built upon a source `WKBackForwardList`
/// and maps any local temporary document items with their correct online source URL.
class TabBackForwardList: BackForwardList {
    var currentItem: BackForwardListItem?
    var backList: [BackForwardListItem]
    var forwardList: [BackForwardListItem]

    private let sourceBackForwardList: WKBackForwardList
    private let temporaryDocumentSession: TemporaryDocumentSession

    init(backForwardList: WKBackForwardList,
         temporaryDocumentSession: TemporaryDocumentSession) {
        self.sourceBackForwardList = backForwardList
        self.temporaryDocumentSession = temporaryDocumentSession
        if let currentItem = backForwardList.currentItem {
            self.currentItem = Self.mapIfNeeded(item: currentItem, documentSession: temporaryDocumentSession)
        }
        self.backList = backForwardList.backList.map {
            return Self.mapIfNeeded(item: $0, documentSession: temporaryDocumentSession)
        }

        self.forwardList = backForwardList.forwardList.map {
            return Self.mapIfNeeded(item: $0, documentSession: temporaryDocumentSession)
        }
    }

    static func mapIfNeeded(item: WKBackForwardListItem,
                            documentSession: TemporaryDocumentSession) -> BackForwardListItem {
        if item.url.isFileURL, let sourceURL = documentSession[item.url] {
            return TemporaryDocumentBackForwardListItem(url: sourceURL, title: item.title, localItem: item)
        }
        return item
    }

    func firstItem(with url: URL) -> BackForwardListItem? {
        // Look for the item into the source list since that is the source of truth.
        let item = sourceBackForwardList.backList.first { $0.url == url } ??
        sourceBackForwardList.forwardList.first { $0.url == url }

        return item
    }
}
