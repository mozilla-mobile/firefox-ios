/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger
import SwiftyJSON

// Int64.max / 1000.
private let MaxSecondsToConvertInt64: Int64 = 9223372036854775
private let MaxSecondsToConvertDouble: Double = Double(9223372036854775 as Int64)

private let log = Logger.browserLogger

open class TabsPayload: CleartextPayloadJSON {
    open class Tab {
        let title: String
        let urlHistory: [String]
        let lastUsed: Timestamp
        let icon: String?

        fileprivate init(title: String, urlHistory: [String], lastUsed: Timestamp, icon: String?) {
            self.title = title
            self.urlHistory = urlHistory
            self.lastUsed = lastUsed
            self.icon = icon
        }

        func toRemoteTabForClient(_ guid: GUID) -> RemoteTab? {
            let urls = urlHistory.flatMap({ $0.asURL })
            if urls.isEmpty {
                log.debug("Bug 1201875 - Discarding tab as history has no conforming URLs.")
                return nil
            }

            return RemoteTab(clientGUID: guid, URL: urls[0], title: self.title, history: urls, lastUsed: self.lastUsed, icon: self.icon?.asURL)
        }

        class func remoteTabFromJSON(_ json: JSON, clientGUID: GUID) -> RemoteTab? {
            return fromJSON(json)?.toRemoteTabForClient(clientGUID)
        }

        class func fromJSON(_ json: JSON) -> Tab? {
            func getLastUsed(_ json: JSON) -> Timestamp? {
                let lastUsed = json["lastUsed"]
                if lastUsed.isBool() {
                    return nil
                }
                // This might be a string or a number.
                if let num = lastUsed.int64 {
                    if num < 0 {
                        // Timestamps are unsigned.
                        return nil
                    }
                    if num > MaxSecondsToConvertInt64 {
                        // This will overflow when multiplied.
                        return nil
                    }
                    return Timestamp(num * 1000)
                }

                if let num = lastUsed.double {
                    if num < 0 {
                        // Timestamps are unsigned.
                        return nil
                    }
                    if num > MaxSecondsToConvertDouble {
                        // This will overflow when multiplied.
                        return nil
                    }
                    return Timestamp(num * 1000)
                }

                if let num = lastUsed.string {
                    // Try parsing.
                    return someKindOfTimestampStringToTimestamp(num)
                }

                return nil
            }

            if let title = json["title"].string,
               let urlHistory = jsonsToStrings(json["urlHistory"].array),
               let lastUsed = getLastUsed(json) {
                return Tab(title: title, urlHistory: urlHistory, lastUsed: lastUsed, icon: json["icon"].string)
            }

            return nil
        }
    }

    override open func isValid() -> Bool {
        if !super.isValid() {
            return false
        }

        if self["deleted"].bool ?? false {
            return true
        }

        return self["clientName"].isString() &&
               self["tabs"].isArray()
    }

    // Eventually it'd be nice to unify RemoteTab and Tab. We want to kill the GUID in RemoteTab,
    // at which point the only distinction between the two is that RemoteTab is "simple" and
    // lives in Storage, and Tab is more closely tied to TabsPayload.

    var remoteTabs: [RemoteTab] {
        if let clientGUID = self["id"].string {
            let payloadTabs = self["tabs"].arrayValue
            let remoteTabs = payloadTabs.flatMap({ Tab.remoteTabFromJSON($0, clientGUID: clientGUID) })
            if payloadTabs.count != remoteTabs.count {
                log.debug("Bug 1201875 - Missing remote tabs from sync")
            }
            return remoteTabs
        }
        log.debug("no client ID for remote tabs")
        return []
    }

    var tabs: [Tab] {
        return self["tabs"].arrayValue.flatMap(Tab.fromJSON)
    }

    var clientName: String {
        return self["clientName"].string!
    }

    override open func equalPayloads(_ obj: CleartextPayloadJSON) -> Bool {
        if !(obj is TabsPayload) {
            return false
        }

        if !super.equalPayloads(obj) {
            return false
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
