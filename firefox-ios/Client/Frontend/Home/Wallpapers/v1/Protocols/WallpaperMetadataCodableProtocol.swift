// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol WallpaperMetadataCodableProtocol {
    func decodeMetadata(from data: Data) throws -> WallpaperMetadata
    func encodeToData(from metadata: WallpaperMetadata) throws -> Data
}

extension WallpaperMetadataCodableProtocol {
    /// Given some data, if that data is a valid JSON file, it attempts to decode it
    /// into a `WallpaperMetadata` object
    func decodeMetadata(from data: Data) throws -> WallpaperMetadata {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter())

        return try decoder.decode(WallpaperMetadata.self, from: data)
    }

    /// Given a `WallpaperMetadata` object, it attempts to encode it into data.
    func encodeToData(from metadata: WallpaperMetadata) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(dateFormatter())

        return try encoder.encode(metadata)
    }

    /// Returns a `DateFormatter` to be used for encoding/decoding `WallpaperMetadata`
    private func dateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        return dateFormatter
    }
}
