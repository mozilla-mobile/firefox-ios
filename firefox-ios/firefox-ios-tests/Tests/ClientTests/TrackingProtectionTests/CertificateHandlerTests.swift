// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import TestKit
import Foundation
import XCTest
import X509
import Common
@testable import Client

final class CertificatesHandlerTests: XCTestCase {
    func testHandleCertificates_withSingleCertificate_returnsThatCertificate() throws {
        let generated = try CertificateTestFactory.makeSelfSigned(commonName: "leaf.test")
        let trust = try CertificateTestFactory.makeTrust(from: [generated.secCertificate])

        let subject = CertificatesHandler(serverTrust: trust)
        let result = subject.handleCertificates()

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.subject, generated.certificate.subject)
    }

    func testHandleCertificates_withMultiCertChain_returnsAllCertificatesInOrder() throws {
        let leaf = try CertificateTestFactory.makeSelfSigned(commonName: "leaf.test")
        let intermediate = try CertificateTestFactory.makeSelfSigned(commonName: "intermediate.test")
        let trust = try CertificateTestFactory.makeTrust(from: [leaf.secCertificate,
                                                                intermediate.secCertificate])

        let subject = CertificatesHandler(serverTrust: trust)
        let result = subject.handleCertificates()

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].subject, leaf.certificate.subject)
        XCTAssertEqual(result[1].subject, intermediate.certificate.subject)
    }

    func testHandleCertificates_whenDecoderThrowsForAll_returnsEmptyAndLogsWarning() throws {
        let generated = try CertificateTestFactory.makeSelfSigned(commonName: "leaf.test")
        let trust = try CertificateTestFactory.makeTrust(from: [generated.secCertificate])
        let logger = MockLogger()

        let subject = CertificatesHandler(serverTrust: trust,
                                          decoder: AlwaysThrowingDecoder(),
                                          logger: logger)
        let result = subject.handleCertificates()

        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(logger.savedLevel, .warning)
        XCTAssertEqual(logger.savedCategory, .certificate)
    }

    func testHandleCertificates_whenDecoderThrowsForOnlyOneCert_returnsTheOtherCert() throws {
        let leaf = try CertificateTestFactory.makeSelfSigned(commonName: "leaf.test")
        let intermediate = try CertificateTestFactory.makeSelfSigned(commonName: "intermediate.test")
        let trust = try CertificateTestFactory.makeTrust(from: [leaf.secCertificate,
                                                                intermediate.secCertificate])
        let decoder = SelectivelyThrowingDecoder(throwOnCallIndex: 0)

        let subject = CertificatesHandler(serverTrust: trust, decoder: decoder)
        let result = subject.handleCertificates()

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.subject, intermediate.certificate.subject)
    }
}

private struct DecoderTestError: Error {}

private struct AlwaysThrowingDecoder: CertificateDecoding {
    func decodeCertificate(from derBytes: Data) throws -> Certificate {
        throw DecoderTestError()
    }
}

/// Delegates to the default decoder except for the call at `throwOnCallIndex`, which throws.
/// Lets tests verify that a single decode failure doesn't drop the rest of the chain.
private final class SelectivelyThrowingDecoder: CertificateDecoding {
    private let throwOnCallIndex: Int
    private let fallback: CertificateDecoding
    private var callCount = 0

    init(throwOnCallIndex: Int, fallback: CertificateDecoding = DefaultCertificateDecoder()) {
        self.throwOnCallIndex = throwOnCallIndex
        self.fallback = fallback
    }

    func decodeCertificate(from derBytes: Data) throws -> Certificate {
        defer { callCount += 1 }
        if callCount == throwOnCallIndex {
            throw DecoderTestError()
        }
        return try fallback.decodeCertificate(from: derBytes)
    }
}
