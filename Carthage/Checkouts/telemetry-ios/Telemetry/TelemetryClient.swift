/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class TelemetryClient: NSObject {
    private let configuration: TelemetryConfiguration

    init(configuration: TelemetryConfiguration) {
        self.configuration = configuration
    }

    // The closure is called with an HTTP status code (zero if unavailable) and an error
    func upload(ping: TelemetryPing, completionHandler: @escaping (Int, Error?) -> Void) -> Void {
        guard let url = URL(string: "\(configuration.serverEndpoint)\(ping.uploadPath)") else {
            let error = NSError(domain: TelemetryError.ErrorDomain, code: TelemetryError.InvalidUploadURL, userInfo: [NSLocalizedDescriptionKey: "Invalid upload URL: \(configuration.serverEndpoint)\(ping.uploadPath)"])
            completionHandler(0, error)
            report(error: error)
            return
        }
        
        guard let data = ping.measurementsJSON() else {
            let error = NSError(domain: TelemetryError.ErrorDomain, code: TelemetryError.CannotGenerateJSON, userInfo: [NSLocalizedDescriptionKey: "Error generating JSON data for TelemetryPing"])
            completionHandler(0, error)
            report(error: error)
            return
        }

        var request = URLRequest(url: url)
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue(configuration.userAgent, forHTTPHeaderField: "User-Agent")
        request.httpMethod = "POST"
        request.httpBody = data
        request.httpShouldHandleCookies = false

        print("\(request.httpMethod ?? "(GET)") \(request.debugDescription)")

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            DispatchQueue.main.async {
                let httpResponse = response as? HTTPURLResponse
                let statusCode = httpResponse?.statusCode ?? 0
                if statusCode == 200 {
                    completionHandler(statusCode, nil)
                    return
                }

                let err = error ?? NSError(domain: TelemetryError.ErrorDomain, code: TelemetryError.UnknownUploadError, userInfo: nil)
                completionHandler(statusCode, err)
                report(error: err)
            }
        }
        task.resume()
    }
}

