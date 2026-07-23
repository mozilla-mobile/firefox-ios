// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Security
import Crypto
import X509
import SwiftASN1

/// Helpers for building self-signed certificates and `SecTrust` values in tests.
///
/// `SecTrustCopyCertificateChain` drops any cert that isn't linked to the leaf, so tests that
/// need a multi-cert chain must sign a leaf with an issuer's key (see `makeLeaf(signedBy:)`).
enum CertificateTestFactory {
    struct GeneratedCertificate {
        let certificate: Certificate
        let secCertificate: SecCertificate
        fileprivate let signingContext: SigningContext
    }

    fileprivate struct SigningContext {
        let privateKey: P256.Signing.PrivateKey
        let subjectName: DistinguishedName
    }

    /// Generates a self-signed CA certificate with the given common name.
    static func makeSelfSigned(commonName: String) throws -> GeneratedCertificate {
        try makeCertificate(commonName: commonName, isCA: true, issuer: nil)
    }

    /// Generates a leaf certificate signed by the given issuer. Use this to build a chain that
    /// `SecTrustCopyCertificateChain` will preserve.
    static func makeLeaf(commonName: String,
                         signedBy issuer: GeneratedCertificate) throws -> GeneratedCertificate {
        try makeCertificate(commonName: commonName, isCA: false, issuer: issuer.signingContext)
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

    private static func makeCertificate(commonName: String,
                                        isCA: Bool,
                                        issuer: SigningContext?) throws -> GeneratedCertificate {
        let privateKey = P256.Signing.PrivateKey()
        let subjectName = try DistinguishedName { CommonName(commonName) }
        let signingIssuer = issuer ?? SigningContext(privateKey: privateKey, subjectName: subjectName)

        let now = Date()
        let extensions = try Certificate.Extensions {
            if isCA {
                Critical(BasicConstraints.isCertificateAuthority(maxPathLength: nil))
            }
        }

        let certificate = try Certificate(
            version: .v3,
            serialNumber: Certificate.SerialNumber(),
            publicKey: Certificate.PublicKey(privateKey.publicKey),
            notValidBefore: now.addingTimeInterval(-3600),
            notValidAfter: now.addingTimeInterval(3600 * 24 * 365),
            issuer: signingIssuer.subjectName,
            subject: subjectName,
            signatureAlgorithm: .ecdsaWithSHA256,
            extensions: extensions,
            issuerPrivateKey: Certificate.PrivateKey(signingIssuer.privateKey)
        )

        var serializer = DER.Serializer()
        try serializer.serialize(certificate)
        let derBytes = Data(serializer.serializedBytes)

        guard let secCertificate = SecCertificateCreateWithData(nil, derBytes as CFData) else {
            throw CertificateTestFactoryError.secCertificateCreationFailed
        }
        return GeneratedCertificate(
            certificate: certificate,
            secCertificate: secCertificate,
            signingContext: SigningContext(privateKey: privateKey, subjectName: subjectName)
        )
    }
}

enum CertificateTestFactoryError: Error {
    case secCertificateCreationFailed
    case trustCreationFailed(OSStatus)
}
