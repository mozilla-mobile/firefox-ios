// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import PDFKit

extension PDFDocument {
    func createOutputURL(withFileName name: String) -> URL? {
        guard let documentsDir = try? FileManager.default.url(for: .documentDirectory,
                                                              in: .userDomainMask,
                                                              appropriateFor: nil,
                                                              create: false) else { return nil }
        var filename = (name as NSString).lastPathComponent
            .replacingOccurrences(of: "/", with: "")
        if filename.isEmpty || filename == "." || filename == ".." { filename = "document" }
        let outputURL = documentsDir.appendingPathComponent(filename, isDirectory: false)
            .appendingPathExtension("pdf")

        // Resolved filepath must still reside in Documents directory
        let base = documentsDir.standardizedFileURL.path
        guard outputURL.standardizedFileURL.path.hasPrefix(base + "/") else { return nil }

        return outputURL
    }
}
