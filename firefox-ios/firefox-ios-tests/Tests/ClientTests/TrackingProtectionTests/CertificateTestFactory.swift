// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Security
import Crypto
import X509
import SwiftASN1

/// Helpers for building self-signed certificates and `SecTrust` values in tests.
enum CertificateTestFactory {
    struct GeneratedCertificate {
        let certificate: Certificate
        let secCertificate: SecCertificate
    }

    /// Generates a minimal self-signed certificate with the given common name and returns both
    /// the parsed `Certificate` and the platform `SecCertificate`.
    static func makeSelfSigned(commonName: String) throws -> GeneratedCertificate {
        let privateKey = P256.Signing.PrivateKey()
        let subjectName = try DistinguishedName { CommonName(commonName) }

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
            throw CertificateTestFactoryError.secCertificateCreationFailed
        }
        return GeneratedCertificate(certificate: certificate, secCertificate: secCertificate)
    }

    /// Wraps the given `SecCertificate`s in a `SecTrust` using the basic X.509 policy.
    /// The first certificate is treated as the leaf; subsequent ones as the chain.
    static func makeTrust(from certificates: [SecCertificate]) throws -> SecTrust {
        let policy = SecPolicyCreateBasicX509()
        var trust: SecTrust?
        let status = SecTrustCreateWithCertificates(certificates as CFArray, policy, &trust)
        guard status == errSecSuccess, let trust else {
            throw CertificateTestFactoryError.trustCreationFailed(status)
        }
        return trust
    }
}

enum CertificateTestFactoryError: Error {
    case secCertificateCreationFailed
    case trustCreationFailed(OSStatus)
}
