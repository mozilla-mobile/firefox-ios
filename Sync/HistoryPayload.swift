/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage

public class HistoryPayload: CleartextPayloadJSON {
    public class func fromJSON(json: JSON) -> HistoryPayload? {
        let p = HistoryPayload(json)
        if p.isValid() {
            return p
        }
        return nil
    }

    override public func isValid() -> Bool {
        return super.isValid() &&
               self["histUri"].isString &&      // TODO: validate URI.
               self["title"].isString &&
               self["visits"].isArray
    }

    public func asPlaceWithModifiedTime(modified: Timestamp) -> RemotePlace {
        return RemotePlace(guid: self.id, url: self.historyURI.absoluteString!, title: self.title, modified: modified)
    }

    var visits: [Visit] {
        return optFilter(self["visits"].asArray!.map(Visit.fromJSON))
    }

    var historyURI: NSURL {
        return self["histUri"].asString!.asURL!
    }

    var title: String {
        return self["title"].asString!
    }

    override public func equalPayloads(obj: CleartextPayloadJSON) -> Bool {
        if !(obj is HistoryPayload) {
            return false;
        }

        if !super.equalPayloads(obj) {
            return false;
        }

        let p = obj as! HistoryPayload
        if p.title != self.title {
            return false
        }

        if p.historyURI != self.historyURI {
            return false
        }

        // TODO: compare visits.

        return true
    }
}
