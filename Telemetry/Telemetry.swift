/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Alamofire
import Foundation
import XCGLogger

private let log = Logger.browserLogger
private let ServerURL = "https://incoming.telemetry.mozilla.org".asURL!
private let AppName = "Fennec"

public class Telemetry {
    public class func sendPing(ping: TelemetryPing) {
        let payload = ping.payload.toString()

        let docID = NSUUID().UUIDString
        let docType = "core"
        let appVersion = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as! String
        let buildID = NSBundle.mainBundle().objectForInfoDictionaryKey(kCFBundleVersionKey as String) as! String

        let channel: String
        switch AppConstants.BuildChannel {
        case .Nightly: channel = "nightly"
        case .Beta: channel = "beta"
        case .Release: channel = "release"
        default: channel = "default"
        }

        let path = "/submit/telemetry/\(docID)/\(docType)/\(AppName)/\(appVersion)/\(channel)/\(buildID)"
        let url = ServerURL.URLByAppendingPathComponent(path)
        let request = NSMutableURLRequest(URL: url)

        log.debug("Ping URL: \(url)")
        log.debug("Ping payload: \(payload)")

        guard let body = payload.dataUsingEncoding(NSUTF8StringEncoding) else {
            log.error("Invalid data!")
            assertionFailure()
            return
        }

        guard channel != "default" else {
            log.debug("Non-release build; not sending ping")
            return
        }

        request.HTTPMethod = "POST"
        request.HTTPBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        Alamofire.Manager.sharedInstance.request(request).response { (request, response, data, error) in
            log.debug("Ping response: \(response?.statusCode ?? -1).")
        }
    }
}

public protocol TelemetryPing {
    var payload: JSON { get }
}