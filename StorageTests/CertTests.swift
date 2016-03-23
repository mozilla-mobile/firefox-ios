/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
import Storage

class CertTests: XCTestCase {
    func testCertStore() {
        let certStore = CertStore()
        let cert1 = getCertificate("testcert1")
        let cert2 = getCertificate("testcert2")

        // Check that contains return false for certs not in store.
        XCTAssertFalse(certStore.containsCertificate(cert1))

        // Add cert 1.
        certStore.addCertificate(cert1)

        // Check that the cert is in the store.
        XCTAssert(certStore.containsCertificate(cert1))

        // Check that contains uniquely identifies certs.
        XCTAssertFalse(certStore.containsCertificate(cert2))

        // Check that adding an existing cert has no effect.
        certStore.addCertificate(cert1)
        XCTAssert(certStore.containsCertificate(cert1))
    }

    private func getCertificate(file: String) -> SecCertificateRef {
        let path = NSBundle(forClass: self.dynamicType).pathForResource(file, ofType: "pem")
        let data = NSData(contentsOfFile: path!)
        return SecCertificateCreateWithData(nil, data!)!
    }
}
