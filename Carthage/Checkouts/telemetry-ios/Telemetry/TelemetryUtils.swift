/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

#if !DEBUG
    // Turn print into a no-op in non-debug builds.
    func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {}
#endif

// Will print the error, and if it is not a simple network connection problem, report it to the client app.
func report(error: Error) {
    print(error)

    let code = (error as NSError).code
    let errorsNotReported = [NSURLErrorNotConnectedToInternet, NSURLErrorCancelled, NSURLErrorTimedOut, NSURLErrorInternationalRoamingOff, NSURLErrorDataNotAllowed, NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost, NSURLErrorNetworkConnectionLost, NSURLErrorSecureConnectionFailed, NSURLErrorServerCertificateHasBadDate, NSURLErrorServerCertificateUntrusted, NSURLErrorServerCertificateHasUnknownRoot, NSURLErrorServerCertificateNotYetValid, NSURLErrorClientCertificateRejected, NSURLErrorClientCertificateRequired]

    let desc = (error as NSError).debugDescription.lowercased()
    // These errors arrive as generic NSError with no code
    let hasIgnoredDescription = desc.contains("offline")

    if errorsNotReported.contains(code) || hasIgnoredDescription {
        return
    }
    NotificationCenter.default.post(name: Telemetry.notificationReportError, object: nil, userInfo: ["error": error])
}

extension UInt64 {
    static func safeConvert<T: FloatingPoint>(_ val: T) -> UInt64 {
        let d = val as? Double ?? 0.0
        return UInt64(Swift.max(0.0, d))
    }

    static func safeConvert<T: BinaryInteger>(_ val: T) -> UInt64 {
        return UInt64(Swift.max(0, val))
    }
}


class TelemetryUtils {
    static let isUnitTesting = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil || (ProcessInfo.processInfo.environment["DYLD_INSERT_LIBRARIES"] ?? "").contains("libXCTTargetBootstrapInject.dylib")

    static func asString(_ object: Any?) -> String {
        guard let object = object else { return "" }
        if let string = object as? String {
            return string
        } else if let bool = object as? Bool {
            return bool ? "true" : "false"
        } else {
            return "\(object)"
        }
    }
    
    static func truncate(string: String, maxLength: Int) -> String {
        guard string.count < maxLength else {
            print("Warning: String '\(string)' needed truncated for exceeding maximum length of \(maxLength)")
            return String(string.prefix(maxLength))
        }

        return string
    }

    static func daysOld(date: Date) -> Int {
        let end = TelemetryUtils.dateFromTimestamp(TelemetryUtils.timestamp())
        return Calendar.current.dateComponents([.day], from: date, to: end).day ?? 0
    }
}

// Allows for adjusting the time when testing
extension TelemetryUtils {
    static var mockableOffset: TimeInterval? {
        didSet {
            if !isUnitTesting {
                // Testing only!!
                mockableOffset = nil
            }
        }
    }

    static func timestamp() -> TimeInterval {
        return Date().timeIntervalSince1970 + (mockableOffset ?? 0)
    }

    static func dateFromTimestamp(_ timestampSince1970: TimeInterval) -> Date {
        return Date(timeIntervalSince1970: timestampSince1970 + (mockableOffset ?? 0))
    }
}

