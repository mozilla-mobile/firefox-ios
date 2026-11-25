// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

struct NativeErrorPageClassifier {
    private let noInternetErrorCodes = [
        NSURLErrorNotConnectedToInternet
    ]

    private let vpnErrorCodes = [
        NSURLErrorCannotConnectToHost
    ]

    private let noResponseErrorCodes = [
        NSURLErrorZeroByteResource,
        NSURLErrorBadServerResponse,
        NSURLErrorNetworkConnectionLost
    ]

    private let certErrorCodes = [
        NSURLErrorServerCertificateUntrusted,
        NSURLErrorServerCertificateHasBadDate,
        NSURLErrorServerCertificateHasUnknownRoot,
        NSURLErrorServerCertificateNotYetValid
    ]

    let isWaybackEnabled: Bool
    let isVPNEnabled: Bool

    func type(for error: NSError) -> NativeErrorPageType {
        let code = error.code
        if noInternetErrorCodes.contains(code) {
            return .noInternet
        } else if isVPNEnabled && vpnErrorCodes.contains(code) {
            return .vpn
        } else if noResponseErrorCodes.contains(code) {
            return .noResponse
        } else if certErrorCodes.contains(code) {
            return .badCert
        } else if isWaybackEnabled && WaybackCodes.isWaybackCode(code) {
            return .wayback
        }
        return .generic
    }
}
