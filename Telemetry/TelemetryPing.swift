/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

public func makeAdHocBookmarkMergePing(bundle: NSBundle, clientID: String, attempt: Int32, bufferRows: Int?, valid: [String: Bool], clientCount: Int) -> JSON {
    let anyFailed = valid.reduce(false, combine: { $0 || $1.1 })

    var out: [String: AnyObject] = [
        "v": 1,
        "appV": AppInfo.appVersion,
        "build": bundle.objectForInfoDictionaryKey("BuildID") as? String ?? "unknown",
        "id": clientID,
        "attempt": Int(attempt),
        "success": !anyFailed,
        "date": NSDate().descriptionWithLocale(nil),
        "clientCount": clientCount,
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

public func makeAdHocSyncStatusPing(bundle: NSBundle, clientID: String, statusObject: [String: String]?, engineResults: [String: String]?, resultsFailure: MaybeErrorType?, clientCount: Int) -> JSON {
    let out: [String: AnyObject] = [
        "v": 1,
        "appV": AppInfo.appVersion,
        "build": bundle.objectForInfoDictionaryKey("BuildID") as? String ?? "unknown",
        "id": clientID,
        "date": NSDate().descriptionWithLocale(nil),
        "clientCount": clientCount,
        "statusObject": statusObject ?? JSON.null,
        "engineResults": engineResults ?? JSON.null,
        "resultsFailure": resultsFailure?.description ?? JSON.null
    ]

    return JSON(out)
}