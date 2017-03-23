/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Alamofire
import Foundation
import GCDWebServers
import XCGLogger
import SwiftyJSON

private let log = Logger.browserLogger
private let ServerURL = "https://incoming.telemetry.mozilla.org".asURL!
private let AppName = "Fennec"

public protocol TelemetryEvent {
    func record(_ prefs: Prefs)
}

open class Telemetry {
    private static var prefs: Prefs?

    open class func initWithPrefs(_ prefs: Prefs) {
        assert(self.prefs == nil, "Prefs already initialized")
        self.prefs = prefs
    }

    open class func recordEvent(_ event: TelemetryEvent) {
        guard let prefs = prefs else {
            assertionFailure("Prefs not initialized")
            return
        }

        event.record(prefs)
    }

    open class func sendPing(_ ping: TelemetryPing) {
        let payload = ping.payload.stringValue()

        let docID = UUID().uuidString
        let docType = "core"
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        let buildID = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String

        let channel: String
        switch AppConstants.BuildChannel {
        case .nightly: channel = "nightly"
        case .beta: channel = "beta"
        case .release: channel = "release"
        default: channel = "default"
        }

        let path = "/submit/telemetry/\(docID)/\(docType)/\(AppName)/\(appVersion)/\(channel)/\(buildID)"
        let url = ServerURL.appendingPathComponent(path)
        var request = URLRequest(url: url)

        log.debug("Ping URL: \(url)")
        log.debug("Ping payload: \(payload)")

        guard let body = payload?.data(using: String.Encoding.utf8) else {
            log.error("Invalid data!")
            assertionFailure()
            return
        }

        guard channel != "default" else {
            log.debug("Non-release build; not sending ping")
            return
        }

        request.httpMethod = "POST"
        request.httpBody = body
        request.addValue(GCDWebServerFormatRFC822(Date()), forHTTPHeaderField: "Date")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        SessionManager.default.request(request).response { response in
            log.debug("Ping response: \(response.response?.statusCode ?? -1).")
        }
    }
}

public protocol TelemetryPing {
    var payload: JSON { get }
}
