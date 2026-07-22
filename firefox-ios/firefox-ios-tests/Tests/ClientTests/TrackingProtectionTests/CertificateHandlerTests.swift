// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Crypto
import X509
import SwiftASN1
@testable import Client

final class CertificatesHandlerTests: XCTestCase {
    func testHandleCertificates_withRealCertificate_returnsParsedCertificate() throws {
        let secCertificate = try Self.makeSelfSignedSecCertificate()
        let policy = SecPolicyCreateBasicX509()
        var trust: SecTrust?
        SecTrustCreateWithCertificates(secCertificate, policy, &trust)

        guard let trust else {
            XCTFail("Expected a SecTrust to be created")
            return
        }

        let subject = CertificatesHandler(serverTrust: trust)
        let result = subject.handleCertificates()

        XCTAssertEqual(result.count, 1)
    }

    static func makeSelfSignedSecCertificate() throws -> SecCertificate {
        let privateKey = P256.Signing.PrivateKey()
        let subjectName = try DistinguishedName { CommonName("Test Certificate") }

        let now = Date()
        let extensions = try Certificate.Extensions {
            Critical(BasicConstraints.isCertificateAuthority(maxPathLength: nil))
        }

        let certificate = try Certificate(
            version: .v3,
            serialNumber: Certificate.SerialNumber(),
            publicKey: Certificate.PublicKey(privateKey.publicKey),
            notValidBefore: now.addingTimeInterval(-3600),
            notValidAfter: now.addingTimeInterval(3600 * 24 * 365),
            issuer: subjectName,
            subject: subjectName,
            signatureAlgorithm: .ecdsaWithSHA256,
            extensions: extensions,
            issuerPrivateKey: Certificate.PrivateKey(privateKey)
        )

        var serializer = DER.Serializer()
        try serializer.serialize(certificate)
        let derBytes = Data(serializer.serializedBytes)

        guard let secCertificate = SecCertificateCreateWithData(nil, derBytes as CFData) else {
            throw NSError(domain: "CertificatesHandlerTests",
                          code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to create SecCertificate"])
        }
        return secCertificate
    }
}
