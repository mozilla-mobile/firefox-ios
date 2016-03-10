/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

public func makeAdHocBookmarkMergePing(bundle: NSBundle, clientID: String, attempt: Int32, bufferRows: Int?, valid: [String: Bool]) -> JSON {
    let anyFailed = valid.reduce(false, combine: { $0 || $1.1 })

    var out: [String: AnyObject] = [
        "v": 1,
        "appV": AppInfo.appVersion,
        "build": bundle.objectForInfoDictionaryKey("BuildID") as? String ?? "unknown",
        "id": clientID,
        "attempt": Int(attempt),
        "success": !anyFailed,
    ]

    if let bufferRows = bufferRows {
        out["rows"] = bufferRows
    }

    if anyFailed {
        valid.forEach { key, value in
            out[key] = value
        }
    }

    return JSON(out)
}