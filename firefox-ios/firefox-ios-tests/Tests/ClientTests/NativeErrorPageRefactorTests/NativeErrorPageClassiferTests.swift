// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

final class NativeErrorPageClassifierTests: XCTestCase {
    func testType_notConnectedToInternet_returnsNoInternet() {
        let subject = createSubject()
        XCTAssertEqual(subject.type(for: makeError(NSURLErrorNotConnectedToInternet)), .noInternet)
    }

    func testType_cannotConnectToHost_withVPNEnabled_returnsVPN() {
        let subject = createSubject(isWaybackEnabled: true, isVPNEnabled: true)
        XCTAssertEqual(subject.type(for: makeError(NSURLErrorCannotConnectToHost)), .vpn)
    }

    func testType_cannotConnectToHost_withVPNDisabled_returnsWayback() {
        let subject = createSubject(isWaybackEnabled: true)
        XCTAssertEqual(subject.type(for: makeError(NSURLErrorCannotConnectToHost)), .wayback)
    }

    func testType_noResponseCodes_returnNoResponse() {
        let subject = createSubject()
        let codes = [NSURLErrorZeroByteResource, NSURLErrorBadServerResponse, NSURLErrorNetworkConnectionLost]
        for code in codes {
            XCTAssertEqual(subject.type(for: makeError(code)), .noResponse)
        }
    }

    func testType_certCodes_returnBadCert() {
        let subject = createSubject()
        let codes = [
            NSURLErrorServerCertificateUntrusted,
            NSURLErrorServerCertificateHasBadDate,
            NSURLErrorServerCertificateHasUnknownRoot,
            NSURLErrorServerCertificateNotYetValid
        ]
        for code in codes {
            XCTAssertEqual(subject.type(for: makeError(code)), .badCert)
        }
    }

    func testType_timedOut_withWaybackEnabled_returnsWayback() {
        let subject = createSubject(isWaybackEnabled: true)
        XCTAssertEqual(subject.type(for: makeError(NSURLErrorTimedOut)), .wayback)
    }

    func testType_timedOut_withWaybackDisabled_returnsGeneric() {
        let subject = createSubject()
        XCTAssertEqual(subject.type(for: makeError(NSURLErrorTimedOut)), .generic)
    }

    func testType_unknownCode_returnsGeneric() {
        let subject = createSubject(isWaybackEnabled: true, isVPNEnabled: true)
        XCTAssertEqual(subject.type(for: makeError(NSURLErrorUnknown)), .generic)
    }

    private func createSubject(isWaybackEnabled: Bool = false, isVPNEnabled: Bool = false) -> NativeErrorPageClassifier {
        return NativeErrorPageClassifier(isWaybackEnabled: isWaybackEnabled, isVPNEnabled: isVPNEnabled)
    }

    private func makeError(_ code: Int) -> NSError {
        return NSError(domain: NSURLErrorDomain, code: code)
    }
}
