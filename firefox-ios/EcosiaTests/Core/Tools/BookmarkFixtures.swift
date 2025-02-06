// swiftlint:disable force_try
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Ecosia

enum BookmarkFixtures {
    enum Browser: String {
        case chrome, firefox, safari
    }

    case html(Browser), debugString(Browser)

    var value: String {
        switch self {
        case let .html(browser):
            return String(
                data: try! Data(contentsOf: Bundle.ecosiaTests.url(forResource: "import_input_bookmark_\(browser.rawValue)", withExtension: "html")!),
                encoding: .utf8
            )!.trimmingCharacters(in: .newlines)
        case let .debugString(browser):
            return String(
                data: try! Data(contentsOf: Bundle.ecosiaTests.url(forResource: "import_output_bookmark_\(browser.rawValue)", withExtension: "txt")!),
                encoding: .utf8
            )!.trimmingCharacters(in: .newlines)
        }
    }

    static var ecosiaExportedHtml: String {
        String(
            data: try! Data(contentsOf: Bundle.ecosiaTests.url(forResource: "export_bookmark_ecosia", withExtension: "html")!),
            encoding: .utf8
        )!.trimmingCharacters(in: .newlines)
    }
}
// swiftlint:enable force_try
