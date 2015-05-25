/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage

public class TabsPayload: CleartextPayloadJSON {
    public class Tab {
        let title: String
        let urlHistory: [String]
        let lastUsed: Timestamp
        let icon: String?

        private init(title: String, urlHistory: [String], lastUsed: Timestamp, icon: String?) {
            self.title = title
            self.urlHistory = urlHistory
            self.lastUsed = lastUsed
            self.icon = icon
        }

        func toRemoteTabForClient(guid: GUID) -> RemoteTab? {
            let urls = optFilter(urlHistory.map({ $0.asURL }))
            if urls.isEmpty {
                return nil
            }

            return RemoteTab(clientGUID: guid, URL: urls[0], title: self.title, history: urls, lastUsed: self.lastUsed, icon: self.icon?.asURL)
        }

        class func remoteTabFromJSON(json: JSON, clientGUID: GUID) -> RemoteTab? {
            return fromJSON(json)?.toRemoteTabForClient(clientGUID)
        }

        class func fromJSON(json: JSON) -> Tab? {
            func getLastUsed(json: JSON) -> Timestamp? {
                // This might be a string or a number.
                if let num = json["lastUsed"].asNumber {
                    return Timestamp(num * 1000)
                }

                if let num = json["lastUsed"].asString {
                    // Try parsing.
                    return decimalSecondsStringToTimestamp(num)
                }

                return nil
            }

            if let title = json["title"].asString,
               let urlHistory = jsonsToStrings(json["urlHistory"].asArray),
               let lastUsed = getLastUsed(json) {
                return Tab(title: title, urlHistory: urlHistory, lastUsed: lastUsed, icon: json["icon"].asString)
            }

            return nil
        }
    }

    override public func isValid() -> Bool {
        return super.isValid() &&
               self["clientName"].isString &&
               self["tabs"].isArray
    }

    // Eventually it'd be nice to unify RemoteTab and Tab. We want to kill the GUID in RemoteTab,
    // at which point the only distinction between the two is that RemoteTab is "simple" and
    // lives in Storage, and Tab is more closely tied to TabsPayload.

    var remoteTabs: [RemoteTab] {
        if let clientGUID = self["id"].asString {
            return optFilter(self["tabs"].asArray!.map({ Tab.remoteTabFromJSON($0, clientGUID: clientGUID) }))
        }
        return []
    }

    var tabs: [Tab] {
        return optFilter(self["tabs"].asArray!.map(Tab.fromJSON))
    }

    var clientName: String {
        return self["clientName"].asString!
    }

    override public func equalPayloads(obj: CleartextPayloadJSON) -> Bool {
        if !(obj is TabsPayload) {
            return false;
        }

        if !super.equalPayloads(obj) {
            return false;
        }

        let p = obj as! TabsPayload
        if p.clientName != self.clientName {
            return false
        }

        // TODO: compare tabs.
        /*
        if p.tabs != self.tabs {
            return false;
        }
        */

        return true
    }
}
