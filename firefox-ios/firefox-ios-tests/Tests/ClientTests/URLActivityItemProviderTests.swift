// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UniformTypeIdentifiers
import XCTest
@testable import Client

// TODO: FXIOS-10816 Flesh out these unit tests
final class URLActivityItemProviderTests: XCTestCase {
    let testWebURL = URL(string: "https://mozilla.org")!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
    }

    // MARK: - Sent from Firefox experiment WhatsApp tab share override

    func testOveridesWhatsAppShareItem() throws {
        // TODO: FXIOS-10858 Real links to come
        let expectedShareContent = "https://mozilla.org Sent from Firefox 🦊 Try the mobile browser: <FXIOS-10858 marketing link here>"
        let whatsAppActivityIdentifier = "net.whatsapp.WhatsApp.ShareExtension"

        let urlActivityItemProvider = URLActivityItemProvider(url: testWebURL, allowSentFromFirefoxTreatment: true)
        let itemForActivity = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: UIActivity.ActivityType(rawValue: whatsAppActivityIdentifier)
        )

        XCTAssertEqual(itemForActivity as? String, expectedShareContent)
    }

    // MARK: - Helpers

    private func createStubActivityViewController() -> UIActivityViewController {
        return UIActivityViewController(activityItems: [], applicationActivities: [])
    }
}
