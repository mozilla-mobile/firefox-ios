/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

public func makeAdHocBookmarkMergePing(_ bundle: Bundle, clientID: String, attempt: Int32, bufferRows: Int?, valid: [String: Bool], clientCount: Int) -> JSON {
    let anyFailed = valid.reduce(false, { $0 || $1.1 })

    var out: [String: AnyObject] = [
        "v": 1 as AnyObject,
        "appV": AppInfo.appVersion as AnyObject,
        "build": bundle.object(forInfoDictionaryKey: "BuildID") as? String as AnyObject? ?? "unknown" as AnyObject,
        "id": clientID as AnyObject,
        "attempt": Int(attempt) as AnyObject,
        "success": !anyFailed as AnyObject,
        "date": Date().description(with: nil),
        "clientCount": clientCount,
    ]

    if let bufferRows = bufferRows {
        out["rows"] = bufferRows as AnyObject?
    }

    if anyFailed {
        valid.forEach { key, value in
            out[key] = value as AnyObject?
        }
    }

    return JSON(out)
}

public func makeAdHocSyncStatusPing(_ bundle: Bundle, clientID: String, statusObject: [String: String]?, engineResults: [String: String]?, resultsFailure: MaybeErrorType?, clientCount: Int) -> JSON {
    let out: [String: AnyObject] = [
        "v": 1,
        "appV": AppInfo.appVersion,
        "build": bundle.object(forInfoDictionaryKey: "BuildID") as? String ?? "unknown",
        "id": clientID,
        "date": Date().description(with: nil),
        "clientCount": clientCount,
        "statusObject": statusObject ?? JSON.null,
        "engineResults": engineResults ?? JSON.null,
        "resultsFailure": resultsFailure?.description ?? JSON.null
    ]

    return JSON(out)
}
